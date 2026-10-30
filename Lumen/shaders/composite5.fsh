#version 120
const int colortex6Format = RGBA16F;
#define BLOOM_SOURCE colortex5
#define BLOOM_SCALE 16.0

/* DRAWBUFFERS:6 */
#include "/program/bloom_downsample.glsl"
