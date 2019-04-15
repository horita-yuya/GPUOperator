#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 position [[ position ]];
    float2 texture_coordinates;
} FragmentCoordinate;

// Reference: https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
// Section 4.2.1
// `device` address space: refers to buffer memory objects allocated from the device memory pool that are both readable and writable.
vertex FragmentCoordinate graphics_vertex(const device packed_float2* vertex_data [[ buffer(0) ]],
                                          const device packed_float2* texture_data [[ buffer(1) ]],
                                          uint vid [[ vertex_id ]]) {
    FragmentCoordinate coordinate;
    coordinate.position = float4(vertex_data[vid], 0.0, 1.0);
    coordinate.texture_coordinates = texture_data[vid];
    return coordinate;
}

fragment float4 graphics_fragment(FragmentCoordinate coordinate [[ stage_in ]],
                                  texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s;
    return texture.sample(s, coordinate.texture_coordinates);
}
