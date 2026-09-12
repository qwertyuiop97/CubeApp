"""Check the local macOS bundle produced by `make app`."""
import pathlib
import plistlib
import subprocess
import sys


def verify(bundle):
    contents = bundle / "Contents"
    with (contents / "Info.plist").open("rb") as source:
        info = plistlib.load(source)
    assert info["CFBundleIdentifier"] == "com.cubenotch.CubeNotch"
    assert info["CFBundlePackageType"] == "APPL"
    assert info["LSUIElement"] is True
    assert info["LSMinimumSystemVersion"] == "14.0"
    executable = contents / "MacOS" / info["CFBundleExecutable"]
    assert executable.is_file() and executable.stat().st_mode & 0o111
    icon = contents / "Resources" / info["CFBundleIconFile"]
    assert icon.read_bytes()[:4] == b"icns"
    subprocess.run(["codesign", "--verify", "--strict", str(bundle)], check=True)
    print(f"Verified executable, bundle metadata, app icon, and local signature: {bundle}")


if __name__ == "__main__":
    verify(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/CubeNotch.app"))
