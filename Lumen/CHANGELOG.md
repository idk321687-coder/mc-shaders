# Changelog

## In progress
- Added an adjustable, larger sun disk and a warm corona; the reflected sun mask tracks
  its size. Reshaped the water into broad crossed swells and reduced high-frequency ripple
  detail with pixel footprint to limit distant striping while keeping waves animated.
- Reduced the painted-looking wave brightness modulation in top-down views. These changes
  have shader compiler coverage but have not been visually tested in Minecraft.
- Added animated, world-space surface shading for top-down water views and increased wave
  normal strength so motion is visible beyond reflections. Added a Wave Speed slider and
  increased the baseline reflection strength. In-game visual validation remains needed.
- Rebuilt water with animated multi-scale, domain-warped wave normals, stronger SSR and
  sky reflections, depth-scaled refraction, a continuous sun-specular lobe, and richer
  world-space shoreline foam and caustics. Added water-effects-off compilation coverage.
- Removed the direct reflected HDR sun disk that could repeat as blown-out blobs.
  These changes compile but have not been visually validated in Minecraft.
- Reworked water normals to avoid a repeating wave grid; softened reflections, sun glints,
  caustics, shoreline foam and refraction to reduce blown-out patches and streaks.
- Added Wave Strength and Reflection Strength sliders; water reflection rays now skip
  water pixels to reduce self-reflection artifacts. Visual testing in-game remains needed.
- Defined the RGBA16F GLSL constant in each program using it, fixing a deferred shader
  compilation error. Validation no longer injects this missing definition.
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
