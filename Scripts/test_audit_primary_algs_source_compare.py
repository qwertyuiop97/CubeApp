#!/usr/bin/env python3
"""Regression tests for conservative primary-alg source compare."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "audit_primary_algs_source_compare.py"
SPEC = importlib.util.spec_from_file_location("audit_primary_algs_source_compare", SCRIPT)
assert SPEC and SPEC.loader
m = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(m)


class TokenizeStrictTests(unittest.TestCase):
    def test_preserves_half_turn_prime_until_normalization(self):
        toks = m.tokenize("R2' U")
        self.assertEqual(toks, ["R2'", "U"])

    def test_unknown_letter_rejects_entire_candidate(self):
        self.assertIsNone(m.tokenize("R Q U"))

    def test_does_not_salvage_valid_prefix_from_junk(self):
        self.assertIsNone(m.tokenize("R Q U"))
        self.assertIsNone(m.classify_pair("R U", "R Q U"))

    def test_unknown_punctuation_rejects_entire_candidate(self):
        self.assertIsNone(m.tokenize("R U, R"))
        self.assertIsNone(m.classify_pair("R U R", "R U, R"))

    def test_round_brackets_are_cosmetic_only(self):
        self.assertEqual(m.classify_pair("R U R'", "(R U) R'"), "cosmetic")

    def test_square_auf_brackets_are_not_cosmetic(self):
        self.assertNotEqual(m.classify_pair("R U", "R [U]"), "cosmetic")
        self.assertEqual(m.classify_pair("R U", "R [U]"), "rotation_or_auf")

    def test_non_auf_square_brackets_reject(self):
        self.assertIsNone(m.classify_pair("R F U", "R [F] U"))

    def test_half_turn_prime_rank(self):
        self.assertEqual(m.classify_pair("R2 U", "R2' U"), "half_turn_prime")
        self.assertEqual(m.classify_pair("R2' U", "R2 U"), "half_turn_prime")

    def test_leading_rotation_is_loose_notation_candidate(self):
        self.assertEqual(m.classify_pair("R U R'", "y R U R'"), "rotation_or_auf")

    def test_terminal_u_removal_is_loose_not_leading_u(self):
        self.assertEqual(m.classify_pair("R U R'", "R U R' U2"), "rotation_or_auf")
        self.assertIsNone(m.classify_pair("R U' R'", "U R U' R'"))

    def test_wide_and_slice_tokens_consumed(self):
        self.assertEqual(m.tokenize("r U R' U' M'"), ["r", "U", "R'", "U'", "M'"])
        self.assertEqual(m.tokenize("Rw2' U"), ["Rw2'", "U"])


class ExtractLeadingAlgTests(unittest.TestCase):
    def test_cuts_community_before_tokenize(self):
        line = "R U2 R2 F R F' U2 R' F R F'             Community Votes: 149 Movecount: 11"
        got = m.extract_leading_alg(line)
        self.assertIsNotNone(got)
        self.assertNotIn("Community", got)
        self.assertNotIn("Votes", got)
        self.assertEqual(m.tokenize(got), ["R", "U2", "R2", "F", "R", "F'", "U2", "R'", "F", "R", "F'"])

    def test_cuts_markdown_image_before_tokenize(self):
        line = (
            "R U2 R2 F R F' U2 R' F R F'             "
            "[![Image 5](https://img.youtube.com/vi/Krt5t5X9gTo/0.jpg)]"
            "(https://www.youtube.com/watch?v=Krt5t5X9gTo)Community Votes: 149"
        )
        got = m.extract_leading_alg(line)
        self.assertIsNotNone(got)
        self.assertNotIn("youtube", got)
        self.assertNotIn("Image", got)
        self.assertNotIn("http", got)
        toks = m.tokenize(got)
        self.assertIsNotNone(toks)
        self.assertNotIn("K", toks)
        self.assertEqual(toks[-1], "F'")

    def test_rejects_unknown_letter_line_instead_of_prefix(self):
        self.assertIsNone(m.extract_leading_alg("R Q U"))
        self.assertIsNone(m.extract_leading_alg("*   R Q U Community Votes: 1"))


class CacheAndConfigTests(unittest.TestCase):
    def test_required_sources_identified(self):
        names = {item["file"] for item in m.REQUIRED_SOURCES}
        self.assertEqual(
            names,
            {
                "jperm-oll.js",
                "jperm-pll.js",
                "scdb-oll.md",
                "scdb-pll.md",
                "scdb-f2l.md",
                "cubeskills-oll.txt",
                "cubeskills-pll.txt",
            },
        )
        self.assertTrue(all("url" in item for item in m.REQUIRED_SOURCES))
        files = {item["file"] for item in m.REQUIRED_SOURCES}
        self.assertNotIn("cubeskills-f2l.txt", files)
        self.assertNotIn("jperm-f2l.js", files)

    def test_missing_cache_fails_clearly(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(SystemExit) as ctx:
                m.validate_cache(Path(tmp))
            self.assertIn("jperm-oll.js", str(ctx.exception))

    def test_incomplete_parsed_counts_fail(self):
        with self.assertRaises(SystemExit) as ctx:
            m.validate_parsed_counts(
                local={"OLL": 57, "PLL": 21, "F2L": 40},
                sources={"jperm_oll": 57},
            )
        msg = str(ctx.exception)
        self.assertTrue("F2L" in msg or "40" in msg or "incomplete" in msg.lower())


if __name__ == "__main__":
    unittest.main()
