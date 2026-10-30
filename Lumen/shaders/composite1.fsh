#version 120
const int colortex2Format = RGBA16F;
#define BLOOM_SOURCE colortex0
#define BLOOM_SCALE 1.0
#define BLOOM_THRESHOLD
/* DRAWBUFFERS:2 */
#include "/program/bloom_downsample.glsl"
