#include <metal_stdlib>
using namespace metal;

half plot(half2 st, half pct) {
    half thickness = 0.003h;
    return step(pct - thickness, st.y) - step(pct + thickness, st.y);
}

half sawtooth_series(half x, int n) {
    half series = M_PI_4_H;
    for (int i = 1; i <= n; i++) {
        half cos_factor = (1 + pow(-1, half(i - 1))) / (pow(i, 2.h) * M_PI_H) * cos(i * x);
        half sin_factor = pow(-1, half(i - 1)) / i * sin(i * x);
        series += -cos_factor + sin_factor;
    }
    return series;
}

half linear_series(half x, int n) {
    half series = 0;
    for (int i = 1; i <= n; i++) {
        half sin_factor = 2 * pow(-1, half(i - 1)) / i * sin(i * x);
        series += sin_factor;
    }
    return series;
}

half square_wave_series(half x, int n) {
    half series = 0.5h;
    for (int i = 1; i <= n; i++) {
        half sin_factor = (1 - pow(-1, half(i))) / (i * M_PI_H) * sin(i * x * M_PI_H);
        series += sin_factor;
    }
    return series;
}

kernel void fourier(texture2d<float, access::read_write> dest [[ texture(0) ]],
                    constant float & time [[ buffer(0) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    const half2 st = half2(gid.x / half(dest.get_width()), gid.y / half(dest.get_height()));
    
    half y = 0.2 * square_wave_series(st.x * M_PI_H * 2, int(time) / 3);
    half pct = plot(st, y + 0.6);
    
    half lin_y = 0.05 * linear_series(st.x * M_PI_H * 8, int(time) / 3);
    pct += plot(st, lin_y + 0.3);
    
    half3 painting_color = half3(1.h, 1.h, 1.h);
    
    // The line becomes panting_color.
    // Because the line's pct is 1 and else is 0.
    half3 final_color = half3(pct) * painting_color;
    
//    Convert background color black to white, if needed
//    if (fmax3(final_color.r, final_color.g, final_color.b) == 0.0h) {
//        final_color.rgb = half3(1.0h);
//    }
    dest.write(float4(float3(final_color), 1.0f), gid);
}
