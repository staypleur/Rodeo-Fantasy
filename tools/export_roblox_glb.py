"""Convert the approved A-family OBJ parts into Studio-importable GLB models."""
from __future__ import annotations

import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/meshes/meadow"
OUTPUT = ROOT / "dist/CreatureModels"
SPECIES = ("MeadowMouse", "GrassBoar", "TreeWolf", "RockElephant", "Weedcrow")
STAGES = (1, 3, 6, 9)


def read_mtl(path: Path) -> dict[str, tuple[float, float, float, float]]:
    materials = {}
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        bits = line.split()
        if not bits:
            continue
        if bits[0] == "newmtl":
            current = bits[1]
        elif bits[0] == "Kd" and current:
            materials[current] = (*map(float, bits[1:4]), 1.0)
    return materials


def normalize(vector):
    length = math.sqrt(sum(value * value for value in vector))
    if length < 1e-12:
        return (0.0, 1.0, 0.0)
    return tuple(value / length for value in vector)


def mesh_group(name, material):
    if name == "Body":
        return "Body"
    side = "Left" if name.startswith("Left") else "Right" if name.startswith("Right") else ""
    limb = "Front" if "Front" in name else "Back" if "Back" in name else ""
    for part in ("Leg", "Paw", "Claw", "HoofLine"):
        if side and limb and part in name:
            return side + limb + part
    if "Wing" in name:
        return (side or "Wing") + "Wing" if side else "Wing"
    if "Ear" in name:
        return (side or "") + "Ear"
    if "Tail" in name:
        return "Tail"
    color = "".join(f"{round(channel * 255):02X}" for channel in material[:3])
    return "Static_" + color


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def make_glb(obj_path: Path, output_path: Path):
    positions = []
    objects = []
    current = None
    smoothing = False
    for line in obj_path.read_text(encoding="utf-8").splitlines():
        bits = line.split()
        if not bits or bits[0].startswith("#"):
            continue
        if bits[0] == "v":
            positions.append(tuple(map(float, bits[1:4])))
        elif bits[0] in ("o", "g"):
            current = {"name": "_".join(bits[1:]) or f"Part{len(objects)+1}", "faces": [], "material": None, "smooth": False}
            objects.append(current)
        elif bits[0] == "usemtl" and current:
            current["material"] = bits[1]
        elif bits[0] == "s" and current:
            smoothing = bits[1].lower() not in ("off", "0")
            current["smooth"] = smoothing
        elif bits[0] == "f" and current:
            face = [int(token.split("/")[0]) - 1 for token in bits[1:]]
            for index in range(1, len(face) - 1):
                current["faces"].append((face[0], face[index], face[index + 1]))

    materials = read_mtl(obj_path.with_suffix(".mtl"))
    glb_bin = bytearray()
    buffer_views, accessors, gltf_meshes, gltf_nodes, gltf_materials = [], [], [], [], []
    material_ids = {}

    def add_material(name):
        if name in material_ids:
            return material_ids[name]
        index = len(gltf_materials)
        gltf_materials.append({"name": name, "pbrMetallicRoughness": {"baseColorFactor": list(materials.get(name, (0.7, 0.7, 0.7, 1.0))), "metallicFactor": 0.0, "roughnessFactor": 0.82}})
        material_ids[name] = index
        return index

    def append_data(data: bytes, target: int):
        while len(glb_bin) % 4:
            glb_bin.append(0)
        offset = len(glb_bin)
        glb_bin.extend(data)
        view = len(buffer_views)
        buffer_views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(data), "target": target})
        return view

    batches = {}
    used_node_names = set()
    for obj in objects:
        if not obj["faces"]:
            continue
        material = obj["material"]
        color = materials.get(material, (0.7, 0.7, 0.7, 1.0))
        group = mesh_group(obj["name"], color)
        color_name = "rgb_" + "".join(f"{round(channel * 255):02X}" for channel in color[:3])
        materials[color_name] = color
        batch_key = (group, color_name)
        batch = batches.get(batch_key)
        if batch is None:
            # Preserve material color in the name as a robust Studio fallback.
            # The importer can omit a glTF material's baseColorFactor on some presets.
            node_name = group + "__C" + color_name[4:]
            if node_name in used_node_names:
                raise ValueError(f"Duplicate GLB node name: {node_name} in {obj_path.name}")
            used_node_names.add(node_name)
            batch = {"name": node_name, "material": color_name, "verts": [], "normals": [], "indices": []}
            batches[batch_key] = batch
        verts = []
        normals = []
        indices = []
        if obj["smooth"]:
            used = sorted({vertex for face in obj["faces"] for vertex in face})
            remap = {old: new for new, old in enumerate(used)}
            verts = [positions[index] for index in used]
            accum = [[0.0, 0.0, 0.0] for _ in used]
            for face in obj["faces"]:
                a, b, c = (positions[index] for index in face)
                n = cross(tuple(b[i] - a[i] for i in range(3)), tuple(c[i] - a[i] for i in range(3)))
                for old in face:
                    slot = remap[old]
                    for axis in range(3):
                        accum[slot][axis] += n[axis]
                indices.extend(remap[index] for index in face)
            normals = [normalize(vector) for vector in accum]
        else:
            for face in obj["faces"]:
                tri = [positions[index] for index in face]
                a, b, c = tri
                n = normalize(cross(tuple(b[i] - a[i] for i in range(3)), tuple(c[i] - a[i] for i in range(3))))
                base = len(verts)
                verts.extend(tri)
                normals.extend((n, n, n))
                indices.extend((base, base + 1, base + 2))
        base = len(batch["verts"])
        batch["verts"].extend(verts)
        batch["normals"].extend(normals)
        batch["indices"].extend(base + index for index in indices)

    for batch in batches.values():
        verts, normals, indices = batch["verts"], batch["normals"], batch["indices"]
        if not verts or not indices:
            continue
        flat_positions = [value for vertex in verts for value in vertex]
        flat_normals = [value for normal in normals for value in normal]
        if len(verts) > 65535:
            index_data = struct.pack("<" + "I" * len(indices), *indices)
            index_component = 5125
        else:
            index_data = struct.pack("<" + "H" * len(indices), *indices)
            index_component = 5123
        pos_view = append_data(struct.pack("<" + "f" * len(flat_positions), *flat_positions), 34962)
        norm_view = append_data(struct.pack("<" + "f" * len(flat_normals), *flat_normals), 34962)
        idx_view = append_data(index_data, 34963)
        pos_min = [min(vertex[axis] for vertex in verts) for axis in range(3)]
        pos_max = [max(vertex[axis] for vertex in verts) for axis in range(3)]
        pos_accessor = len(accessors)
        accessors.append({"bufferView": pos_view, "componentType": 5126, "count": len(verts), "type": "VEC3", "min": pos_min, "max": pos_max})
        norm_accessor = len(accessors)
        accessors.append({"bufferView": norm_view, "componentType": 5126, "count": len(normals), "type": "VEC3"})
        idx_accessor = len(accessors)
        accessors.append({"bufferView": idx_view, "componentType": index_component, "count": len(indices), "type": "SCALAR"})
        mesh_index = len(gltf_meshes)
        gltf_meshes.append({"name": batch["name"], "primitives": [{"attributes": {"POSITION": pos_accessor, "NORMAL": norm_accessor}, "indices": idx_accessor, "material": add_material(batch["material"]), "mode": 4}]})
        gltf_nodes.append({"name": batch["name"], "mesh": mesh_index})

    gltf = {"asset": {"version": "2.0", "generator": "Rodeo Fantasy A-family model exporter"}, "scene": 0, "scenes": [{"nodes": list(range(len(gltf_nodes)))}], "nodes": gltf_nodes, "meshes": gltf_meshes, "materials": gltf_materials, "buffers": [{"byteLength": len(glb_bin)}], "bufferViews": buffer_views, "accessors": accessors}
    json_chunk = json.dumps(gltf, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_chunk += b" " * ((-len(json_chunk)) % 4)
    while len(glb_bin) % 4:
        glb_bin.append(0)
    total = 12 + 8 + len(json_chunk) + 8 + len(glb_bin)
    output_path.write_bytes(struct.pack("<4sII", b"glTF", 2, total) + struct.pack("<I4s", len(json_chunk), b"JSON") + json_chunk + struct.pack("<I4s", len(glb_bin), b"BIN\x00") + glb_bin)
    return len(gltf_nodes)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    total_parts = 0
    total_bytes = 0
    model_counts = []
    for species in SPECIES:
        for stars in STAGES:
            stem = f"{species}_A_S{stars}"
            count = make_glb(SOURCE / f"{stem}.obj", OUTPUT / f"{stem}.glb")
            total_parts += count
            model_counts.append(count)
            total_bytes += (OUTPUT / f"{stem}.glb").stat().st_size
    print(f"Exported 20 Roblox-importable A models: {total_parts} named mesh parts ({min(model_counts)}-{max(model_counts)} per model), {total_bytes:,} bytes")


if __name__ == "__main__":
    main()
