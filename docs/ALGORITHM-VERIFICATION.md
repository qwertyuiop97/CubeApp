# Algorithm source comparison

This report compares the primary algorithms in CubeNotch with saved reference data. It records text matches and differences; it does not verify the starting cube state for each case.

Local primaries: **57 OLL + 21 PLL** in `Sources/Core/Data/AlgorithmDatabase.swift`, **41 F2L** in `Sources/Core/Data/F2LDatabase.swift`. AlgorithmDatabase.swift comments CubeSkills OLL/PLL sheets by Feliks Zemdegs and Andy Klise as the in-repo source note.

This report does **not** establish canonical algorithm identity. Matches are notation-string candidates only (no cube-state solver). `rotation_or_auf` is a loose notation relation after **leading** `x/y/z` rotations and **terminal** U-face AUF (including CubeSkills square `[U]` AUF brackets). That reduction is intentional and can create ambiguous F2L matches; it is not an identity proof.

## Sources used

Cached under `/tmp/cubeapp-audit/` from these URLs (hashes recorded for reproducibility):

| Id | URL | Cache file | SHA-256 prefix | Cases parsed |
| --- | --- | --- | --- | --- |
| [1] | https://jperm.net/lib/oll.js | `jperm-oll.js` | `d893a359ccbb…` | 57 |
| [2] | https://jperm.net/lib/pll.js | `jperm-pll.js` | `c455bd663c80…` | 21 |
| [3] | https://speedcubedb.com/a/3x3/OLL | `scdb-oll.md` | `16417986cb83…` | 57 |
| [4] | https://speedcubedb.com/a/3x3/PLL | `scdb-pll.md` | `3d7a3fe1142f…` | 21 |
| [5] | https://speedcubedb.com/a/3x3/F2L | `scdb-f2l.md` | `6996b57270d1…` | 41 |
| [6] | https://www.cubeskills.com/uploads/pdf/tutorials/pll-algorithms.pdf | `cubeskills-pll.txt` | `240b66f27c90…` | 36 seqs |
| [7] | https://www.cubeskills.com/uploads/pdf/tutorials/oll-algorithms.pdf | `cubeskills-oll.txt` | `fef8c73a02cb…` | 83 seqs |

JPerm files are `algsetAlgs` objects with `name` plus `alg` arrays. Semicolon-separated alternatives inside a string are split before matching.[1][2]

SpeedCubeDB extracts include a Standard Alg plus bullet alternatives per case. Bullet metadata (Community, markdown images) is cut **before** strict tokenization.[3][4]

CubeSkills PDFs are two-column layouts. Individual-case assignment from the extracted text is skipped rather than guessed.[6][7]

`jperm-f2l.js` in cache is an HTML tutorial page, not `algsetAlgs` JS, so JPerm F2L is **source_unavailable**. `cubeskills-f2l.txt` is **not** in the verified URL set and is **not** read.

Repro: `python3 Scripts/audit_primary_algs_source_compare.py` (reads local Swift + `--cache-dir`, default `/tmp/cubeapp-audit/`; writes `--output` and compact `--docs-json`). Missing cache files or incomplete parsed case counts abort rather than producing an incomplete report.

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

Primary count = 57 + 21 + 41 = **119**.

Parsed source cases: JPerm OLL 57; JPerm PLL 21; SCDB OLL 57; SCDB PLL 21; SCDB F2L 41; CubeSkills OLL corpus seqs 83; CubeSkills PLL corpus seqs 36. CubeSkills F2L corpus is unused.

### OLL (57)

| Source | Tally | Resolved (not unresolved) |
| --- | --- | --- |
| JPerm same OLL id [1] | exact 19; cosmetic 2; half_turn_prime 8; rotation_or_auf 17; unresolved 11 | 46/57 |
| SpeedCubeDB same OLL id [3] | exact 28; half_turn_prime 12; rotation_or_auf 13; unresolved 4 | 53/57 |
| JPerm **or** SpeedCubeDB (id-aligned) | — | **54/57** |
| CubeSkills PDF corpus (unattributed) [7] | exact 6; cosmetic 47; unresolved 4 | 53/57 (not case-id verified) |

Id-aligned unresolved on **both** JPerm and SpeedCubeDB: 3 cases (20, 36, 52). Of those, CubeSkills corpus also unresolved: 0 (none).

### PLL (21)

Matched by PLL name stem (`Aa-Perm` → `Aa`), not by CubeApp’s 1–21 index.

