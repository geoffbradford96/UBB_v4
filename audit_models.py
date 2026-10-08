import os
import re

def parse_tscn(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    meshes = re.findall(r'type="([A-Za-z]+Mesh)"', content)
    sub_meshes = re.findall(r'\[sub_resource type="([A-Za-z]+Mesh)"', content)
    all_meshes = set(meshes + sub_meshes)
    
    csgs = re.findall(r'type="(CSG[A-Za-z3D]+)"', content)
    all_meshes.update(csgs)
    
    # Let's extract the color or material if possible
    colors = re.findall(r'albedo_color = Color\((.*?)\)', content)
    
    return all_meshes, colors

def main():
    unit_dir = "Scenes/Units"
    print("--- UNIT MODELS AUDIT ---")
    for root, dirs, files in os.walk(unit_dir):
        for file in files:
            if file.endswith(".tscn"):
                path = os.path.join(root, file)
                meshes, colors = parse_tscn(path)
                m_str = ', '.join(meshes) if meshes else 'NO MESH FOUND'
                c_str = 'Colors: ' + '; '.join(colors) if colors else 'No Color'
                print(f"{file.ljust(30)} | {m_str.ljust(40)} | {c_str}")

if __name__ == "__main__":
    main()
