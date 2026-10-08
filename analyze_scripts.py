import os
import re

def analyze_file(filepath):
    errors = []
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        line_num = i + 1
        # Check for undeclared variables used in math/assignment
        if re.search(r'(?<!var )([a-zA-Z_]\w*)\s*[+\-*/]?=', line) and not line.strip().startswith("#"):
            # This is too noisy, let's skip undeclared variable checking statically in python, hard to do accurately
            pass
            
        # Check for bad node paths
        if "$" in line and not line.strip().startswith("#"):
            if "$NavigationAgent3D" in line:
                errors.append(f"Line {line_num}: Still has $NavigationAgent3D!")
                
        # Check for missing colons in control flow
        if re.match(r'^\s*(if|elif|else|for|while|func)\b.*[^\:]\s*$', line) and not line.strip().startswith("#"):
            # Some lines might wrap, but let's check basic
            if not line.strip().endswith(":") and not "\\" in line:
                errors.append(f"Line {line_num}: Missing colon in control flow: {line.strip()}")
                
    return errors

def main():
    print("--- STATIC SCRIPT ANALYSIS ---")
    script_dir = "Scripts"
    for f in os.listdir(script_dir):
        if f.endswith(".gd"):
            errs = analyze_file(os.path.join(script_dir, f))
            if errs:
                print(f"File: {f}")
                for e in errs:
                    print("  " + e)

if __name__ == "__main__":
    main()