| Source | Tally | Resolved |
| --- | --- | --- |
| JPerm name [2] | exact 7; cosmetic 3; half_turn_prime 1; rotation_or_auf 4; unresolved 6 | 15/21 |
| SpeedCubeDB name [4] | exact 10; half_turn_prime 4; rotation_or_auf 7 | 21/21 |
| JPerm **or** SpeedCubeDB | — | **21/21** |
| CubeSkills PDF corpus (unattributed) [6] | cosmetic 11; rotation_or_auf 8; unresolved 2 | 19/21 (not case-id verified) |

CubeSkills corpus unresolved (two-column / jammed extraction, not invalid): Na-Perm, Nb-Perm.

### F2L (41)

SpeedCubeDB uses its own F2L numbering; a same-id miss is **not** automatically incorrect.[5] Leading-U AUF stripping is **not** applied; only terminal U and leading rotations. F2L AUF-removal can still create ambiguous matches and is reported as `rotation_or_auf`, not identity.

| Check | Tally | Count |
| --- | --- | --- |
| SpeedCubeDB same id [5] | unresolved 41 | same-id resolved **0/41** |
| Same-id miss, found under another SCDB F2L id | exists_other_id 8; unresolved 33 | **8** elsewhere-only |
| Same-id unresolved **and** not found elsewhere | — | **33/41** |
| JPerm F2L | source_unavailable | 41/41 |
| CubeSkills F2L | not in verified URL set | — |

## Case-by-case: OLL

`cs_corpus` is unattributed CubeSkills PDF text, not a case-id claim.

