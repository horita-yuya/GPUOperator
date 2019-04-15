#include <metal_stdlib>
using namespace metal;

constant half3 bt601(0.299, 0.587, 0.114);

//kernel void prewitt(texture2d<half, access::read_write> dest [[ texture(0) ]],
//                    uint2 gid [[ thread_position_in_grid ]]) {
//    constexpr int kernel_size = 3;
//    constexpr int radius = kernel_size / 2;
//
//    half3x3 prewitt_horizontal_kernel = half3x3(-1, -1, -1,
//                                                0,  0,  0,
//                                                1, 1, 1);
//    half3x3 prewitt_vertical_kernel = half3x3(1, 0, -1,
//                                              1, 0, -1,
//                                              1, 0, -1);
//
//    half3 result_horizontal(0, 0, 0);
//    half3 result_vertical(0, 0, 0);
//    for (int j = 0; j <= kernel_size - 1; j++) {
//        for (int i = 0; i <= kernel_size - 1; i++) {
//            uint2 texture_index(gid.x + (i - radius), gid.y + (j - radius));
//            result_horizontal += prewitt_horizontal_kernel[i][j] * dest.read(texture_index).rgb;
//            result_vertical += prewitt_vertical_kernel[i][j] * dest.read(texture_index).rgb;
//        }
//    }
//
//    half gray_horizontal = dot(result_horizontal.rgb, bt601);
//    half gray_vertical = dot(result_vertical.rgb, bt601);
//
//    half magnitude = length(half2(gray_horizontal, gray_vertical));
//
//    dest.write(half4(half3(magnitude), 1), gid);
//}

kernel void prewitt(texture2d<half, access::read_write> dest [[ texture(0) ]],
                    texture2d<half, access::read> source [[ texture(1) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    constexpr int kernel_size = 3;
    constexpr int radius = kernel_size / 2;

    half3x3 prewitt_horizontal_kernel = half3x3(-1, -1, -1,
                                                0,  0,  0,
                                                1, 1, 1);
    half3x3 prewitt_vertical_kernel = half3x3(1, 0, -1,
                                              1, 0, -1,
                                              1, 0, -1);

    half3 result_horizontal(0, 0, 0);
    half3 result_vertical(0, 0, 0);
    for (int j = 0; j <= kernel_size - 1; j++) {
        for (int i = 0; i <= kernel_size - 1; i++) {
            uint2 texture_index(gid.x + (i - radius), gid.y + (j - radius));
            result_horizontal += prewitt_horizontal_kernel[i][j] * source.read(texture_index).rgb;
            result_vertical += prewitt_vertical_kernel[i][j] * source.read(texture_index).rgb;
        }
    }

    half gray_horizontal = dot(result_horizontal.rgb, bt601);
    half gray_vertical = dot(result_vertical.rgb, bt601);

    half magnitude = length(half2(gray_horizontal, gray_vertical));

    dest.write(half4(half3(magnitude), 1), gid);
}
