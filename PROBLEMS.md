# Known limitations

The current task queue lives in [NEXT.md](NEXT.md). This file records product limitations, not a second development plan.

- **Algorithm case mapping:** The [source comparison](docs/ALGORITHM-VERIFICATION.md) checks notation candidates. It does not prove every algorithm belongs to its displayed canonical case; F2L numbering differs between references. Match actual cube cases before changing protected data. Missing string matches are not proof of incorrect algorithms.
- **Interactive verification:** Native light/dark renders and offscreen focus tests pass. Foreground shortcut recording, physical shortcut presses, and the live overlay's material capture still need interactive smoke coverage. See [visual evidence](docs/VISUAL-VERIFICATION.md) and [focus coverage](docs/HOTKEY-FOCUS-VERIFICATION.md).
- **Playback scope:** Moves advance discretely. Smooth intra-move animation and a 3D F2L slot view are not implemented.
- **Older timer records:** Earlier builds could store a manually applied +2 in both elapsed time and the penalty flag. New edits keep these separate; existing records are not rewritten because manual and inspection penalties cannot be distinguished reliably.
- **Practice scrambles:** Scrambles use random moves, not the official WCA random-state generator.
- **Distribution:** Source builds are tested. No signed/notarized release package is promised.

Resolved parser, diagram, search/history, hotkey, and screenshot regressions are covered by the test suite. Run `make build && make test` for current results.
