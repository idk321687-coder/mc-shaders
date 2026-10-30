# Minecraft Shader Pack — Build Prompt

A copy‑paste prompt for getting an AI coding agent (or a human dev) to build a
complete Iris/OptiFine shader pack with **water reflections + ray tracing, god rays,
wind‑animated foliage, and a custom sun/moon**.

- **Section 1** — the full prompt (copy everything inside the fence).
- **Section 2** — a short version if the agent has a small context budget.
- **Section 3** — follow‑up prompts for iterating (perf pass, bug hunt, polish).
- **Section 4** — a bonus prompt for a cinematic trailer render (image/video AI).

---

## 1. Full prompt

````text
ROLE
You are a senior real-time graphics engineer who ships Minecraft shader packs. You know the
Iris/OptiFine shader pipeline, its uniforms, its buffers, and its footguns (shadow acne,
TAA ghosting, chunk-seam foliage popping, NaN from zero-length normals). Write production
GLSL, not pseudocode.

GOAL
Build a complete, installable Minecraft shader pack — call it "Lumen" — that delivers the
look of a modern AAA natural-lighting render at Minecraft scale. Priorities, in order:
  1. Water you can believe: real reflections, refraction, absorption, caustics, foam.
  2. Volumetric god rays that react to clouds, foliage, and the sun's position.
  3. Foliage that moves like it's alive — layered wind, per-plant behavior, no seams.
  4. A custom sun and moon (phases, corona, stars, atmospheric sky) that replaces vanilla's.
  5. Clean color pipeline: physically plausible exposure, filmic tonemap, no banding.

TARGET
- Minecraft Java 1.20.1 and 1.21.x, Iris 1.7+ and OptiFine 1.20.1_HD_U_I6+.
- GLSL: every program starts with `#version 330 core`. No compute shaders, no geometry
  shaders, no `#extension` tricks that OptiFine rejects. 330 is the portable ceiling —
  stay under it unless you gate a feature behind `#ifdef IRIS_FEATURE_*` with a fallback.
- No external libraries, no downloaded assets, no codegen. Everything in-repo, human-readable.
- Must survive: vanilla textures, high-res packs, labPBR packs, Distant Horizons chunks,
  Sodium + Iris, and servers with 8-view-distance.

DELIVERABLES (exact layout — a user must be able to drop the folder into `.minecraft/shaderpacks/`)
  Lumen/
    shaders/
      shaders.properties
      dimension.properties
      block.properties          (wind + material ID tables)
      lang/en_us.lang
      lib/
        common.glsl             math, hash, noise, packing, saturation helpers
        settings.glsl           every tunable #define / uniform, one place
        sky.glsl                sun/moon/stars/scattering/atmosphere
        water.glsl              wave normals, absorption, caustics, foam, refraction math
        shadow.glsl             PCF/PCSS, distortion, bias, sampling wrappers
        volumetrics.glsl        ray-march kernels, phase functions, dithering
        tonemap.glsl            exposure, AgX/ACES, grading, dither
      program/
        gbuffers_basic.vsh/.fsh
        gbuffers_textured_lit, textured, terrain, terrain_solid, water,
        gbuffers_hand, handheld, entities, block, beacons, skybasic, skytextured,
        clouds, weather, shadow, shadow_solid   (+ any _fsh variants Iris asks for)
        deferred.fsh
        composite.fsh / composite1..composite4.fsh
        final.fsh
    + README.md with install steps, feature list, performance table, and credits.

FEATURE SPEC

