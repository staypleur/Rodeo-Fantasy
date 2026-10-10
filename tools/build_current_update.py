"""Compatibility entry point for the approved orbital lobby update."""
from pathlib import Path
from build_orbital_lobby_installer import build as build_orbital
R=Path(__file__).resolve().parents[1]
def build():
 build_orbital()
 (R/'dist/UpdateCurrentProject.commandbar.lua').write_text((R/'dist/InstallOrbitalLobby.commandbar.lua').read_text(encoding='utf-8'),encoding='utf-8')
 print('CURRENT_PROJECT_UPDATE_BUILT: orbital lobby installer compatibility copy')
if __name__=='__main__':build()
