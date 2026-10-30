#version 120
// OpenGL internal format value; the shader loader does not define this GLSL token.
#ifndef RGBA16F
#define RGBA16F 34842
#endif
const int colortex5Format = RGBA16F;
#define BLOOM_SOURCE colortex4
#define BLOOM_SCALE 8.0

/* DRAWBUFFERS:5 */
#include "/program/bloom_downsample.glsl"
