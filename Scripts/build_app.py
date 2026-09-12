"""Package the Swift executable and canonical artwork for local macOS use.

Signs with an Apple Development identity when one is installed, so macOS keeps
granted permissions across rebuilds; falls back to ad-hoc otherwise. Neither is
a notarized distribution signature.
"""
import json
import os
import pathlib
import plistlib
import shutil
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


def signing_identity():
    """Prefer a real signing identity over ad-hoc.

    macOS ties Accessibility permission to the app's code identity. An ad-hoc
    signature is identified by a content hash that changes on every rebuild, so
    the permission has to be granted again each time. A certificate-based
    identity keeps the permission across rebuilds.
    """
    override = os.environ.get("CUBENOTCH_SIGN_IDENTITY")
    if override:
        return override
    found = subprocess.run(
        ["security", "find-identity", "-v", "-p", "codesigning"],
        capture_output=True, text=True, check=True
    ).stdout
    for line in found.splitlines():
        if "Apple Development" in line and '"' in line:
            return line.split('"')[1]
    return "-"


def main():
    binary_dir = pathlib.Path(subprocess.check_output(
        ["swift", "build", "--show-bin-path"], cwd=ROOT, text=True
    ).strip())
    output = ROOT / "build"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="app-", dir=output) as temporary:
        staging = pathlib.Path(temporary)
        bundle = staging / "CubeNotch.app"
        contents = bundle / "Contents"
        resources = contents / "Resources"
        resources.mkdir(parents=True)
        (contents / "MacOS").mkdir()
        shutil.copy2(binary_dir / "CubeNotch", contents / "MacOS" / "CubeNotch")
        # iconutil expects an .iconset, not an Xcode .appiconset. Derive it from
        # the canonical manifest rather than maintaining a second image tree.
        artwork = ROOT / "Resources/Assets.xcassets/AppIcon.appiconset"
        iconset = staging / "AppIcon.iconset"
        iconset.mkdir()
        for image in json.loads((artwork / "Contents.json").read_text())["images"]:
            suffix = "@2x" if image["scale"] == "2x" else ""
            shutil.copy2(artwork / image["filename"],
                         iconset / f"icon_{image['size']}{suffix}.png")
        subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o",
                        str(resources / "AppIcon.icns")], check=True)
        info = {
            "CFBundleIdentifier": "com.cubenotch.CubeNotch",
            "CFBundleName": "CubeNotch",
            "CFBundleDisplayName": "CubeNotch",
            "CFBundleExecutable": "CubeNotch",
            "CFBundlePackageType": "APPL",
            "CFBundleIconFile": "AppIcon.icns",
            "CFBundleShortVersionString": "0.1.0",
            "CFBundleVersion": "1",
            "LSMinimumSystemVersion": "14.0",
            "LSUIElement": True,
            "NSHighResolutionCapable": True,
        }
        (contents / "Info.plist").write_bytes(plistlib.dumps(info))
        identity = signing_identity()
        subprocess.run(["codesign", "--force", "--sign", identity, str(bundle)], check=True)
        print(f"Signed with: {identity}")
        subprocess.run(["codesign", "--verify", "--strict", str(bundle)], check=True)
        destination = output / "CubeNotch.app"
        if destination.exists():
            shutil.rmtree(destination)  # Replace only this generated build artifact.
        shutil.move(str(bundle), destination)
    print(destination)


if __name__ == "__main__":
    main()
