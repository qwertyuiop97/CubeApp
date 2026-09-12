# Known limitations

The current task queue lives in [NEXT.md](NEXT.md). This file records product limitations, not a second development plan.

- **Algorithm case mapping:** The [source comparison](docs/ALGORITHM-VERIFICATION.md) checks notation candidates. It does not prove every algorithm belongs to its displayed canonical case; F2L numbering differs between references. Match actual cube cases before changing protected data. Missing string matches are not proof of incorrect algorithms.
- **Interactive verification:** Native light/dark renders and offscreen focus tests pass. Foreground shortcut recording, physical shortcut presses, and the live overlay's material capture still need interactive smoke coverage. See [visual evidence](docs/VISUAL-VERIFICATION.md) and [focus coverage](docs/HOTKEY-FOCUS-VERIFICATION.md).
- **Playback scope:** Moves advance discretely. Smooth intra-move animation and a 3D F2L slot view are not implemented.
- **Distribution:** Source builds are tested. No signed/notarized release package is promised.

Resolved parser, diagram, search/history, hotkey, and screenshot regressions are covered by the test suite. Run `make build && make test` for current results.
