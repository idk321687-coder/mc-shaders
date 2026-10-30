#version 120
// Snapshot opaque color before the water and translucent passes.
const int colortex8Format = RGBA16F;
uniform sampler2D colortex0;
varying vec2 uv;
/* DRAWBUFFERS:8 */
void main() { gl_FragData[0] = texture2D(colortex0, uv); }
