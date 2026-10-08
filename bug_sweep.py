import os
import re

def check_gdscript_files():
    script_dir = "Scripts"
    issues = []
    
    for f_name in os.listdir(script_dir):
        if not f_name.endswith(".gd"):
            continue
            
        filepath = os.path.join(script_dir, f_name)
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines):
            line_strip = line.strip()
            
            # Check for old connect syntax
            if re.search(r'\.connect\s*\(\s*["\']', line):
                issues.append(f"{f_name}:{i+1} Old Godot 3 connect syntax used.")
                
            # Check for get_node_or_null without a check afterwards
            # This is hard to do line by line, but we can flag variables initialized with get_node_or_null
            if "get_node_or_null" in line and not line_strip.startswith("#"):
                # We'll just skip this, it requires AST parsing.
                pass
                
            # Check for trailing operators like "=" or "+" at end of line without continuation
            if re.search(r'=\s*$', line_strip) and not line_strip.endswith("\\"):
                issues.append(f"{f_name}:{i+1} Trailing '=' assignment without value.")
                
            # Missing pass in empty block
            if line_strip.endswith(":") and "func " in line_strip:
                # check if next line is empty or unindented
                if i + 1 < len(lines):
                    next_line = lines[i+1].strip()
                    if next_line == "" or not lines[i+1].startswith("\t") and not lines[i+1].startswith(" "):
                        # Function with no body
                        issues.append(f"{f_name}:{i+1} Empty function block without pass.")

            # Check for self.get/set instead of direct access when not needed, although harmless
            
            # Common bug: Queue free instead of queue_free()
            if "queue free" in line or "queue_free " in line_strip:
                if "queue_free()" not in line:
                    issues.append(f"{f_name}:{i+1} Possible malformed queue_free.")

            # Check for old export syntax
            if line_strip.startswith("export "):
                issues.append(f"{f_name}:{i+1} Godot 3 export syntax.")
                
            # Check for old onready syntax
            if line_strip.startswith("onready "):
                issues.append(f"{f_name}:{i+1} Godot 3 onready syntax.")
                
    if not issues:
        print("No obvious syntax or legacy issues found.")
    else:
        for issue in issues:
            print(issue)

if __name__ == "__main__":
    check_gdscript_files()
