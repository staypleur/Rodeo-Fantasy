"""Verify the requested archival moves preserved every file byte."""
from pathlib import Path
import hashlib, json
ROOT=Path(__file__).resolve().parents[1]
records=json.loads((ROOT/'archive/legacy-monsters/2026-10-10/manifest.json').read_text(encoding='utf-8-sig'))
assert len(records)==54
for record in records:
    target=(ROOT/record['archive']).resolve()
    source=(ROOT/record['source']).resolve()
    assert target.is_relative_to(ROOT.resolve()) and source.is_relative_to(ROOT.resolve())
    assert not source.exists()
    assert hashlib.sha256(target.read_bytes()).hexdigest().upper()==record['sha256']
assert (ROOT/'assets/meshes/meshy/Mossrat_S1_Source.glb').exists()
assert (ROOT/'assets/meshes/meshy/LobbyAirship_Source.glb').exists()
print('LEGACY_MONSTER_ARCHIVE_PASS: 54 unchanged files archived; user originals and lobby airship preserved')
