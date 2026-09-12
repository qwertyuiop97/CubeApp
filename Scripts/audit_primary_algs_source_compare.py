#!/usr/bin/env python3
"""Conservative primary-algorithm source compare for CubeApp.

Reads local Swift primaries and already-downloaded evidence under
--cache-dir (default /tmp/cubeapp-audit/). Does not fetch the network.
Does not modify AlgorithmDatabase.swift / F2LDatabase.swift.

Match ranks (strict → loose), never claiming state-equivalence:
  exact              whitespace-collapsed string equality
  cosmetic           drop round brackets only; fully-consumed move tokens equal
  half_turn_prime    cosmetic + X2' == X2 (prime preserved until this step)
  rotation_or_auf    notation candidate after leading x/y/z rotations and
                     terminal U-face AUF (including explicit [U]/[U']/ [U2]
                     square AUF brackets). Not a canonical identity proof.
  unresolved         no match at that source (not 'invalid')
  skipped_two_column CubeSkills PDF: no per-case attribution
  source_unavailable cached file is not usable algorithm data

F2L same-id misses are also searched under other F2L ids
('exists_other_id') instead of being marked incorrect.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEFAULT_CACHE = Path("/tmp/cubeapp-audit")
DEFAULT_OUTPUT = DEFAULT_CACHE / "primary-compare-results.json"
DEFAULT_DOCS_JSON = REPO / "docs/primary-compare-results.json"
DEFAULT_REPORT = REPO / "docs/ALGORITHM-VERIFICATION.md"

REQUIRED_SOURCES = [
    {
        "file": "jperm-oll.js",
        "url": "https://jperm.net/lib/oll.js",
        "cite": 1,
        "kind": "jperm_oll",
        "expected_cases": 57,
    },
    {
        "file": "jperm-pll.js",
        "url": "https://jperm.net/lib/pll.js",
        "cite": 2,
        "kind": "jperm_pll",
        "expected_cases": 21,
    },
    {
        "file": "scdb-oll.md",
        "url": "https://speedcubedb.com/a/3x3/OLL",
        "cite": 3,
        "kind": "scdb_oll",
        "expected_cases": 57,
    },
    {
        "file": "scdb-pll.md",
        "url": "https://speedcubedb.com/a/3x3/PLL",
        "cite": 4,
        "kind": "scdb_pll",
        "expected_cases": 21,
    },
    {
        "file": "scdb-f2l.md",
        "url": "https://speedcubedb.com/a/3x3/F2L",
        "cite": 5,
        "kind": "scdb_f2l",
        "expected_cases": 41,
    },
    {
        "file": "cubeskills-pll.txt",
        "url": "https://www.cubeskills.com/uploads/pdf/tutorials/pll-algorithms.pdf",
        "cite": 6,
        "kind": "cubeskills_pll_corpus",
        "expected_cases": None,
    },
    {
        "file": "cubeskills-oll.txt",
        "url": "https://www.cubeskills.com/uploads/pdf/tutorials/oll-algorithms.pdf",
        "cite": 7,
        "kind": "cubeskills_oll_corpus",
        "expected_cases": None,
    },
]

EXPECTED_LOCAL = {"OLL": 57, "PLL": 21, "F2L": 41}

MOVE_RE = re.compile(
    r"(?:[xyzXYZ]|[RULDFB]w|[RULDFBMES]|[ruldfbmes])(?:2'|2|')?"
)
ROT_RE = re.compile(r"^[xyzXYZ](?:2'|2|')?$")
AUF_RE = re.compile(r"^U(?:2'|2|')?$")
SQUARE_AUF_RE = re.compile(r"\[(U(?:2'|2|')?)\]")
METADATA_CUT_RE = re.compile(r"(?:\[?!\[|\bCommunity\b)")


def collapse_ws(s: str) -> str:
    return " ".join(s.split())


def strip_round_brackets(s: str) -> str:
    return s.replace("(", " ").replace(")", " ")


def tokenize(s: str) -> list[str] | None:
    """Fully consume allowed notation. Unknown letters/punct → None."""
    s = strip_round_brackets(s)
    if not s.strip():
        return None
    tokens: list[str] = []
    i = 0
    n = len(s)
    while i < n:
        if s[i].isspace():
            i += 1
            continue
        m = MOVE_RE.match(s, i)
        if not m:
            return None
        tokens.append(m.group(0))
        i = m.end()
    return tokens or None


def replace_square_auf(s: str) -> str | None:
    """Expand U-face square AUF brackets. Any other [ ] rejects the candidate."""
    if "[" not in s and "]" not in s:
        return s
    out = SQUARE_AUF_RE.sub(r" \1 ", s)
    if "[" in out or "]" in out:
        return None
    return out


def half_turn_norm(tokens: list[str] | tuple[str, ...]) -> tuple[str, ...]:
    out = []
    for t in tokens:
        if t.endswith("2'"):
            out.append(t[:-1])
        else:
            out.append(t)
    return tuple(out)


def strip_rot_auf(tokens: tuple[str, ...]) -> tuple[str, ...]:
    """Leading rotations and terminal U-face AUF only (not leading U)."""
    t = list(tokens)
    while t and ROT_RE.match(t[0]):
        t.pop(0)
    while t and AUF_RE.match(t[-1]):
        t.pop()
    return tuple(t)


def split_alts(raw: str) -> list[str]:
    parts = []
    for chunk in raw.split(";"):
        chunk = chunk.strip().strip(",")
        if chunk:
            parts.append(chunk)
    return parts or ([raw] if raw.strip() else [])


def classify_pair(local: str, source: str) -> str | None:
    if collapse_ws(local) == collapse_ws(source):
        return "exact"
    loc_tok = tokenize(local)
    src_tok = tokenize(source)
    if loc_tok is not None and src_tok is not None:
        if loc_tok == src_tok:
            return "cosmetic"
        loc_h = half_turn_norm(loc_tok)
        src_h = half_turn_norm(src_tok)
        if loc_h == src_h:
            return "half_turn_prime"
    loc_s = replace_square_auf(local)
    src_s = replace_square_auf(source)
    if loc_s is None or src_s is None:
        return None
    loc_tok2 = tokenize(loc_s)
    src_tok2 = tokenize(src_s)
    if loc_tok2 is None or src_tok2 is None:
        return None
    loc_h = half_turn_norm(loc_tok2)
    src_h = half_turn_norm(src_tok2)
    used_square = any(ch in local or ch in source for ch in "[]")
    if loc_h == src_h:
        return "rotation_or_auf" if used_square else "half_turn_prime"
    loc_r = strip_rot_auf(loc_h)
    src_r = strip_rot_auf(src_h)
    if loc_r and src_r and loc_r == src_r:
        return "rotation_or_auf"
    return None


RANK = {
    "exact": 0,
    "cosmetic": 1,
    "half_turn_prime": 2,
    "rotation_or_auf": 3,
    "exists_other_id": 4,
    "unresolved": 5,
    "skipped_two_column": 6,
    "source_unavailable": 7,
    "not_in_verified_set": 8,
}

RESOLVED = {"exact", "cosmetic", "half_turn_prime", "rotation_or_auf"}


def best_match(local: str, sources: list[str]) -> str:
    best = None
    for s in sources:
        for alt in split_alts(s):
            cls = classify_pair(local, alt)
            if cls is None:
                continue
            if best is None or RANK[cls] < RANK[best]:
                best = cls
            if best == "exact":
                return best
    return best or "unresolved"


def extract_leading_alg(line: str) -> str | None:
    """Cut metadata first, then require the remainder to fully tokenize."""
    line = line.strip().lstrip("*").strip()
    cut = METADATA_CUT_RE.search(line)
    if cut:
        line = line[: cut.start()]
    line = collapse_ws(line)
    if not line:
        return None
    toks = tokenize(line)
    if toks is None or len(toks) < 2:
        return None
    return line


def parse_local_cube_cases(path: Path, case_type: str) -> list[dict]:
    text = path.read_text()
    pat = re.compile(
        r"CubeCase\(\s*caseNumber:\s*(\d+),\s*caseType:\s*\""
        + re.escape(case_type)
        + r"\",\s*name:\s*\"([^\"]*)\",\s*primaryAlgorithm:\s*\"([^\"]*)\"",
        re.S,
    )
    out = []
    for n, name, alg in pat.findall(text):
        out.append({"id": int(n), "name": name, "primary": alg})
    return out


def parse_jperm_js(path: Path) -> dict[str, list[str]]:
    text = path.read_text()
    out: dict[str, list[str]] = {}
    for m in re.finditer(
        r"\{name:(\d+|\"[^\"]+\"),alg:\[(.*?)\]",
        text,
    ):
        raw_name, body = m.group(1), m.group(2)
        name = raw_name.strip('"')
        algs = re.findall(r"\"((?:\\.|[^\"])*)\"", body)
        cleaned = []
        for a in algs:
            a = a.encode("utf-8").decode("unicode_escape")
            cleaned.extend(split_alts(a))
        out[name] = cleaned
    return out


def parse_scdb_oll(path: Path) -> dict[str, list[str]]:
    text = path.read_text()
    out: dict[str, list[str]] = {}
    blocks = re.split(r"## \[OLL\s+(\d+)\]", text)
    for i in range(1, len(blocks), 2):
        cid = blocks[i]
        body = blocks[i + 1]
        algs: list[str] = []
        sm = re.search(
            r"Standard Alg:\s*(.*?)(?:\n\s*\*|\n\s*More Algorithms)", body, re.S
        )
        if sm:
            algs.extend(split_alts(sm.group(1).strip()))
        for bullet in re.findall(r"^\*\s+(.+)$", body, re.M):
            run = extract_leading_alg(bullet)
            if run:
                algs.append(run)
        out[cid] = algs
    return out


def parse_scdb_pll(path: Path) -> dict[str, list[str]]:
    text = path.read_text()
    out: dict[str, list[str]] = {}
    blocks = re.split(r"speedcubedb\.com/a/3x3/a/3x3/PLL/([A-Za-z]+)", text)
    for i in range(1, len(blocks), 2):
        name = blocks[i]
        body = blocks[i + 1]
        if name in out:
            continue
        algs: list[str] = []
        sm = re.search(r"Standard Alg:\s*(.*?)(?:\n\s*\*|\n\s*\[\])", body, re.S)
        if sm:
            algs.extend(split_alts(sm.group(1).strip()))
        for bullet in re.findall(r"^\*\s+(.+)$", body, re.M):
            run = extract_leading_alg(bullet)
            if run:
                algs.append(run)
        out[name] = algs
    return out


def parse_scdb_f2l(path: Path) -> dict[str, list[str]]:
    text = path.read_text()
    out: dict[str, list[str]] = {}
    blocks = re.split(r"F2L\s+(\d+)\b", text)
    for i in range(1, len(blocks), 2):
        cid = blocks[i]
        body = blocks[i + 1]
        if cid in out:
            continue
        algs: list[str] = []
        body = re.sub(r"setup:\s*[^\n]+", " ", body, count=1)
        for line in body.splitlines():
            line = line.strip()
            if not line or line in {
                "Front Right",
                "Front Left",
                "Back Left",
                "Back Right",
                "More Algorithms",
                "3x3",
                "-",
                "F2L",
            }:
                continue
            if line.startswith("F2L ") or line.startswith("Created"):
                break
            run = extract_leading_alg(line)
            if run:
                algs.append(run)
            if line == "More Algorithms":
                break
        out[cid] = algs
    return out


def _corpus_part_ok(part: str) -> bool:
    toks = tokenize(part)
    if toks is not None:
        return len(toks) >= 3
    rewritten = replace_square_auf(part)
    if rewritten is None:
        return False
    toks = tokenize(rewritten)
    return toks is not None and len(toks) >= 3


def cubeskills_corpus(path: Path) -> list[str]:
    """Bag of move sequences; not case-attributed (two-column PDF)."""
    if not path.exists():
        return []
    text = path.read_text()
    algs: list[str] = []
    for line in text.splitlines():
        if "Probability" in line or "Algorithm" in line or "Developed" in line:
            continue
        parts = re.split(r"\s{6,}", line.strip())
        for part in parts:
            part = part.strip()
            if not part:
                continue
            if _corpus_part_ok(part):
                algs.append(part)
    return algs


def pll_key(name: str) -> str:
    n = name.replace("-Perm", "").replace("Perm", "").strip()
    return n


def tally(rows: list[dict], key: str) -> dict[str, int]:
    c: dict[str, int] = defaultdict(int)
    for r in rows:
        c[r[key]] += 1
    return dict(sorted(c.items(), key=lambda kv: RANK.get(kv[0], 99)))


def any_source_resolved(row: dict, keys: list[str]) -> bool:
    return any(row.get(k) in RESOLVED for k in keys)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_cache(cache: Path) -> None:
    missing = [item["file"] for item in REQUIRED_SOURCES if not (cache / item["file"]).is_file()]
    if missing:
        req = ", ".join(f"{i['file']} <- {i['url']}" for i in REQUIRED_SOURCES)
        raise SystemExit(
            "missing required cache file(s): "
            + ", ".join(missing)
            + f" under {cache}. Required: {req}"
        )


def validate_parsed_counts(local: dict[str, int], sources: dict[str, int]) -> None:
    errors = []
    for k, n in EXPECTED_LOCAL.items():
        got = local.get(k)
        if got != n:
            errors.append(f"local {k} expected {n} got {got}")
    for item in REQUIRED_SOURCES:
        exp = item["expected_cases"]
        if exp is None:
            continue
        kind = item["kind"]
        got = sources.get(kind)
        if got != exp:
            errors.append(f"{kind} expected {exp} cases got {got}")
    if errors:
        raise SystemExit("incomplete parsed counts (refusing fake full audit): " + "; ".join(errors))


def fmt_tally(d: dict[str, int]) -> str:
    return "; ".join(f"{k} {v}" for k, v in d.items())


def resolved_count(d: dict[str, int]) -> int:
    return sum(v for k, v in d.items() if k in RESOLVED)


def render_report(payload: dict) -> str:
    s = payload["summary"]
    hashes = payload.get("source_hashes", [])
    hash_rows = "\n".join(
        f"| [{h['cite']}] | {h['url']} | `{h['file']}` | `{h['sha256'][:12]}…` | {h.get('parsed', '—')} |"
        for h in hashes
    )
    oll_rows = payload["oll"]
    pll_rows = payload["pll"]
    f2l_rows = payload["f2l"]

    def case_table_oll() -> str:
        lines = [
            "| # | Name | Primary | JPerm [1] | SCDB [3] | CS corpus [7] |",
            "| --- | --- | --- | --- | --- | --- |",
        ]
        for r in oll_rows:
            lines.append(
                f"| {r['id']} | {r['name']} | {r['primary']} | {r['jperm']} | {r['scdb']} | {r['cubeskills_corpus']} |"
            )
        return "\n".join(lines)

    def case_table_pll() -> str:
        lines = [
            "| # | Name | Key | Primary | JPerm [2] | SCDB [4] | CS corpus [6] |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ]
        for r in pll_rows:
            lines.append(
                f"| {r['id']} | {r['name']} | {r['pll_key']} | {r['primary']} | {r['jperm']} | {r['scdb']} | {r['cubeskills_corpus']} |"
            )
        return "\n".join(lines)

    def case_table_f2l() -> str:
        lines = [
            "| # | Name | Primary | SCDB same id [5] | SCDB elsewhere | Elsewhere (id:rank) | JPerm |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ]
        for r in f2l_rows:
            ranks = r.get("scdb_elsewhere_ranks") or {}
            if ranks:
                parts = []
                for i in r.get("scdb_elsewhere_ids", []):
                    rk = ranks.get(str(i), ranks.get(i, "?"))
                    parts.append(f"{i}:{rk}")
                detail = ", ".join(parts)
            else:
                detail = "—"
            lines.append(
                f"| {r['id']} | {r['name']} | {r['primary']} | {r['scdb_same_id']} | {r['scdb_elsewhere']} | {detail} | {r['jperm']} |"
            )
        return "\n".join(lines)

    oll_both_unresolved = [
        r["id"]
        for r in oll_rows
        if r["jperm"] == "unresolved" and r["scdb"] == "unresolved"
    ]
    oll_all_unresolved = [
        r["id"]
        for r in oll_rows
        if r["jperm"] == "unresolved"
        and r["scdb"] == "unresolved"
        and r["cubeskills_corpus"] == "unresolved"
    ]
    pll_cs_unresolved = [r["name"] for r in pll_rows if r["cubeskills_corpus"] == "unresolved"]

    loc = s["local_counts"]
    src = s["source_case_counts"]
    oll = s["oll"]
    pll = s["pll"]
    f2l = s["f2l"]
    primary_total = loc["OLL"] + loc["PLL"] + loc["F2L"]
    id_aligned_oll_pll = oll["resolved_any_id_source"] + pll["resolved_any_id_source"]
    id_aligned_total = loc["OLL"] + loc["PLL"]

    notes = payload.get("notes", {})

    return f"""# Algorithm verification (conservative source audit)

