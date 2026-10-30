#version 120
// OpenGL internal format value; the shader loader does not define this GLSL token.
#ifndef RGBA16F
#define RGBA16F 34842
#endif
const int colortex2Format = RGBA16F;
#define BLOOM_SOURCE colortex0
#define BLOOM_SCALE 1.0
#define BLOOM_THRESHOLD
/* DRAWBUFFERS:2 */
#include "/program/bloom_downsample.glsl"
