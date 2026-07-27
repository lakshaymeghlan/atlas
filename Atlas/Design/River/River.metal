#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Subtle horizontal ripple for the Analysing screen. Returns the source
// position to sample for each destination pixel, offset by a slow vertical
// sine so the whole canvas shimmers like water. Gated behind Config.useShaders.
[[ stitchable ]] float2 riverRipple(float2 position, float time) {
    float2 p = position;
    p.x += sin(position.y * 0.02 + time * 1.5) * 2.0;
    return p;
}
