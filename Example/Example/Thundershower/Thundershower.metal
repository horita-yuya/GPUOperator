#include <metal_stdlib>
using namespace metal;

half2x2 rotate(half a) {
    half c = cos(a);
    half s = sin(a);
    return half2x2(c, s, -s, c);
}

half hash(half2 p) {
    return fract(sin(p.x * 15.32h + p.y * 35.78) * 43758.23h);
}

half2 hash2(half2 p) {
    return half2(hash(p * .754h), hash(1.5743h * p.yx + 4.5891h)) - .5h;
}

half2 hash2b(half2 p) {
    return half2(hash(p * .754h), hash(1.5743h * p + 4.5476351h));
}

constant half2 add = half2(1.0, 0.0);

half2 noise2(half2 x) {
    half2 p = floor(x);
    half2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    half2 res = mix(mix(hash2(p), hash2(p + add.xy), f.x),
                    mix(hash2(p + add.yx), hash2(p + add.xx), f.x), f.y);
    return res;
}

half2 fbm2(half2 x) {
    half2 r = half2(0.0);
    half a = 1.0;
    
    for (int i = 0; i < 8; i++) {
        r += abs(noise2(x) + .5) * a;
        x *= 2.;
        a *= .5;
    }
    return r;
}

constant half2x2 m2 = half2x2(0.80, -0.60, 0.60, 0.80);

half2 fbm3(half2 x) {
    half2 r = half2(0.0);
    half a = 1.0;
    for (int i = 0; i < 6; i++) {
        r += m2 * noise2((x + r) / a) * a;
        r =- .8 * abs(r);
        a *= 1.7;
    }
    return r;
}

half dseg(half2 ba, half2 pa) {
    half h = clamp(dot(pa, ba) / dot(ba, ba), -0.2h, 1.h);
    return length(pa - ba * h);
}

half arc(half2 x, half2 p, half2 dir, half time) {
    half2 r = p;
    half d = 10.;
    for (int i = 0; i < 5; i++) {
        half2 s = noise2(r + time)+dir;
        d = min(d, dseg(s, x-r));
        r += s;
    }
    return d * 3.0;
}

half thunderbolt(half2 x, half2 tgt, half time) {
    half2 r = tgt;
    half d = 1000.;
    half dist = length(tgt - x);
    
    for (int i = 0; i < 19; i++) {
        if (r.y > x.y + .5) break;
        half2 s = (noise2(r + time) + half2(0., .7)) * 2.;
        dist = dseg(s, x - r);
        d = min(d, dist);
        r += s;
        if (i - (i / 5) * 5 == 0) {
            if(i - (i / 10) * 10 == 0)
                d = min(d, arc(x, r, half2( .3, .5), time));
            else
                d = min(d, arc(x, r, half2(-.3, .5), time));
        }
    }
    return exp(-5. * d) + .2 * exp(-1. * dist);
}

half noise(half2 p){
    half2 ip = floor(p);
    half2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    
    half res = mix(
                   mix(hash(ip), hash(ip + half2(1.0, 0.0)), u.x),
                   mix(hash(ip + half2(0.0, 1.0)), hash(ip + half2(1.0, 1.0)), u.x),
                   u.y
                   );
    return res * res;
}


half layer(half2 uv, half fz) {
    half col = (0.);
    
    half2 f = 2. * fract(uv) - 1.;
    half2 i = floor(uv);
    
    
    half2 t = hash2(i) * .8;
    half d = length(f - t);
    
    
    half r = hash(i) * .01 + .001;
    col += smoothstep(r + fz, r, d);
    col += .0008 / d;
    
    return col;
}

half3 lightening(half2 p, half time) {
    half2 tgt = half2(1., -8.);
    half c = 0.;
    half3 col = half3(0.);
    half t = hash(floor(5. * time));
    tgt += 8. * hash2b(tgt + t);
    if (hash(t + 2.3) > 0.8) {
        c = thunderbolt(p * 10. + 2. * fbm2(5. * p), tgt, time);
        col += clamp(1.7 * half3(0.8, .7, .9) * c, 0., 1.);
    }
    return col;
}

kernel void thundershower(texture2d<half, access::read_write> o [[ texture(0) ]],
                          constant float &tt [[ buffer(0) ]],
                          uint2 gid [[ thread_position_in_grid ]]) {
    half2 uv = half2(half(gid.x) / o.get_width(), half(gid.y) / o.get_height());
    half2 u = uv;
    half3 col = half3(0.);
    half time = half(tt);
    
    col += lightening(u, time);
    col += lightening(u + hash(floor(time)), time) * .5;
    col += lightening(hash(floor(time * 34.)) + u * 2., time) * .2;
    col *= half3(0.5, 0.5, 1.25);
    col = col * .5 + o.read(gid).rgb * .8;
    
    o.write(half4(col, 1.0), gid);
}