Bounded audit of CubeApp **primary** algorithms against already-downloaded public references. Local databases were not edited. No network fetch was performed in this pass.

Local primaries: **{loc['OLL']} OLL + {loc['PLL']} PLL** in `Sources/Core/Data/AlgorithmDatabase.swift`, **{loc['F2L']} F2L** in `Sources/Core/Data/F2LDatabase.swift`. AlgorithmDatabase.swift comments CubeSkills OLL/PLL sheets by Feliks Zemdegs and Andy Klise as the in-repo source note.

This report does **not** establish canonical algorithm identity. Matches are notation-string candidates only (no cube-state solver). `rotation_or_auf` is a loose notation relation after **leading** `x/y/z` rotations and **terminal** U-face AUF (including CubeSkills square `[U]` AUF brackets). That reduction is intentional and can create ambiguous F2L matches; it is not an identity proof.

## Sources used

Cached under `/tmp/cubeapp-audit/` from these URLs (hashes recorded for reproducibility):

| Id | URL | Cache file | SHA-256 prefix | Cases parsed |
| --- | --- | --- | --- | --- |
{hash_rows}

JPerm files are `algsetAlgs` objects with `name` plus `alg` arrays. Semicolon-separated alternatives inside a string are split before matching.[1][2]

SpeedCubeDB extracts include a Standard Alg plus bullet alternatives per case. Bullet metadata (Community, markdown images) is cut **before** strict tokenization.[3][4]

