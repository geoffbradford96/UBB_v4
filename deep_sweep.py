import os
import re

def analyze_scripts():
    script_dir = "Scripts"
    errors = []
    
    for f in os.listdir(script_dir):
        if not f.endswith(".gd"): continue
        path = os.path.join(script_dir, f)
        with open(path, 'r', encoding='utf-8') as file:
            content = file.read()
            
        lines = content.split('\n')
        
        for i, line in enumerate(lines):
            line_num = i + 1
            l_strip = line.strip()
            
            # Check for old connect syntax
            if ".connect(" in l_strip and not "Callable" in l_strip and not l_strip.startswith("#"):
                errors.append(f"{f}:{line_num} -> Old connect syntax: {l_strip}")
                
            # Check for position instead of global_position when interacting across nodes
            if ".position.distance_to" in l_strip and not l_strip.startswith("#"):
                errors.append(f"{f}:{line_num} -> Using local position for distance: {l_strip}")
                 
    return errors

def analyze_scenes():
    scene_dir = "Scenes"
    errors = []
    
    for root, dirs, files in os.walk(scene_dir):
        for f in files:
            if not f.endswith(".tscn"): continue
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
                
            # Check for missing scripts
            scripts = re.findall(r'ext_resource type="Script" path="res://Scripts/(.*?)"', content)
            for s in scripts:
                if not os.path.exists(os.path.join("Scripts", s)):
                    errors.append(f"{path} -> Missing script: {s}")
                    
            # For Units, check if HealthComponent is present
            if "Units\\" in path or f in ["Tower.tscn", "CommandBay.tscn"]:
                if 'path="res://Scripts/HealthComponent.gd"' not in content:
                    errors.append(f"{path} -> Missing HealthComponent!")
                    
    return errors

def main():
    print("--- DEEP SWEEP ---")
    script_errs = analyze_scripts()
    for e in script_errs: print(e)
    
    scene_errs = analyze_scenes()
    for e in scene_errs: print(e)
    
    if not script_errs and not scene_errs:
        print("No obvious structural bugs found!")

if __name__ == "__main__":
    main()
