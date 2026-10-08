import os
import glob

missing = []
for file in glob.glob('d:/Game Dev/UBB_v2/Scenes/Units/*.tscn'):
    with open(file, 'r') as f:
        text = f.read()
    if 'NavigationAgent3D' not in text:
        missing.append(os.path.basename(file))
        
print("Missing NavigationAgent3D:", missing)
