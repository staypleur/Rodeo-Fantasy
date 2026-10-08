"""Patch nameplate scripts without rebuilding or removing Studio-imported assets."""
from pathlib import Path
import argparse
import html
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "LevelPlaque": ROOT / "src/server/LevelPlaque.luau",
    "ProgressService": ROOT / "src/server/ProgressService.luau",
    "HuntIsolation": ROOT / "src/client/HuntIsolation.luau",
}


def patch(source: Path, output: Path):
    original = source.read_bytes()
    text = original.decode("utf-8")
    replacements = {name: path.read_text(encoding="utf-8") for name, path in SOURCES.items()}
    counts = {name: 0 for name in replacements}
    properties = re.compile(r'<Item\s+class="(?:ModuleScript|Script|LocalScript)"[^>]*>\s*<Properties>.*?</Properties>', re.S)

    def update(match):
        block = match.group(0)
        name = re.search(r'<string\s+name="Name">(.*?)</string>', block, re.S)
        if not name or html.unescape(name.group(1)) not in replacements:
            return block
        key = html.unescape(name.group(1))
        value = html.escape(replacements[key], quote=False)
        changed, count = re.subn(r'(<ProtectedString\s+name="Source">).*?(</ProtectedString>)', lambda m: m.group(1) + value + m.group(2), block, flags=re.S)
        if count != 1:
            raise ValueError(f"Expected one Source property for {key}, got {count}")
        counts[key] += 1
        return changed

    updated = properties.sub(update, text).encode("utf-8")
    if any(count != 1 for count in counts.values()):
        raise ValueError(f"Expected exactly one of each nameplate module: {counts}")
    before, after = ET.fromstring(original), ET.fromstring(updated)
    scripts = {}
    for node in after.iter("Item"):
        name = node.findtext("Properties/string[@name='Name']")
        if name in replacements and node.get("class") == "ModuleScript":
            scripts[name] = node.findtext("Properties/ProtectedString[@name='Source']")
    assert scripts == replacements, "Patched script sources do not match local files"
    # Only the selected Source text may change; every saved property and asset stays intact.
    for tree in (before, after):
        for node in tree.iter("Item"):
            if node.get("class") == "ModuleScript" and node.findtext("Properties/string[@name='Name']") in replacements:
                node.find("Properties/ProtectedString[@name='Source']").text = ""
    assert ET.tostring(before) == ET.tostring(after), "A saved asset or property changed during patching"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(updated)
    mesh_count = sum(n.get("class") == "MeshPart" for n in after.iter("Item"))
    print(f"PASS: patched {len(replacements)} nameplate modules; preserved all saved properties and {mesh_count} MeshParts")
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "dist/RodeoFantasy-Capture.rbxlx")
    parser.add_argument("--output", type=Path, default=ROOT / "dist/RodeoFantasy-NameplateV3.rbxlx")
    args = parser.parse_args()
    patch(args.source, args.output)
