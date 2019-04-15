#include <metal_stdlib>
using namespace metal;

kernel void image_difference(texture2d<float, access::read_write> dest [[ texture(0) ]],
                             texture2d<float, access::read> source [[ texture(1) ]],
                             texture2d<float, access::read> target [[ texture(2) ]],
                             uint2 gid [[ thread_position_in_grid ]]) {
    const float3 s_color = source.read(gid).rgb;
    const float3 t_color = target.read(gid).rgb;
    const float3 diff_color = abs(s_color - t_color);
    
    const float diff_length = fmax3(diff_color.r, diff_color.g, diff_color.b);
    const float3 diff_pointing_color = float3(0.234, 0.877, 0.432);
    const float threshold = 0.95f;
    
    if (diff_length > threshold) {
        dest.write(float4(diff_pointing_color, 1.0f), gid);
    } else {
        dest.write(float4(float3(1.0f), 1.0f), gid);
    }
}