CubeSkills PDFs are two-column layouts. Individual-case assignment from the extracted text is skipped rather than guessed.[6][7]

`jperm-f2l.js` in cache is an HTML tutorial page, not `algsetAlgs` JS, so JPerm F2L is **source_unavailable**. `cubeskills-f2l.txt` is **not** in the verified URL set and is **not** read.

Repro: `python3 Scripts/audit_primary_algs_source_compare.py` (reads local Swift + `--cache-dir`, default `/tmp/cubeapp-audit/`; writes `--output` and compact `--docs-json`). Missing cache files or incomplete parsed case counts abort instead of emitting a fake full audit.

## Match ranks (conservative)

Compared **primary** only (not alternatives). No cube-state solver, no `r`↔`R` rewrite. Unknown letters/punctuation reject the entire candidate (no `findall` salvage). `2'` is preserved until the half-turn step. Square brackets are **not** cosmetic (round brackets only).

| Rank | Meaning |
| --- | --- |
| `exact` | whitespace-collapsed string equality |
| `cosmetic` | drop `()` only; fully consumed move-token sequences equal |
| `half_turn_prime` | cosmetic plus `X2'` = `X2` |
| `rotation_or_auf` | notation candidate after leading `x/y/z` and terminal U-face AUF / square `[U]` AUF; **not** claimed exact or state-equivalent |
| `unresolved` | no match at that source — **not** “invalid” |
| `exists_other_id` | F2L only: same-id miss, but a token match exists under a **different** SpeedCubeDB F2L id |
| `skipped_two_column` | CubeSkills: no case-id attribution |
| `source_unavailable` | cache is not algorithm data |
| `not_in_verified_set` | source URL was not in the verified set (CubeSkills F2L) |

