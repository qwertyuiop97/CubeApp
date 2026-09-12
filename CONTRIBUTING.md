# Contributing

Build with Xcode 26 and Python 3 on macOS:

```sh
make build
make test
```

Keep changes small enough to review. Include a regression test with a bug fix, and explain any change in behavior. For UI changes, include a screenshot or native render at the affected window size. Don't change unrelated code just to match a formatting preference.

## Project layout

- `Sources/App/`: application lifecycle and windows.
- `Sources/Core/`: cube data, move engine, preferences, and shared services.
- `Sources/Features/`: timer, trainer, library, diagrams, and settings.
- `Sources/UI/`: the main overlay, dismissal routing, and shared views.
- `Tests/CubeNotchTests/`: Swift tests.
- `Scripts/`: icon generation and source-comparison tools.
- `Resources/`: canonical app artwork; `make app` builds the icon into the macOS bundle.
- `docs/`: technical notes and saved UI renders.

`NEXT.md` is the current task list. Agent-specific instructions are in `AGENTS.md`.

## Algorithm changes

Don't replace an algorithm just because another website uses a different sequence or case number. Show the starting case and verify what the proposed algorithm solves. Include the source URL and explain orientation or numbering differences. Keep corrections separate from presentation changes.

## UI checks

To export the playback test renders:

```sh
CUBEAPP_RENDER_DIR=/tmp/cubenotch-renders \
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
swift test -Xswiftc -warnings-as-errors --filter PlaybackRenderingTests
```

These renders check layout, not window focus or global keyboard input. Test those interactions in the running app when changing them.

## Before opening a pull request

Run the build and tests, check `git diff --check`, and inspect the files you are committing. Don't include local settings, credentials, logs, reference downloads, or build output. Report security issues privately as described in [SECURITY.md](SECURITY.md).
