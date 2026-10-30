# Changelog

## In progress
- Moved the water mask from colortex1 (which clears white) to colortex7 (which clears
  transparent black), preventing unmarked pixels from being mistaken for water.
- Added opt-in terrain labPBR normal/smoothness/reflectance/AO sampling, procedural wet
  highlights, an AgX-style tone curve and experimental instantaneous auto exposure.
- Compiled default, LOW and experimental variants with glslang. Minecraft testing remains
  necessary, especially for optional material textures and buffer behavior.
- Added an opaque-scene snapshot for depth-rejected refraction, a five-level bloom pyramid,
  variable-radius shadow filtering, SSR hit refinement, procedural cloud shadows and wet
  surface darkening; attenuated caustics and glints with the shadow map.
- Compiled and linked shader programs with glslang in default and LOW feature variants.
  In-game validation and the remaining features listed in the README are still pending.
- Added approximate water caustic patterns, procedural Nether and End skies, moon shafts,
  haze, ambient occlusion, expanded foliage wind and fitted filmic color controls.

## Prototype
- Added procedural overworld sky, approximate moon phases, stars and foliage wind.
- Added screen-space water reflections, depth-based water color and foam, underwater fog,
  terrain shadows, shadow-map-marched sunlight shafts and basic quality profiles.