| # | Name | Primary | JPerm [1] | SCDB [3] | CS corpus [7] |
| --- | --- | --- | --- | --- | --- |
| 1 | Dot 1 | R U2' R2' F R F' U2' R' F R F' | unresolved | half_turn_prime | cosmetic |
| 2 | Dot 2 | F R U R' U' F' f R U R' U' f' | rotation_or_auf | exact | cosmetic |
| 3 | Dot 3 | f R U R' U' f' U' F R U R' U' F' | rotation_or_auf | rotation_or_auf | cosmetic |
| 4 | Dot 4 | f R U R' U' f' U F R U R' U' F' | rotation_or_auf | rotation_or_auf | cosmetic |
| 5 | Square 1 | r' U2' R U R' U r | rotation_or_auf | half_turn_prime | cosmetic |
| 6 | Square 2 | r U2 R' U' R U' r' | exact | exact | cosmetic |
| 7 | Lightning 1 | r U R' U R U2' r' | half_turn_prime | half_turn_prime | cosmetic |
| 8 | Lightning 2 | r' U' R U' R' U2 r | rotation_or_auf | rotation_or_auf | cosmetic |
| 9 | Fish 1 | R U R' U' R' F R2 U R' U' F' | exact | rotation_or_auf | cosmetic |
| 10 | Fish 2 | R U R' U R' F R F' R U2' R' | half_turn_prime | half_turn_prime | cosmetic |
| 11 | Lightning 3 | r' R2 U R' U R U2 R' U M' | rotation_or_auf | exact | cosmetic |
| 12 | Lightning 4 | M' R' U' R U' R' U2 R U' M | unresolved | rotation_or_auf | cosmetic |
| 13 | Knight Move 1 | r U' r' U' r U r' y' R' U R | exact | unresolved | cosmetic |
| 14 | Knight Move 2 | R' F R U R' F' R F U' F' | exact | exact | cosmetic |
| 15 | Knight Move 3 | r' U' r R' U' R U r' U r | rotation_or_auf | exact | cosmetic |
| 16 | Knight Move 4 | r U r' R U R' U' r U' r' | exact | exact | cosmetic |
| 17 | Dot 5 | R U R' U R' F R F' U2' R' F R F' | rotation_or_auf | half_turn_prime | cosmetic |
| 18 | Dot 6 | y R U2' R2' F R F' U2' M' U R U' r' | unresolved | half_turn_prime | unresolved |
| 19 | Dot 7 | M U R U R' U' M' R' F R F' | unresolved | exact | unresolved |
| 20 | Dot 8 | M U R U R' U' M2' U R U' r' | unresolved | unresolved | cosmetic |
| 21 | All Edges 1 | R U2 R' U' R U R' U' R U' R' | exact | rotation_or_auf | cosmetic |
| 22 | All Edges 2 (Pi) | R U2' R2' U' R2 U' R2' U2' R | half_turn_prime | half_turn_prime | exact |
| 23 | All Edges 3 (U) | R2 D R' U2 R D' R' U2 R' | rotation_or_auf | exact | cosmetic |
| 24 | All Edges 4 (T) | r U R' U' r' F R F' | exact | exact | cosmetic |
| 25 | All Edges 5 (L) | y F' r U R' U' r' F R | rotation_or_auf | exact | cosmetic |
| 26 | Anti-Sune | R U2 R' U' R U' R' | cosmetic | rotation_or_auf | exact |
| 27 | Sune | R U R' U R U2' R' | half_turn_prime | half_turn_prime | exact |
| 28 | Edge Flip 1 | r U R' U' M U R U' R' | unresolved | exact | cosmetic |
| 29 | Awkward 1 | y R U R' U' R U' R' F' U' F R U R' | rotation_or_auf | exact | unresolved |
| 30 | Awkward 2 | y' F U R U2 R' U' R U2 R' U' F' | rotation_or_auf | rotation_or_auf | unresolved |
| 31 | P-Shape 1 | R' U' F U R U' R' F' R | exact | exact | cosmetic |
| 32 | P-Shape 2 | R U B' U' R' U R B R' | unresolved | exact | cosmetic |
| 33 | T-Shape 1 | R U R' U' R' F R F' | exact | exact | cosmetic |
| 34 | C-Shape 1 | R U R2' U' R' F R U R U' F' | half_turn_prime | rotation_or_auf | cosmetic |
| 35 | Fish 3 | R U2' R2' F R F' R U2' R' | unresolved | half_turn_prime | cosmetic |
| 36 | W-Shape 1 | R' U' R U' R' U R U l U' R' U x | unresolved | unresolved | cosmetic |
| 37 | Fish 4 | F R U' R' U' R U R' F' | exact | exact | cosmetic |
| 38 | W-Shape 2 | R U R' U R U' R' U' R' F R F' | exact | exact | cosmetic |
| 39 | Lightning 5 | L F' L' U' L U F U' L' | exact | rotation_or_auf | cosmetic |
| 40 | Lightning 6 | R' F R U R' U' F' U R | exact | rotation_or_auf | cosmetic |
| 41 | Awkward 3 | R U R' U R U2' R' F R U R' U' F' | half_turn_prime | rotation_or_auf | cosmetic |
| 42 | Awkward 4 | R' U' R U' R' U2 R F R U R' U' F' | exact | exact | cosmetic |
| 43 | P-Shape 3 | y R' U' F' U F R | unresolved | exact | exact |
| 44 | P-Shape 4 | f R U R' U' f' | rotation_or_auf | exact | cosmetic |
| 45 | T-Shape 2 | F R U R' U' F' | exact | exact | cosmetic |
| 46 | C-Shape 2 | R' U' R' F R F' U R | exact | exact | cosmetic |
| 47 | L-Shape 1 | F' L' U' L U L' U' L U F | exact | exact | cosmetic |
| 48 | L-Shape 2 | F R U R' U' R U R' U' F' | exact | exact | cosmetic |
| 49 | L-Shape 3 | r U' r2' U r2 U r2' U' r | half_turn_prime | rotation_or_auf | exact |
| 50 | L-Shape 4 | r' U r2 U' r2' U' r2 U r' | half_turn_prime | half_turn_prime | exact |
| 51 | I-Shape 1 | f R U R' U' R U R' U' f' | rotation_or_auf | exact | cosmetic |
| 52 | I-Shape 2 | R' U' R U' R' U y' R' U R B | unresolved | unresolved | cosmetic |
| 53 | L-Shape 5 | r' U' R U' R' U R U' R' U2 r | rotation_or_auf | exact | cosmetic |
| 54 | L-Shape 6 | r U R' U R U' R' U R U2' r' | rotation_or_auf | half_turn_prime | cosmetic |
| 55 | I-Shape 3 | y R' F R U R U' R2' F' R2 U' R' U R U R' | rotation_or_auf | half_turn_prime | cosmetic |
| 56 | I-Shape 4 | r' U' r U' R' U R U' R' U R r' U r | cosmetic | exact | cosmetic |
| 57 | Edge Flip 2 | R U R' U' M' U R U' r' | exact | exact | cosmetic |

## Case-by-case: PLL

