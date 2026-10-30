#version 120
// OpenGL internal format value; the shader loader does not define this GLSL token.
#ifndef RGBA16F
#define RGBA16F 34842
#endif
const int colortex4Format = RGBA16F;
#define BLOOM_SOURCE colortex3
#define BLOOM_SCALE 4.0

/* DRAWBUFFERS:4 */
#include "/program/bloom_downsample.glsl"
