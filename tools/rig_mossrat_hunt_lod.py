"""Build the approved 2,951-triangle hunt-only variant with the shared S1 rig."""
from pathlib import Path
import json
import rig_user_mossrat as rig
from mossrat_rig_common import ROOT

if __name__ == '__main__':
    rig.ASSETS = ROOT / 'assets/models/MossratS1HuntRig'
    rig.SOURCE = rig.ASSETS / 'Source.glb'
    rig.build()
    path = rig.ASSETS / 'metadata.json'
    data = json.loads(path.read_text())
    assert data['riggedTriangles'] == 2951
    data.update(usage='Hunting grounds only; lobby and cafe retain the detailed model',
                rigReviewApproved=False, sharedRig='MossratS1UserRig:34 bones',
                texturesOptimized=False)
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
