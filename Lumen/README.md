# Lumen — experimental Minecraft shader pack

Lumen is an experimental shader pack for Minecraft Java. It is **not yet the complete,
production-tested pack** in `../SHADER_PROMPT.md`.

## Install

1. Install Minecraft Java and Iris or OptiFine.
2. Copy the `Lumen` folder into `.minecraft/shaderpacks/`, or zip the folder's
   contents so `shaders/` is at the root of the zip.
3. Select Lumen in Video Settings → Shaders. Shader options include LOW, MEDIUM,
   HIGH and ULTRA profiles plus atmosphere, water, wind and color controls.

## Implemented so far

- Procedural overworld sky, sun disk, moon disk with approximate eight-phase shading,
  stars, horizon colors, and rain desaturation. Simple procedural Nether and End skies.
- World-space vertex wind for common plants, leaves, hanging vines and aquatic plants,
  shared with the shadow pass.
- Water normal animation, screen-space ray-marched reflections with sky fallback, an
  approximate depth-rejected screen-space refraction using an opaque-scene snapshot, depth-based tint, shoreline foam, caustic pattern,
  sun glints, and underwater fog.
- Variable-radius shadow-map filtered terrain shadows, shadow-map-marched sun and moon shafts, screen-space
  ambient occlusion, distance haze, procedural cloud shadows and rain-darkened surfaces.
- Procedural wet highlights/puddle patches and opt-in terrain normal, ambient-occlusion,
  smoothness and reflectance maps using a subset of labPBR.
- Five-level downsampled bloom, fitted ACES-style and opt-in AgX-style tone curves,
  dither, vignette, exposure and saturation. Optional instant auto exposure is experimental.

Screen-space reflections are **not hardware ray tracing**: off-screen and hidden objects
cannot be reflected. Refraction samples a pre-water opaque snapshot. Caustics use a shadow-attenuated pattern
over pixels looking through water, not projected lighting on all geometry. SSAO, foam and shafts are approximations, not temporally stabilized.
Shadows do not yet extend to all passes.

## Status and limitations

The shader entry points were compiled and linked with glslang for default, LOW and experimental feature
variants, after expanding loader includes and defining its RGBA16F format token. The pack
has not been run in Minecraft: loader compatibility, buffer blending, performance and
appearance must all be verified in-game. The implementation uses GLSL 120 compatibility built-ins rather than
the prompt's GLSL 330 core target. Compatibility with specific Iris, OptiFine or Minecraft
versions is not yet established. Run `python3 Lumen/tests/check_pack.py` for file, include
and preprocessor checks. Set `GLSLANG_VALIDATOR` to a glslang executable to additionally
compile and link shader entry points; neither check substitutes for an in-game test.

Still missing from the original specification: robust refraction and physically projected caustics, full PCSS, temporal accumulation/TAA,
temporally smoothed eye adaptation, full labPBR material support, reflective puddles,
Distant Horizons integration, and a
verified performance budget. Wind and lighting do not cover every requested material or
rendering pass. LabPBR is opt-in and only covers terrain: enable it only with compatible
normal/specular maps; conductor colors, subsurface scattering and parallax are not implemented.
The puddle effect is a procedural darkening and highlight, not a reflected scene.
The experimental auto exposure responds instantly, without temporal smoothing. The opaque
snapshot uses colortex8; some hardware or loaders limited to eight color attachments may
not support the pack. Phase orientation, sky compositing, underwater behavior and shadow mapping
need in-game validation; some effects may need corrections after that testing.

Suggested test scenes: forest with moving leaves and grass; a river reflecting nearby
terrain; looking towards and away from the sun; rainy weather; underwater; the Nether and
End; and transparent glass next to water. Check the shader log for compilation errors.