Best rank wins per source. JPerm `alg` arrays and SpeedCubeDB Standard + bullets are the candidate sets.

## Coverage totals (computed)

Primary count = {loc['OLL']} + {loc['PLL']} + {loc['F2L']} = **{primary_total}**.

Parsed source cases: JPerm OLL {src.get('jperm_oll')}; JPerm PLL {src.get('jperm_pll')}; SCDB OLL {src.get('scdb_oll')}; SCDB PLL {src.get('scdb_pll')}; SCDB F2L {src.get('scdb_f2l')}; CubeSkills OLL corpus seqs {src.get('cubeskills_oll_corpus_seqs')}; CubeSkills PLL corpus seqs {src.get('cubeskills_pll_corpus_seqs')}. CubeSkills F2L corpus is unused.

### OLL ({loc['OLL']})

| Source | Tally | Resolved (not unresolved) |
| --- | --- | --- |
| JPerm same OLL id [1] | {fmt_tally(oll['jperm'])} | {resolved_count(oll['jperm'])}/{loc['OLL']} |
| SpeedCubeDB same OLL id [3] | {fmt_tally(oll['scdb'])} | {resolved_count(oll['scdb'])}/{loc['OLL']} |
| JPerm **or** SpeedCubeDB (id-aligned) | — | **{oll['resolved_any_id_source']}/{loc['OLL']}** |
| CubeSkills PDF corpus (unattributed) [7] | {fmt_tally(oll['cubeskills_corpus'])} | {resolved_count(oll['cubeskills_corpus'])}/{loc['OLL']} (not case-id verified) |

