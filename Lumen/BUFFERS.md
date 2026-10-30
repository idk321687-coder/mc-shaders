# Buffers

| Buffer | Contents | Writers / readers |
| --- | --- | --- |
| colortex0 | HDR scene color (RGBA16F) | Gbuffers write; composite reads and writes via loader ping-pong; final reads. |
| colortex7 RGB | encoded view-space normal | Terrain/water write; composite reads. |
| colortex7 A | water marker (1 for water, 0 for terrain and other translucent blocks) | Terrain/water write; composite reads. |
| colortex2–6 | half, quarter, eighth, sixteenth and 1/32 resolution HDR bloom levels | composite1–5 progressively downsample; final combines. |
| colortex8 | opaque scene color (RGBA16F) | deferred snapshots colortex0 before translucent passes; composite reads for refraction. |
| depthtex0 | current scene depth | Loader writes; composite reads for sky, reflections and fog. |
| depthtex1 | opaque scene depth before translucents | Loader writes; composite reads for approximate water thickness and refraction rejection. |
| shadowtex0 | alpha-tested shadow depth | Shadow pass writes; terrain and composite sample for shadows, glints, caustics and shafts. |

colortex7 is used rather than colortex1 because the latter clears to white in OptiFine.
Water marker correctness depends on loader blend and draw ordering; validate in-game before
building additional effects on this layout. Other passes use loader defaults and can affect
the attachments. No persistent history buffers are allocated.
