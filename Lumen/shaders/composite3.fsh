#version 120
const int colortex4Format = RGBA16F;
#define BLOOM_SOURCE colortex3
#define BLOOM_SCALE 4.0

/* DRAWBUFFERS:4 */
#include "/program/bloom_downsample.glsl"