Id-aligned unresolved on **both** JPerm and SpeedCubeDB: {len(oll_both_unresolved)} cases ({", ".join(str(i) for i in oll_both_unresolved) or "none"}). Of those, CubeSkills corpus also unresolved: {len(oll_all_unresolved)} ({", ".join(str(i) for i in oll_all_unresolved) or "none"}).

### PLL ({loc['PLL']})

Matched by PLL name stem (`Aa-Perm` → `Aa`), not by CubeApp’s 1–21 index.

| Source | Tally | Resolved |
| --- | --- | --- |
| JPerm name [2] | {fmt_tally(pll['jperm'])} | {resolved_count(pll['jperm'])}/{loc['PLL']} |
| SpeedCubeDB name [4] | {fmt_tally(pll['scdb'])} | {resolved_count(pll['scdb'])}/{loc['PLL']} |
| JPerm **or** SpeedCubeDB | — | **{pll['resolved_any_id_source']}/{loc['PLL']}** |
| CubeSkills PDF corpus (unattributed) [6] | {fmt_tally(pll['cubeskills_corpus'])} | {resolved_count(pll['cubeskills_corpus'])}/{loc['PLL']} (not case-id verified) |

CubeSkills corpus unresolved (two-column / jammed extraction, not invalid): {", ".join(pll_cs_unresolved) or "none"}.

