#version 120
const int colortex3Format = RGBA16F;
#define BLOOM_SOURCE colortex2
#define BLOOM_SCALE 2.0

/* DRAWBUFFERS:3 */
#include "/program/bloom_downsample.glsl"
