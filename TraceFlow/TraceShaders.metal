#include <metal_stdlib>
using namespace metal;

struct StarVertex {
    float2 position;
    float pointSize;
    float4 color;
};

struct ViewportUniforms {
    float2 viewportSize;
};

struct RasterizerData {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

vertex RasterizerData trace_star_vertex(
    const device StarVertex *stars [[buffer(0)]],
    constant ViewportUniforms &uniforms [[buffer(1)]],
    uint id [[vertex_id]]
) {
    RasterizerData out;
    float2 unit = stars[id].position;
    float2 pixel = float2(unit.x * uniforms.viewportSize.x, unit.y * uniforms.viewportSize.y);
    float2 ndc = float2(
        (pixel.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (pixel.y / uniforms.viewportSize.y) * 2.0
    );

    out.position = float4(ndc, 0.0, 1.0);
    out.pointSize = stars[id].pointSize;
    out.color = stars[id].color;
    return out;
}

fragment float4 trace_star_fragment(RasterizerData in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float2 centered = pointCoord * 2.0 - 1.0;
    float radius = length(centered);
    if (radius > 1.0) {
        discard_fragment();
    }

    float glow = smoothstep(1.0, 0.0, radius);
    return float4(in.color.rgb, in.color.a * glow);
}
