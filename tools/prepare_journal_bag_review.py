"""Prepare separate bug-fix and unapproved design-review places without rebuilding assets."""
from pathlib import Path
import xml.etree.ElementTree as E
import patch_nameplate_place as P
from place_identity import assert_unique_ids

R=Path(__file__).resolve().parents[1]
fix={'FacetedMouse':'src/client/FacetedMouse.luau','HerdVisibility':'src/shared/HerdVisibility.luau','HuntWorld':'src/server/HuntWorld.luau'}
fix.update({'MonsterCatalog':'src/shared/MonsterCatalog.luau','Localization':'src/shared/Localization.luau'})
review={
 'JournalUI':'src/client/JournalUI.luau','BagUI':'src/client/BagUI.luau',
 'AudioPresentation':'src/client/AudioPresentation.luau','Config':'src/shared/Config.luau',
 'Localization':'src/shared/Localization.luau','ProgressRules':'src/shared/ProgressRules.luau',
 'ProgressService':'src/server/ProgressService.luau','BagRules':'src/shared/BagRules.luau',
 'CaptureServer':'src/server/CaptureServer.server.luau',
}
def patch(source,output,files):
 P.SOURCES={n:R/f for n,f in files.items()}
 P.patch(R/'dist'/source,R/'dist'/output)
 assert_unique_ids(E.parse(R/'dist'/output).getroot())
if __name__=='__main__':
 patch('RodeoFantasy-LobbyFinishedLayout.rbxlx','RodeoFantasy-HuntTextureFix.rbxlx',fix)
 patch('RodeoFantasy-HuntTextureFix.rbxlx','RodeoFantasy-JournalBagReview.rbxlx',review)