| # | Name | Key | Primary | JPerm [2] | SCDB [4] | CS corpus [6] |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Aa-Perm | Aa | x R' U R' D2 R U' R' D2 R2 x' | unresolved | exact | cosmetic |
| 2 | Ab-Perm | Ab | x R2' D2 R U R' D2 R U' R x' | unresolved | half_turn_prime | cosmetic |
| 3 | F-Perm | F | R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R | exact | rotation_or_auf | cosmetic |
| 4 | Ga-Perm | Ga | R2 U R' U R' U' R U' R2 D U' R' U R D' | unresolved | exact | rotation_or_auf |
| 5 | Gb-Perm | Gb | F' U' F R2 u R' U R U' R u' R2' | rotation_or_auf | rotation_or_auf | cosmetic |
| 6 | Gc-Perm | Gc | R2 U' R U' R U R' U R2 D' U R U' R' D | unresolved | exact | rotation_or_auf |
| 7 | Gd-Perm | Gd | D' R U R' U' D R2 U' R U' R' U R' U R2 | unresolved | exact | rotation_or_auf |
| 8 | E-Perm | E | x' R U' R' D R U R' D' R U R' D R U' R' D' x | unresolved | rotation_or_auf | cosmetic |
| 9 | H-Perm | H | M2' U M2' U2 M2' U M2' | half_turn_prime | half_turn_prime | cosmetic |
| 10 | Ja-Perm | Ja | R' U L' U2 R U' R' U2 R L | rotation_or_auf | rotation_or_auf | rotation_or_auf |
| 11 | Jb-Perm | Jb | R U R' F' R U R' U' R' F R2 U' R' | exact | exact | rotation_or_auf |
| 12 | Na-Perm | Na | R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R' | exact | exact | unresolved |
| 13 | Nb-Perm | Nb | R' U R U' R' F' U' F R U R' F R' F' R U' R | cosmetic | exact | unresolved |
| 14 | Ra-Perm | Ra | R U' R' U' R U R D R' U' R D' R' U2 R' | exact | rotation_or_auf | rotation_or_auf |
| 15 | Rb-Perm | Rb | R' U2 R U2' R' F R U R' U' R' F' R2 | rotation_or_auf | half_turn_prime | rotation_or_auf |
| 16 | T-Perm | T | R U R' U' R' F R2 U' R' U' R U R' F' | cosmetic | exact | cosmetic |
| 17 | Ua-Perm | Ua | R U' R U R U R U' R' U' R2 | exact | rotation_or_auf | cosmetic |
| 18 | Ub-Perm | Ub | R2 U R U R' U' R' U' R' U R' | cosmetic | rotation_or_auf | cosmetic |
| 19 | V-Perm | V | R' U R' U' y R' F' R2 U' R' U R' F R F | exact | exact | cosmetic |
| 20 | Y-Perm | Y | F R U' R' U' R U R' F' R U R' U' R' F R F' | exact | exact | cosmetic |
| 21 | Z-Perm | Z | M2' U M2' U M' U2 M2' U2 M' | rotation_or_auf | half_turn_prime | rotation_or_auf |

## Case-by-case: F2L

`elsewhere (id:rank)` lists SpeedCubeDB F2L numbers where a conservative token match exists when the same id does not match, with the best notation rank for that other id. These matches may help map case numbers; they do not establish which starting state a case depicts.

