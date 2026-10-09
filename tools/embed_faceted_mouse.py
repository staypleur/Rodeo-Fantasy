"""Compatibility entry point for the approved four-stage lineage embedder."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name("embed_mouse_lineage.py")))
