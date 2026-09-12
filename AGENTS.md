# Agent workflow

1. **Task source.** Read `NEXT.md` first. That file is the current work list. Update it when a task actually finishes.
2. **Existing first.** Use `Package.swift`, the Makefile, in-repo docs, and existing tests/scripts before adding custom tooling or duplicate instructions.
3. **One owner.** One agent owns each shared file in a cycle. Do not edit a file another owner is changing.
4. **One delivery.** Implement one bounded change, then `make build` and `make test`. Do not treat old checkboxes or other docs as proof.
5. **Protected data.** Do not modify `Sources/Core/Data/AlgorithmDatabase.swift` or `Sources/Core/Data/F2LDatabase.swift` unless a specific case is independently verified. Notation match, parser validity, and inverse/forward playback are not case identity.

Product commands and limits: `README.md`.