| # | Name | Primary | SCDB same id [5] | SCDB elsewhere | Elsewhere (id:rank) | JPerm |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Basic FR | R U' R' | unresolved | unresolved | — | source_unavailable |
| 2 | Basic FL | L' U L | unresolved | unresolved | — | source_unavailable |
| 3 | Pair Ready FR | R U R' | unresolved | exists_other_id | 4:exact | source_unavailable |
| 4 | Pair Ready FL | L' U' L | unresolved | exists_other_id | 3:rotation_or_auf | source_unavailable |
| 5 | Edge Flip FR | R U2 R' U' R U' R' | unresolved | unresolved | — | source_unavailable |
| 6 | Edge Flip FL | L' U2 L U L' U L | unresolved | unresolved | — | source_unavailable |
| 7 | Corner Flip FR | R U R' U R U2 R' | unresolved | unresolved | — | source_unavailable |
| 8 | Corner Flip FL | L' U' L U' L' U2 L | unresolved | unresolved | — | source_unavailable |
| 9 | Both Flip FR | R U' R' U' R U R' U2 R U' R' | unresolved | exists_other_id | 38:exact | source_unavailable |
| 10 | Both Flip FL | L' U L U L' U' L U2 L' U L | unresolved | unresolved | — | source_unavailable |
| 11 | Back Slot FR | R' U' R U' R' U2 R | unresolved | unresolved | — | source_unavailable |
| 12 | Back Slot FL | L U L' U L U2 L' | unresolved | unresolved | — | source_unavailable |
| 13 | Split Pair FR | R U' R' U R U R' | unresolved | unresolved | — | source_unavailable |
| 14 | Split Pair FL | L' U L U' L' U' L | unresolved | unresolved | — | source_unavailable |
| 15 | Connected Pair FR | R U R' U' R U' R' | unresolved | unresolved | — | source_unavailable |
| 16 | Connected Pair FL | L' U' L U L' U L | unresolved | unresolved | — | source_unavailable |
| 17 | White on Top FR | R U' R' U2 R U' R' | unresolved | unresolved | — | source_unavailable |
| 18 | White on Top FL | L' U L U2 L' U L | unresolved | unresolved | — | source_unavailable |
| 19 | Sledge FR | R' F R F' | unresolved | exists_other_id | 1:exact | source_unavailable |
| 20 | Sledge FL | L F' L' F | unresolved | unresolved | — | source_unavailable |
| 21 | Hedgeslammer FR | F R' F' R | unresolved | exists_other_id | 2:exact | source_unavailable |
| 22 | Hedgeslammer FL | F' L F L' | unresolved | unresolved | — | source_unavailable |
| 23 | Wide Sledge FR | r U' r' F R' F' R | unresolved | unresolved | — | source_unavailable |
| 24 | Wide Sledge FL | l' U l F' L F L' | unresolved | unresolved | — | source_unavailable |
| 25 | Keyhole FR | R U' R' U' R U R' U' R U' R' | unresolved | unresolved | — | source_unavailable |
| 26 | Keyhole FL | L' U L U L' U' L U L' U L | unresolved | unresolved | — | source_unavailable |
| 27 | Free Pair FR | R U R' U' R U R' | unresolved | exists_other_id | 30:exact | source_unavailable |
| 28 | Free Pair FL | L' U' L U L' U' L | unresolved | exists_other_id | 29:rotation_or_auf | source_unavailable |
| 29 | F2L 29 | R U2 R' U R U' R' | unresolved | unresolved | — | source_unavailable |
| 30 | F2L 30 | L' U2 L U' L' U L | unresolved | unresolved | — | source_unavailable |
| 31 | F2L 31 | R U R' U R U2 R' | unresolved | unresolved | — | source_unavailable |
| 32 | F2L 32 | L' U' L U' L' U2 L | unresolved | unresolved | — | source_unavailable |
| 33 | F2L 33 | R U' R' U' R U2 R' | unresolved | unresolved | — | source_unavailable |
| 34 | F2L 34 | L' U L U L' U2 L | unresolved | unresolved | — | source_unavailable |
| 35 | F2L 35 | R U R' U2 R U' R' U R U' R' | unresolved | exists_other_id | 15:exact | source_unavailable |
| 36 | F2L 36 | L' U' L U2 L' U L U' L' U L | unresolved | unresolved | — | source_unavailable |
| 37 | F2L 37 | R U' R' U R U R' U R U' R' | unresolved | unresolved | — | source_unavailable |
| 38 | F2L 38 | L' U L U' L' U' L U' L' U L | unresolved | unresolved | — | source_unavailable |
| 39 | F2L 39 | R U2 R2 U' R2 U' R2 U2 R | unresolved | unresolved | — | source_unavailable |
| 40 | F2L 40 | R U R' U' R U' R' U2 R U' R' | unresolved | unresolved | — | source_unavailable |
| 41 | F2L 41 | R U' R' U R U R' U' R U' R' | unresolved | unresolved | — | source_unavailable |

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

## Summary

| Set | Id/name-aligned resolved (JPerm and/or SCDB) | Unresolved on both id sources | Notes |
| --- | --- | --- | --- |
| OLL 57 | **54/57** | 3 | CubeSkills corpus is unattributed; all-three unresolved: none |
| PLL 21 | **21/21** | 0 | CubeSkills two-column misses labeled unresolved, not invalid |
| F2L 41 | **0/41 same-id**; 8 exist under another SCDB id | 33 same-id and not elsewhere | numbering schemes differ; not scored as errors |

**Id-aligned coverage of OLL+PLL primaries: 75/78.** F2L is largely **unresolved under conservative same-id comparison**, as expected when numbering is not shared.

Notes from run: JPerm F2L cache=HTML tutorial page, not algsetAlgs JS; CubeSkills=two-column PDF extraction: no per-case attribution; F2L cache unused.

## Sources

[1] https://jperm.net/lib/oll.js — JPerm OLL algorithms JS
[2] https://jperm.net/lib/pll.js — JPerm PLL algorithms JS
[3] https://speedcubedb.com/a/3x3/OLL — SpeedCubeDB OLL
[4] https://speedcubedb.com/a/3x3/PLL — SpeedCubeDB PLL
[5] https://speedcubedb.com/a/3x3/F2L — SpeedCubeDB F2L
[6] https://www.cubeskills.com/uploads/pdf/tutorials/pll-algorithms.pdf — CubeSkills PLL PDF
[7] https://www.cubeskills.com/uploads/pdf/tutorials/oll-algorithms.pdf — CubeSkills OLL PDF