### F2L ({loc['F2L']})

SpeedCubeDB uses its own F2L numbering; a same-id miss is **not** automatically incorrect.[5] Leading-U AUF stripping is **not** applied; only terminal U and leading rotations. F2L AUF-removal can still create ambiguous matches and is reported as `rotation_or_auf`, not identity.

| Check | Tally | Count |
| --- | --- | --- |
| SpeedCubeDB same id [5] | {fmt_tally(f2l['scdb_same_id'])} | same-id resolved **{f2l['same_id_resolved']}/{loc['F2L']}** |
| Same-id miss, found under another SCDB F2L id | {fmt_tally(f2l['scdb_elsewhere'])} | **{f2l['elsewhere_only']}** elsewhere-only |
| Same-id unresolved **and** not found elsewhere | — | **{f2l['same_id_and_elsewhere_unresolved']}/{loc['F2L']}** |
| JPerm F2L | source_unavailable | {loc['F2L']}/{loc['F2L']} |
| CubeSkills F2L | not in verified URL set | — |

## Case-by-case: OLL

`cs_corpus` is unattributed CubeSkills PDF text, not a case-id claim.

{case_table_oll()}

## Case-by-case: PLL

{case_table_pll()}

## Case-by-case: F2L

`elsewhere (id:rank)` lists SpeedCubeDB F2L numbers where a conservative token match exists when the same id does not match, with the best notation rank for that other id. That is numbering-offset evidence, not a verdict that CubeApp is wrong.

{case_table_f2l()}

## Limitations

- **Primary only.** Alternatives in CubeApp were not scored.
- **Notation, not cube state.** No solver; `R' R'` vs `R2'` is unresolved, not merged. Wide vs regular (`r` vs `R`) is unresolved. This is not canonical identity.
- **Two-column CubeSkills PDFs.** pdftotext interleaves columns; per-case labels were not assigned.[6][7] Corpus hits only mean the move sequence appears somewhere in the extracted PDF text.
- **SpeedCubeDB F2L extract** is a flattened Jina markdown dump (slot labels + several algs per case). Same-id comparison is therefore weak; elsewhere-id hits are reported separately with ranks.[5]
- **JPerm F2L** cache is HTML, not the algorithm library JS.
- **No CubeSkills F2L URL** in the verified set; that cache file is not used.
- **`rotation_or_auf`** is a loose notation candidate after intentional leading-rotation / terminal-U (and square `[U]` AUF) reduction. F2L AUF-removal can create ambiguous matches.
- Cache hashes: see table above. Sources may have changed since download (cache dated from local files).
- This audit does not modify protected databases or tests and does not claim the local list is incorrect where matches are unresolved.

## Honest headline

| Set | Id/name-aligned resolved (JPerm and/or SCDB) | Unresolved on both id sources | Notes |
| --- | --- | --- | --- |
| OLL {loc['OLL']} | **{oll['resolved_any_id_source']}/{loc['OLL']}** | {len(oll_both_unresolved)} | CubeSkills corpus is unattributed; all-three unresolved: {", ".join(str(i) for i in oll_all_unresolved) or "none"} |
| PLL {loc['PLL']} | **{pll['resolved_any_id_source']}/{loc['PLL']}** | {sum(1 for r in pll_rows if r['jperm']=='unresolved' and r['scdb']=='unresolved')} | CubeSkills two-column misses labeled unresolved, not invalid |
| F2L {loc['F2L']} | **{f2l['same_id_resolved']}/{loc['F2L']} same-id**; {f2l['elsewhere_only']} exist under another SCDB id | {f2l['same_id_and_elsewhere_unresolved']} same-id and not elsewhere | numbering schemes differ; not scored as errors |

