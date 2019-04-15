#include <metal_stdlib>
using namespace metal;

kernel void pass_through(texture2d<half, access::read_write> dest [[ texture(0) ]],
                         texture2d<half, access::read> source [[ texture(1) ]],
                         uint2 gid [[ thread_position_in_grid ]]) {
    dest.write(source.read(gid), gid);
}
