#version 120
const int colortex5Format = RGBA16F;
#define BLOOM_SOURCE colortex4
#define BLOOM_SCALE 8.0

/* DRAWBUFFERS:5 */
#include "/program/bloom_downsample.glsl"
