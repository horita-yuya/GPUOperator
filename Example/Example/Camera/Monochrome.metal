#include <metal_stdlib>
using namespace metal;

kernel void monochrome(texture2d<half, access::read_write> dest [[ texture(0) ]],
                       texture2d<half, access::read_write> source [[ texture(1) ]],
                       uint2 gid [[ thread_position_in_grid ]]) {
    half3 color = source.read(gid).rgb;
    half max_color = fmax3(color.r, color.g, color.b);
    
    dest.write(half4(half3(max_color), 1), gid);
}
