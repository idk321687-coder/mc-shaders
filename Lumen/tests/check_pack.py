"""Basic pack structural checks, not a GLSL compiler or renderer."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1] / "shaders"
files = [p for p in root.rglob("*") if p.is_file()]
for path in files:
    source = path.read_text(encoding="utf-8")
    for include in re.findall(r'^\s*#include\s+"/([^\"]+)"', source, re.M):
        assert (root / include).is_file(), f"{path}: missing include {include}"
    if path.suffix in (".vsh", ".fsh"):
        assert source.startswith("#version "), f"{path}: missing version"
for path in root.rglob("*.vsh"):
    assert path.with_suffix(".fsh").exists(), f"{path}: missing fragment stage"
for path in root.rglob("*.fsh"):
    assert path.with_suffix(".vsh").exists(), f"{path}: missing vertex stage"
print(f"Checked {len(files)} pack files; includes and program pairs are present.")

# Expand includes and preprocess entry points to catch malformed conditional directives.
# cpp is not GLSL-aware, so #version is removed; this is still not shader compilation.
import shutil
import subprocess

def expand(path, stack=()):
    assert path not in stack, f"include cycle: {path}"
    source = path.read_text(encoding="utf-8")
    def replace(match):
        return expand(root / match.group(1), stack + (path,))
    return re.sub(r'^\s*#include\s+"/([^\"]+)"\s*$', replace, source, flags=re.M)

cpp = shutil.which("cpp")
if cpp:
    for path in files:
        if path.suffix not in (".vsh", ".fsh"):
            continue
        source = re.sub(r'^#version[^\n]*', '', expand(path), flags=re.M)
        result = subprocess.run([cpp, '-P', '-'], input=source, text=True, capture_output=True)
        assert result.returncode == 0, f"{path}: {result.stderr}"
        code = re.sub(r'/\*.*?\*/|//[^\n]*', '', result.stdout, flags=re.S)
        assert code.count('{') == code.count('}'), f"{path}: unmatched braces"
    print("Preprocessor and brace checks passed for all shader entry points.")
else:
    print("cpp unavailable; conditional preprocessing checks skipped.")

# Optional real GLSL compilation/linking. The loader injects the format token; define
# it here solely for standalone validation. Set GLSLANG_VALIDATOR to its executable.
import os
import tempfile
validator = os.environ.get("GLSLANG_VALIDATOR") or shutil.which("glslangValidator") or shutil.which("glslang")
if validator:
    disabled_low = ("GOD_RAYS", "WATER_REFLECTIONS", "SHADOWS", "SSAO", "BLOOM")
    with tempfile.TemporaryDirectory(prefix="lumen-glsl-") as tmp:
        for vert in sorted(root.rglob("*.vsh")):
            frag = vert.with_suffix(".fsh")
            for profile in ("default", "low", "experimental"):
                stages = []
                for path, suffix in ((vert, ".vert"), (frag, ".frag")):
                    source = expand(path).replace("#version 120", "#version 120\n#define RGBA16F 34842", 1)
                    if profile == "low":
                        for option in disabled_low:
                            source = re.sub(rf'^#define {option}\s*$', f'// #define {option}', source, flags=re.M)
                    if profile == "experimental":
                        for option in ("LAB_PBR", "TONEMAP_AGX", "AUTO_EXPOSURE"):
                            source = re.sub(rf'^//#define {option}\s*$', f'#define {option}', source, flags=re.M)
                    dest = Path(tmp) / (path.stem + suffix)
                    dest.write_text(source, encoding="utf-8")
                    stages.append(str(dest))
                result = subprocess.run([validator, '-l', *stages], capture_output=True, text=True)
                assert result.returncode == 0, f"{vert} ({profile}):\n{result.stdout}\n{result.stderr}"
    print("GLSL compilation and linking passed for default, LOW and experimental feature variants.")
else:
    print("glslang unavailable; shader compilation and linking skipped.")
