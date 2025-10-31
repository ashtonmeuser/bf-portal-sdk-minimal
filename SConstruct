import os
import shutil
import PyInstaller.__main__


def copy_dir(source, destination):
    src = env.Dir(source).abspath
    dst = os.path.join(env.Dir(destination).abspath, os.path.basename(src))
    shutil.copytree(src, dst, dirs_exist_ok=True)


def replace_in_file(file_path, replacements):
    with open(file_path, "r", encoding="utf-8") as f:
        data = f.read()

    for old, new in replacements:
        data = data.replace(old, new)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(data)

# Build binaries with PyInstaller
def build_binary(env, target, source):
    script_path = "PortalSDK/code/gdconverter/src/gdconverter/export_tscn.py"
    PyInstaller.__main__.run([
        script_path,
        "--onefile",
        "--distpath", "PortalSDK/GodotProject/gdconverter",
        "--specpath", "build"
    ])


# Bundle all requirements under Godot project
def bundle_project(env, target, source):
    # Bundle FbExportData into Godot project
    copy_dir("PortalSDK/FbExportData", "PortalSDK/GodotProject")

    # Rewrite config file
    config_path = os.path.abspath("PortalSDK/GodotProject/addons/bf_portal/bf_portal.config.json")
    replace_in_file(config_path, [
        ("../FbExportData", "./FbExportData"),
        ("../export/levels", "./export")
    ])

    # Godot ignore assets and binaries
    open("PortalSDK/GodotProject/FbExportData/.gdignore", "w").close()
    open("PortalSDK/GodotProject/gdconverter/.gdignore", "w").close()


# Register SCons actions
env = Environment()
env.AlwaysBuild(env.Command("build", None, build_binary))
env.AlwaysBuild(env.Command("bundle", None, bundle_project))
Default("bundle")
