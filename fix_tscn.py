import re

with open('d:/Game Dev/UBB_v2/Scenes/Arena.tscn', 'r') as f:
    lines = f.readlines()

header = []
ext_resources = []
sub_resources = []
nodes = []

current_block = header
current_sub_resource = []
current_node = []

for line in lines:
    if line.startswith('[ext_resource'):
        ext_resources.append(line)
    elif line.startswith('[sub_resource'):
        if current_sub_resource:
            sub_resources.append(''.join(current_sub_resource))
        current_sub_resource = [line]
        current_block = current_sub_resource
    elif line.startswith('[node'):
        if current_sub_resource:
            sub_resources.append(''.join(current_sub_resource))
            current_sub_resource = []
        if current_node:
            nodes.append(''.join(current_node))
        current_node = [line]
        current_block = current_node
    elif line.startswith('[gd_scene'):
        header.append(line)
    else:
        current_block.append(line)

if current_sub_resource:
    sub_resources.append(''.join(current_sub_resource))
if current_node:
    nodes.append(''.join(current_node))

with open('d:/Game Dev/UBB_v2/Scenes/Arena.tscn', 'w') as f:
    f.writelines(header)
    f.writelines(ext_resources)
    f.writelines(sub_resources)
    f.writelines(nodes)

print('Done')
