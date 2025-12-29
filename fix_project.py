import sys

path = 'iMessageWrapped.xcodeproj/project.pbxproj'

with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
in_native_target = False
in_frameworks_phase = False
frameworks_phase_id = 'A1000020282A0001'
native_target_id = 'A1000040282A0001'

# IDs
mlx_pkg_id = '96B796092F00EDE300F7DF93'
mlx_lm_pkg_id = '96B7960A2F00EFF500F7DF93'

mlx_dep_id = '96B7960B2F00F00100F7DF93'
mlx_llm_dep_id = '96B7960C2F00F00200F7DF93'
mlx_common_dep_id = '96B7960F2F00F00500F7DF93'

mlx_build_id = '96B7960D2F00F00300F7DF93'
mlx_llm_build_id = '96B7960E2F00F00400F7DF93'
mlx_common_build_id = '96B796102F00F00600F7DF93'

# Check if already patched to avoid duplication
content = "".join(lines)
if mlx_dep_id in content:
    print("Project already patched.")
    sys.exit(0)

for line in lines:
    new_lines.append(line)
    
    # Insert Build Files
    if '/* Begin PBXBuildFile section */' in line:
        new_lines.append(f'\t\t{mlx_build_id} /* MLX in Frameworks */ = {{isa = PBXBuildFile; productRef = {mlx_dep_id} /* MLX */; }};\n')
        new_lines.append(f'\t\t{mlx_llm_build_id} /* MLXLLM in Frameworks */ = {{isa = PBXBuildFile; productRef = {mlx_llm_dep_id} /* MLXLLM */; }};\n')
        new_lines.append(f'\t\t{mlx_common_build_id} /* MLXLMCommon in Frameworks */ = {{isa = PBXBuildFile; productRef = {mlx_common_dep_id} /* MLXLMCommon */; }};\n')

    # Insert Frameworks Phase Files
    if f'{frameworks_phase_id} /* Frameworks */ = {{' in line:
        in_frameworks_phase = True
    
    if in_frameworks_phase and 'files = (' in line:
        new_lines.append(f'\t\t\t\t{mlx_build_id} /* MLX in Frameworks */,\n')
        new_lines.append(f'\t\t\t\t{mlx_llm_build_id} /* MLXLLM in Frameworks */,\n')
        new_lines.append(f'\t\t\t\t{mlx_common_build_id} /* MLXLMCommon in Frameworks */,\n')
        in_frameworks_phase = False

    # Insert Native Target Dependencies
    if f'{native_target_id} /* iMessageWrapped */ = {{' in line:
        in_native_target = True
    
    if in_native_target and 'productType = ' in line:
        # Add package dependencies before closing brace of target
        new_lines.append('\t\t\tpackageProductDependencies = (\n')
        new_lines.append(f'\t\t\t\t{mlx_dep_id} /* MLX */,\n')
        new_lines.append(f'\t\t\t\t{mlx_llm_dep_id} /* MLXLLM */,\n')
        new_lines.append(f'\t\t\t\t{mlx_common_dep_id} /* MLXLMCommon */,\n')
        new_lines.append('\t\t\t);\n')
        in_native_target = False

# Append Package Product Dependencies Section at end (before main closing brace usually, but we can put it before Project section)
# Searching for a place to put it. simpler to put it before Project section
final_lines = []
inserted_deps = False
for line in new_lines:
    if '/* Begin PBXProject section */' in line and not inserted_deps:
        final_lines.append('/* Begin XCSwiftPackageProductDependency section */\n')
        final_lines.append(f'\t\t{mlx_dep_id} /* MLX */ = {{\n')
        final_lines.append('\t\t\tisa = XCSwiftPackageProductDependency;\n')
        final_lines.append(f'\t\t\tpackage = {mlx_pkg_id} /* XCRemoteSwiftPackageReference "mlx-swift" */;\n')
        final_lines.append('\t\t\tproductName = MLX;\n')
        final_lines.append('\t\t};\n')
        final_lines.append(f'\t\t{mlx_llm_dep_id} /* MLXLLM */ = {{\n')
        final_lines.append('\t\t\tisa = XCSwiftPackageProductDependency;\n')
        final_lines.append(f'\t\t\tpackage = {mlx_lm_pkg_id} /* XCRemoteSwiftPackageReference "mlx-swift-lm" */;\n')
        final_lines.append('\t\t\tproductName = MLXLLM;\n')
        final_lines.append('\t\t};\n')
        final_lines.append(f'\t\t{mlx_common_dep_id} /* MLXLMCommon */ = {{\n')
        final_lines.append('\t\t\tisa = XCSwiftPackageProductDependency;\n')
        final_lines.append(f'\t\t\tpackage = {mlx_lm_pkg_id} /* XCRemoteSwiftPackageReference "mlx-swift-lm" */;\n')
        final_lines.append('\t\t\tproductName = MLXLMCommon;\n')
        final_lines.append('\t\t};\n')
        final_lines.append('/* End XCSwiftPackageProductDependency section */\n\n')
        inserted_deps = True
    final_lines.append(line)

with open(path, 'w') as f:
    f.writelines(final_lines)

print("Project patched successfully.")