A. WATER (the hero feature)
   1. Geometry: no vertex displacement of water — do the work in the fragment stage so
      it stays compatible with every resource pack. Opt out cleanly for flowing water and
      for water in the Nether/End.
   2. Normals: blend 2–3 scrolling procedural wave sets (sum of directional Gerstner-like
      sine waves plus fine hash noise) with per-biome scale and speed. Fade wave amplitude
      with distance and crush the normal toward the geometric normal when the surface is
      nearly edge-on (grazing angle) to kill shimmering.
   3. Ray-traced reflections: screen-space ray march against `depthtex0` in view space,
      using the previous frame's resolved color (`colortex` ping-pong) for the reflection
      source. 16–48 steps with binary-search refinement, one jittered ray per pixel rotated
      by a Bayer/blue-noise offset, then temporally accumulated with a neighborhood clamp
      (variance clipping) so it doesn't smear.
      - Miss = sample the sky function (A.7) with the reflected ray. No hard cutoff at the
        waterline: fade SSR to sky reflection over the last ~20% of the ray, plus a
        roughness-driven blur (2–4 taps along the reflected ray) so distant water looks
        soft, not mirror-sharp.
      - Reflections must be correct for: the sun disk, terrain, entities, held items, and
        the Nether's roof. Anything visible above the water must be reflected.
   4. Refraction: sample the opaque scene with a UV offset derived from the wave normal
      slope and a depth-scaled strength; reject samples that are in front of the water
      surface using `depthtex0` so nothing "floats" through. Screen-clamp the offset.
   5. Absorption/color: Beer–Lambert per-channel extinction along the view ray through
      water depth. Water color from biome (warm swamp green, cold ocean teal, swamp murk,
      river clarity) times a user tint slider. Underwater view gets a separate, denser fog
      with depth+normal-aware falloff and a caustic pattern on geometry below.
   6. Caustics: animated Voronoi/domain-warped pattern, projected along the sun direction
      onto submerged and near-shore geometry, attenuated by shadow-map visibility and by
      sun height. Must fade out at night and under overcast.
   7. Foam and shoreline: thin foam band from depth difference between water and the
      opaque surface, broken up by noise and by wave crest height; spray puffs where wave
      gradients are steepest. Optional rain rings (expanding, randomized per-cell) when
      `biome_precipitation` says it's raining.
   8. Fresnel: Schlick with F0 ≈ 0.02, plus a slight energy-conserving mix so reflections
      don't blow out to white at the horizon. Add a "sea sparkle" specular lobe from the
      sun that is sampled from the shadow map (so a mountain's shadow kills the glints).

B. GOD RAYS + VOLUMETRICS
   1. Primary method: ray-march `shadowtex1` in view space from the camera to the opaque
      depth, 24–40 steps, exponential step distribution (denser near camera), with
      blue-noise dithering on the start offset and temporal accumulation.
   2. Light shafts come from a Henyey–Greenstein phase function (g ≈ 0.6–0.75) around the
      sun direction, so rays bloom when you look toward the sun and fade when you look away.
      Support both sun and moon (moon shafts are cool-blue and much weaker).
   3. Occlusion must include: opaque geometry, foliage (so tree canopies cast broken shafts
      through leaves), clouds (sample a cheap 2D cloud-shadow term), and water surface for
      the underwater case (a separate, dimmer underwater shaft set).
   4. Fallback path (LOW preset): screen-space radial light shafts — 12 taps toward the sun's
      screen position, occlusion accumulated from a downsampled depth/color mip chain.
      Toggle automatically when the volumetric budget is exhausted.
   5. Also ship volumetric height fog (2–3 layers, exponential) with sun-direction in-scatter
      and a subtle forward-scatter halo. Export both as quality sliders.
   6. Bloom: threshold on HDR luminance, 5-level downsample chain, energy-normalized upsample.
      God rays must bleed into bloom, and the sun disk must trigger a lens-ish halo — not a
      full lens-flare funk, keep it tasteful (one ghost, one anamorphic streak, both optional).

C. WIND / MOVING FOLIAGE
   1. Vertex-stage sway on `gbuffers_terrain` (and `shadow`, so shadows match — otherwise
      foliage shadows detach from leaves, which is the #1 giveaway of a bad wind system).
   2. Displacement model: 2–3 world-space sine waves at different frequencies + slow
      low-frequency gust noise sampled from `noisetex`. Amplitude scales with:
        - vertex height above the block base (via `at_midBlock` / `mc_midTexCoord`), so the
          plant pivots at the ground and bends at the top;
        - a per-block hash so neighboring plants are out of phase;
        - distance from camera (subtle squash so distant foliage doesn't wobble aliased);
        - `frameTimeCounter` for stability, never `frameTime`.
   3. Per-material behavior via `block.properties` IDs: leaves flutter and shear, tall grass
      and crops sway with the gust direction, flowers bob with a slight twist, vines hang
      and swing, lily pads drift, kelp/seagrass waves with an underwater current, sugar cane
      flexes top-down. Water plants use the current direction, not the wind.
   4. Chunk seams: displacement must be a pure function of world position and time so a leaf
      on the edge of chunk A moves identically to its neighbor in chunk B. Verify at render
      distance boundaries and with Distant Horizons LODs.
   5. Never displace: solid blocks, glass, doors, redstone, anything with a stable ID, or
      snow layers. Never displace the player's view (no camera shake inside the vertex
      shader for the hand pass).
   6. Wind responds to weather: `rainStrength` raises amplitude and gust speed; thunder adds
      a slow pressure pulse. Wind direction slowly rotates over minutes (user-tunable).

D. CUSTOM SUN, MOON, SKY
   1. Replace vanilla sky entirely (kill `skybasic`/`skytextured` output; draw the sky in
      `composite` before geometry is composited, using the inverse view-projection to get the
      world-space view ray).
   2. Atmosphere: single-scattering Rayleigh + Mie approximation with a real sun direction,
      producing believable sunrise/sunset reddening, a blue zenith, horizon haze, and a
      subtle earth-shadow band at twilight. Must transition continuously through dawn/dusk
      and degrade gracefully when the sun is directly overhead.
   3. Sun: procedural disk with limb darkening, a granulation-ish noise, a bright core, a
      soft corona/halo driven by Mie in-scatter. Angular size ~0.53° plus a user slider.
      Bloom and god rays key off the disk's radiance, so it should be HDR (>> 1.0).
   4. Moon: a real phased moon (8 phases, correct waxing/waning orientation mirrored per
      hemisphere), procedural craters + maria, limb darkening, faint earthshine. Phase comes
      from the level's day/time so it lines up with vanilla's moon phase. Optional soft
      blue "moonlight" god rays and a night-time sky that is dark but not black.
   5. Stars: procedural, density- and magnitude-varied, twinkling with per-star phase,
      occluded by the sky's brightness and by the moon's disk. A faint Milky-Way-ish band is
      optional (default on, subtle). Optional aurora in cold biomes (default off, it's a
      separate slider — don't let it cost anything when disabled).
   6. Clouds: keep vanilla's volumetric-ish cloud rendering but light it — tint the cloud
      undersides with the sky gradient, add sun-forward silver lining, and let clouds cast
      soft moving shadows on the terrain (a 2D noise shadow term, no extra shadow map).
   7. Nether and End: replace the sky with bespoke gradients (Nether: smoky red/orange
      with drifting embers and a dim internal light source; End: deep violet void with a
      starfield and a subtle nebula). No sun/moon/atmosphere leaking into those dimensions.

E. SHADOWS AND AMBIENT
   1. Shadow map: OptiFine/Iris `shadowtex0` + `shadowtex1`, normal-offset bias, slope-scaled
      depth bias, and a distortion function that keeps texel density reasonable near the
      player. PCSS-style variable penumbra from a blocker search (8–16 taps) so shadows get
      softer with distance. Contact-hardening is what sells "real".
   2. Foliage shadows must be dithered/alpha-tested identically to the color pass, or you get
      leaf shadows that don't match leaf silhouettes.
   3. Ambient: hemisphere ambient from the sky function (sky color from above, bounce color
      from the ground), an AO term from a cheap SSAO (8–12 taps, half-res, bilateral
      upsample), and a screen-space contact shadow term. Ambient must react to the sun's
      color at sunset, and to weather (overcast = flatter, bluer, dimmer).
   4. Sun/moon light extraction: read the sky's own radiance for the directional light so
      terrain lighting and the sky never disagree in color temperature.

F. MATERIALS, SPECULAR, POST
   1. Optional labPBR support: if a resource pack ships `_n`/`_s` maps, use them for normals,
      roughness, F0, porosity (wetness darkening), and SSS (leaves, grass, skin, ice).
      Detect and degrade gracefully when they're missing — vanilla textures must look great.
   2. Wetness: rain darkens and smooths surfaces over a few seconds, puddles in flat areas
      with ripples, splash particles on the ground. Snow accumulates subtly in cold biomes.
   3. Hand/held item: lit consistently with the world (same sun color, shadowed by the
      shadow map when underground), swinging without wind displacement, plus a subtle
      underwater tint.
   4. Post stack order: TAA/accumulation → bloom → exposure (eye adaptation with a slow
      temporal lerp, clamped) → filmic tonemap (AgX preferred, ACES as a toggle) →
      color grading (temperature, saturation, contrast, shadow/highlight tint) → optional
      LUT → vignette → chromatic aberration at the edges (subtle) → film grain (luma-masked)
      → blue-noise dither to kill 8-bit banding.
   5. Underwater: animated caustic light on the screen edges, murk by depth, a subtle
      chromatic wobble on the image edges, muffled fog. Above water, no wobble.

QUALITY SYSTEM
- `shaders.properties` must define real screens, not a swamp of toggles:
    SCREEN "Performance": QUALITY (LOW/MEDIUM/HIGH/ULTRA), VOLUMETRIC_STEPS,
      SSR_STEPS, SHADOW_RES, CLOUD_SHADOWS, TAA on/off.
    SCREEN "Water": WATER_QUALITY, REFLECTION_QUALITY, CAUSTICS, FOAM, WAVE_HEIGHT,
      WATER_TINT, UNDERWATER_FOG.
    SCREEN "Sky": CUSTOM_SKY, SUN_SIZE, MOON_PHASES, STARS, AURORA, CLOUD_LIGHTING,
      SKY_SATURATION.
    SCREEN "Wind": WIND_STRENGTH, WIND_SPEED, WIND_DIRECTION, FOLIAGE_QUALITY.
    SCREEN "Post": EXPOSURE, TONEMAP (AgX/ACES), SATURATION, CONTRAST, BLOOM, GRAIN, VIGNETTE.
- Every screen option must be wired to an actual `#define`/uniform and must actually change
  the image. No dead sliders. `LOW` must run without SSR, without volumetrics, and with
  half-res shadows; `ULTRA` may cost ~2x.
- Slider ranges must be sane and clamped. Add a `profile.*` section so users can switch
  LOW/MEDIUM/HIGH/ULTRA in one click.

PERFORMANCE BUDGET
- HIGH preset, 1080p, GTX 1660 / RX 580 class: 60 fps sustained in a forest at render
  distance 12, no stutter when crossing chunk borders or entering water.
- Total texture fetches per pixel in `composite` ≤ 24 on HIGH; shadow map at 2048 (HIGH)
  with a 1024 low tier; volumetrics on a half-res buffer, upsampled; SSR at full res but
  with an early-out when the pixel is not water (read a water mask from a gbuffer channel —
  never run SSR over the whole screen).
- No dynamic allocation, no loops with data-dependent bounds larger than declared, no
  `textureGrad` on unsupported targets, no division by zero, no NaN propagation into bloom
  (a single NaN pixel becomes a black square — clamp and sanitize every HDR write).

ROBUSTNESS / ACCEPTANCE CRITERIA
- Compiles with zero errors and zero per-frame console spam on Iris 1.7 + OptiFine 1.20.1.
- No z-fighting, no shadow acne, no peter-panning, no reflection leaks through walls, no
  ghosting trails longer than ~4 frames on camera motion.
- Water looks correct at every angle: top-down (no mirror), grazing (soft horizon), from
  underwater looking up (Snell's window), and at the edge of the render distance (no hard
  reflection cutoff).
- God rays visible through leaves, gone when a wall blocks the sun, gone at night, and
  present-but-subtle from the moon.
- Foliage motion is seamless across chunk borders and identical in the shadow pass.
- Sun and moon sit exactly where vanilla's sun/moon would be, track `sunAngle`, and don't
  pop when the day/night transition happens. Eclipses aren't required; continuity is.
- Everything degrades gracefully: no resource pack, no PBR maps, OptiFine instead of Iris,
  Nether/End, rain, thunder, sleeping through the night, F3+A chunk reload.

WORKING METHOD
1. Start by writing the skeleton + `settings.glsl` + `shaders.properties` so the pack loads
   and renders vanilla-correct before any effect exists. Report that it loads.
2. Then land features in this order, one commit each, verifying the pack still loads after
   every one: shadows → sky/sun/moon → water → volumetrics → wind → materials → post.
3. Before writing a pass, state in one sentence what it reads, what it writes, and which
   `colortex` channel carries what. Keep a `BUFFERS.md` table so channels never collide.
4. Prefer `#include` over copy-paste. Every magic number gets a named `#define` with a unit.
5. When you hit a pipeline limitation, pick the boring portable solution and leave a comment
   explaining the trade-off. Do not invent uniforms that don't exist in Iris/OptiFine.
6. Finish with a README (install, presets, perf table, screenshots-to-take list) and a
   short `CHANGELOG.md`.

Ask me at most two clarifying questions before starting, and only if a decision genuinely
changes the architecture. Otherwise make a tasteful call, document it, and ship.
````

---

## 2. Short version

````text
Build me a complete Iris/OptiFine Minecraft shader pack (GLSL 330 core, MC 1.20.1 + 1.21.x,
Iris 1.7+ / OptiFine compatible, no compute or geometry shaders, no external assets).

It must deliver:
- WATER: screen-space ray-marched reflections against the depth buffer with a sky fallback,
  roughness-blurred and temporally cleaned; refraction with depth rejection; Beer–Lambert
  absorption with per-biome water color; animated caustics projected along the sun; shoreline
  foam and crest spray; correct Fresnel and sun glints read from the shadow map.
- GOD RAYS: volumetric ray march through shadowtex1, Henyey–Greenstein phase function,
  blue-noise dither + temporal accumulation, occluded by terrain, leaves and clouds, plus
  height fog and bloom. Screen-space radial shafts as the LOW-tier fallback.
- WIND: vertex sway in both the terrain and shadow passes, driven by world-position sine waves
  plus gust noise, pivoting from the block base, per-block phase offset, different behavior
  for leaves / tall grass / crops / flowers / vines / kelp, scaled by rainStrength, seamless
  across chunk borders and identical in the shadow pass.
- SKY: vanilla sky fully replaced — Rayleigh+Mie single-scatter atmosphere, procedural HDR sun
  with limb darkening and corona, real phased moon with craters and earthshine that follows
  vanilla's moon phase, twinkling stars, optionally aurora; lighting-driven clouds with soft
  moving cloud shadows. Bespoke Nether/End skies.
- SHADOWS: normal-offset + distortion, PCSS variable penumbra, alpha-tested foliage shadows,
  hemisphere ambient + SSAO, sun color taken from the sky so nothing disagrees.
- POST: TAA, bloom, eye-adaptation exposure, AgX tonemap, grading, vignette, subtle grain,
  dithering. Optional labPBR materials with wetness.
- A real quality system in shaders.properties (Performance/Water/Sky/Wind/Post screens,
  LOW–ULTRA profiles, no dead sliders) and a 60 fps HIGH target on a GTX 1660.

Write it as production GLSL with an #include-able lib/ folder, keep a BUFFERS.md channel
table, land it in the order shadows → sky → water → volumetrics → wind → materials → post,
and make sure the pack loads and looks vanilla-correct after every step. Ship a README
with install steps and a performance table.
````

---

## 3. Follow-up prompts (paste after the first build)

**Debug pass**
````text
Audit the pack as if you were reviewing someone else's PR. Check, and fix where broken:
shadow acne and peter-panning at low sun angles; SSR rays escaping through thin geometry;
reflection ghosting when strafing; water pixels with zero-length normals producing NaN bloom;
foliage shadows lagging the color pass; chunk-seam popping at the render-distance edge; sun
and moon popping at dawn/dusk; UI/HUD washed out by exposure; banding in the night sky.
For each issue, tell me the cause in one line and the fix in one line. Then show the diff.
````

**Performance pass**
````text
Profile-cost the pack by inspection. For every program, estimate texture fetches per pixel and
ALUs, then cut the top three costs without changing the look at HIGH: early-outs on the water
mask, half-res volumetrics with a bilateral upsample, fewer SSR refinement steps with a wider
search, branch-free sky on the cheap path. Add an on-screen debug view (F3-style text drawn in
final.fsh, toggled by a setting) showing which passes are active and their step counts.
Re-state the perf table for LOW/MEDIUM/HIGH/ULTRA at 1080p.
````

**Look-dev pass**
````text
Now push it from "correct" to "beautiful". Give me three named look presets that share the same
code path but different grading: "Clear Noon" (crisp, high micro-contrast, saturated but not
candy), "Golden Hour" (warm shafts, long shadows, soft haze, lifted blacks), "Storm" (desaturated,
heavy volumetrics, wind cranked, water choppier and darker). Implement them as toggles that set
the grading + atmosphere uniforms, and describe the exact parameter deltas between them so I can
tune by hand.
````

---

## 4. Bonus: prompt for a cinematic trailer shot (image/video AI)

````text
Cinematic Minecraft screenshot, shot on a high-end shader pack. Vanilla-style blocky terrain but
photoreal lighting: a river cutting through a birch forest at golden hour, camera low over the
water so the surface shows crisp ray-traced reflections of the trees and the sun's glitter path,
volumetric god rays breaking through the canopy in visible shafts with dust motes, tall grass and
leaves visibly bending in the same wind direction, a large custom sun disk near the horizon with a
soft corona and warm atmospheric haze fading distant hills into blue, wispy sunlit clouds with
silver linings, shallow-water caustics on submerged stones, subtle shoreline foam. Deep natural
color grade, filmic contrast, no UI, no text. 16:9, ultra-detailed, photoreal render, shallow
depth of field on the foreground reeds.
````
