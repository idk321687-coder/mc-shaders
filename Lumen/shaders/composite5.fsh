#version 120
// OpenGL internal format value; the shader loader does not define this GLSL token.
#ifndef RGBA16F
#define RGBA16F 34842
#endif
const int colortex6Format = RGBA16F;
#define BLOOM_SOURCE colortex5
#define BLOOM_SCALE 16.0

/* DRAWBUFFERS:6 */
#include "/program/bloom_downsample.glsl"
