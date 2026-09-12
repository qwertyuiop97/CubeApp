"""Package the Swift executable and canonical artwork for local macOS use.

The ad-hoc signature is for local development, not notarized distribution.
"""
import json
import pathlib
import plistlib
import shutil
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


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
        subprocess.run(["codesign", "--force", "--sign", "-", str(bundle)], check=True)
        subprocess.run(["codesign", "--verify", "--strict", str(bundle)], check=True)
        destination = output / "CubeNotch.app"
        if destination.exists():
            shutil.rmtree(destination)  # Replace only this generated build artifact.
        shutil.move(str(bundle), destination)
    print(destination)


if __name__ == "__main__":
    main()