**Id-aligned coverage of OLL+PLL primaries: {id_aligned_oll_pll}/{id_aligned_total}.** F2L is largely **unresolved under conservative same-id comparison**, as expected when numbering is not shared.

Notes from run: JPerm F2L cache={notes.get('jperm_f2l_cache')}; CubeSkills={notes.get('cubeskills')}.

## Sources

[1] https://jperm.net/lib/oll.js — JPerm OLL algorithms JS
[2] https://jperm.net/lib/pll.js — JPerm PLL algorithms JS
[3] https://speedcubedb.com/a/3x3/OLL — SpeedCubeDB OLL
[4] https://speedcubedb.com/a/3x3/PLL — SpeedCubeDB PLL
[5] https://speedcubedb.com/a/3x3/F2L — SpeedCubeDB F2L
[6] https://www.cubeskills.com/uploads/pdf/tutorials/pll-algorithms.pdf — CubeSkills PLL PDF
[7] https://www.cubeskills.com/uploads/pdf/tutorials/oll-algorithms.pdf — CubeSkills OLL PDF
"""


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Conservative primary-alg source compare (offline cache).")
    p.add_argument("--cache-dir", type=Path, default=DEFAULT_CACHE)
    p.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    p.add_argument("--docs-json", type=Path, default=DEFAULT_DOCS_JSON)
    p.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    cache: Path = args.cache_dir
    validate_cache(cache)

    oll = parse_local_cube_cases(REPO / "Sources/Core/Data/AlgorithmDatabase.swift", "OLL")
    pll = parse_local_cube_cases(REPO / "Sources/Core/Data/AlgorithmDatabase.swift", "PLL")
    f2l = parse_local_cube_cases(REPO / "Sources/Core/Data/F2LDatabase.swift", "F2L")

    jperm_oll = parse_jperm_js(cache / "jperm-oll.js")
    jperm_pll = parse_jperm_js(cache / "jperm-pll.js")
    jperm_f2l_path = cache / "jperm-f2l.js"
    jperm_f2l_usable = False
    if jperm_f2l_path.exists():
        text_head = jperm_f2l_path.read_text()[:2000]
        jperm_f2l_usable = "algsetAlgs" in text_head and not text_head.lstrip().startswith("<!")

    scdb_oll = parse_scdb_oll(cache / "scdb-oll.md")
    scdb_pll = parse_scdb_pll(cache / "scdb-pll.md")
    scdb_f2l = parse_scdb_f2l(cache / "scdb-f2l.md")

    cs_oll_corpus = cubeskills_corpus(cache / "cubeskills-oll.txt")
    cs_pll_corpus = cubeskills_corpus(cache / "cubeskills-pll.txt")

    local_counts = {"OLL": len(oll), "PLL": len(pll), "F2L": len(f2l)}
    source_case_counts = {
        "jperm_oll": len(jperm_oll),
        "jperm_pll": len(jperm_pll),
        "scdb_oll": len(scdb_oll),
        "scdb_pll": len(scdb_pll),
        "scdb_f2l": len(scdb_f2l),
        "cubeskills_oll_corpus_seqs": len(cs_oll_corpus),
        "cubeskills_pll_corpus_seqs": len(cs_pll_corpus),
    }
    validate_parsed_counts(local_counts, source_case_counts)

    source_hashes = []
    for item in REQUIRED_SOURCES:
        path = cache / item["file"]
        parsed = source_case_counts.get(item["kind"])
        if item["kind"] == "cubeskills_oll_corpus":
            parsed = f"{len(cs_oll_corpus)} seqs"
        elif item["kind"] == "cubeskills_pll_corpus":
            parsed = f"{len(cs_pll_corpus)} seqs"
        source_hashes.append(
            {
                "file": item["file"],
                "url": item["url"],
                "cite": item["cite"],
                "sha256": sha256_file(path),
                "parsed": parsed if parsed is not None else source_case_counts.get(item["kind"]),
            }
        )

    oll_rows = []
    for c in oll:
        cid = str(c["id"])
        row = {
            "id": c["id"],
            "name": c["name"],
            "primary": c["primary"],
            "jperm": best_match(c["primary"], jperm_oll.get(cid, [])),
            "scdb": best_match(c["primary"], scdb_oll.get(cid, [])),
            "cubeskills_case": "skipped_two_column",
            "cubeskills_corpus": best_match(c["primary"], cs_oll_corpus)
            if cs_oll_corpus
            else "unresolved",
        }
        oll_rows.append(row)

    pll_rows = []
    for c in pll:
        key = pll_key(c["name"])
        row = {
            "id": c["id"],
            "name": c["name"],
            "pll_key": key,
            "primary": c["primary"],
            "jperm": best_match(c["primary"], jperm_pll.get(key, [])),
            "scdb": best_match(c["primary"], scdb_pll.get(key, [])),
            "cubeskills_case": "skipped_two_column",
            "cubeskills_corpus": best_match(c["primary"], cs_pll_corpus)
            if cs_pll_corpus
            else "unresolved",
        }
        pll_rows.append(row)

    f2l_rows = []
    all_other: list[tuple[str, str]] = []
    for oid, algs in scdb_f2l.items():
        for a in algs:
            all_other.append((oid, a))

    for c in f2l:
        cid = str(c["id"])
        same = best_match(c["primary"], scdb_f2l.get(cid, []))
        other_ranks: dict[str, str] = {}
        if same == "unresolved":
            for oid, a in all_other:
                if oid == cid:
                    continue
                cls = classify_pair(c["primary"], a)
                if cls is None:
                    continue
                prev = other_ranks.get(oid)
                if prev is None or RANK[cls] < RANK[prev]:
                    other_ranks[oid] = cls
        other_ids = sorted(other_ranks, key=int)
        other_hit = "exists_other_id" if other_ranks else ("n/a" if same != "unresolved" else "unresolved")
        row = {
            "id": c["id"],
            "name": c["name"],
            "primary": c["primary"],
            "jperm": "source_unavailable" if not jperm_f2l_usable else "unresolved",
            "scdb_same_id": same,
            "scdb_elsewhere": other_hit,
            "scdb_elsewhere_ids": other_ids,
            "scdb_elsewhere_ranks": other_ranks,
            "cubeskills_case": "not_in_verified_set",
            "cubeskills_corpus": "not_in_verified_set",
        }
        f2l_rows.append(row)

    summary = {
        "local_counts": local_counts,
        "source_case_counts": source_case_counts,
        "oll": {
            "jperm": tally(oll_rows, "jperm"),
            "scdb": tally(oll_rows, "scdb"),
            "cubeskills_corpus": tally(oll_rows, "cubeskills_corpus"),
            "resolved_any_id_source": sum(
                1 for r in oll_rows if any_source_resolved(r, ["jperm", "scdb"])
            ),
        },
        "pll": {
            "jperm": tally(pll_rows, "jperm"),
            "scdb": tally(pll_rows, "scdb"),
            "cubeskills_corpus": tally(pll_rows, "cubeskills_corpus"),
            "resolved_any_id_source": sum(
                1 for r in pll_rows if any_source_resolved(r, ["jperm", "scdb"])
            ),
        },
        "f2l": {
            "scdb_same_id": tally(f2l_rows, "scdb_same_id"),
            "scdb_elsewhere": tally(f2l_rows, "scdb_elsewhere"),
            "same_id_resolved": sum(1 for r in f2l_rows if r["scdb_same_id"] in RESOLVED),
            "elsewhere_only": sum(1 for r in f2l_rows if r["scdb_elsewhere"] == "exists_other_id"),
            "same_id_and_elsewhere_unresolved": sum(
                1
                for r in f2l_rows
                if r["scdb_same_id"] == "unresolved" and r["scdb_elsewhere"] == "unresolved"
            ),
        },
    }

    payload = {
        "summary": summary,
        "source_hashes": source_hashes,
        "required_sources": REQUIRED_SOURCES,
        "oll": oll_rows,
        "pll": pll_rows,
        "f2l": f2l_rows,
        "notes": {
            "jperm_f2l_cache": "HTML tutorial page, not algsetAlgs JS"
            if not jperm_f2l_usable
            else "ok",
            "cubeskills": "two-column PDF extraction: no per-case attribution; F2L cache unused",
            "matcher": (
                "strict full-consume tokenize; 2' preserved until half_turn_prime; "
                "square [U] AUF is rotation_or_auf not cosmetic; "
                "leading rotations + terminal U only; not state-equivalent"
            ),
        },
    }

    compact = {
        "summary": summary,
        "source_hashes": source_hashes,
        "notes": payload["notes"],
        "oll": oll_rows,
        "pll": pll_rows,
        "f2l": f2l_rows,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n")
    args.docs_json.parent.mkdir(parents=True, exist_ok=True)
    args.docs_json.write_text(json.dumps(compact, indent=2) + "\n")
    args.report.write_text(render_report(payload))

    json.dump(summary, sys.stdout, indent=2)
    print()
    print("wrote", args.output)
    print("wrote", args.docs_json)
    print("wrote", args.report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
