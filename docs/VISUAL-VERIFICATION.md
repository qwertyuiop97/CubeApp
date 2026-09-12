# Playback layout checks

These images were exported with SwiftUI `ImageRenderer` at 2× scale. They show the algorithm detail view, not the live floating window's blur or window chrome.

| View | Image size |
| --- | --- |
| [Compact, light](images/playback-compact-light.png) | 480 × 1076 px |
| [Compact, dark](images/playback-compact-dark.png) | 480 × 1076 px |
| [Large, light](images/playback-large-light.png) | 880 × 1228 px |
| [Invalid algorithm](images/playback-error-compact-light.png) | 552 × 166 px |

The compact renders use the actual 240pt window width. Notation and alternatives wrap without visible clipping; long alternatives make the view taller. Play, step, and reset share a control group, with separate progress and speed rows. The primary algorithm appears once, with its copy control below.

Invalid input displays the error and source notation without a cube or playback controls. The error render uses 260pt content width plus padding, so it is not a compact-width check.

## Reproduce

```sh
CUBEAPP_RENDER_DIR=/tmp/cubenotch-renders \
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
swift test -Xswiftc -warnings-as-errors --filter PlaybackRenderingTests
```

The render harness disables scrolling because `ImageRenderer` produced blank output for that ScrollView configuration. Production still scrolls.

## What these checks don't cover

- Live NSPanel materials, mouse handling, and keyboard focus.
- System Reduce Motion or Reduce Transparency settings. The motion decision has unit coverage, but those system settings were not changed for screenshots.
- Smooth turns between moves. Playback currently changes cube state at move boundaries.
