float hash(vec2 value) {
    return fract(sin(dot(value, vec2(12.9898, 78.233))) * 34758.5453);
}

float ch_dist2(vec2 point1, vec2 point2) {
    return pow(
        pow(point1.x + point2.x, 2.) + pow(point1.y + point2.y, 2.),
        1. / 2.
    );
}

float ch_dist3(vec2 point1, vec2 point2) {
    return pow(
        pow(point1.x + point2.x, 3.) + pow(point1.y + point2.y, 3.),
        1. / 3.
    );
}

float truchet(vec2 uv, float width, bool striped) {
    vec2 id = floor(uv);
    bool flipped = hash(id) < 0.5;

    vec2 local_uv = fract(uv) - .5;
    vec2 flipped_uv = flipped ? vec2(-1. * local_uv.x, local_uv.y) : local_uv;

    float translation = (flipped_uv.x + flipped_uv.y) < 0. ? .5 : -.5;
    vec2 translated_flipped_uv = flipped_uv + translation;

    float dist = ch_dist2(translated_flipped_uv, vec2(0.));
    float dist_from_circle = abs(.5 - dist);
    float circle = 1. - smoothstep(width/2.3, width/2., dist_from_circle);

    float grid = 0.;
    // if (abs(local_uv.x) > .49 || abs(local_uv.y) > .49) {
    //     grid = 1.;
    // }

    float height = 1. - clamp(abs(local_uv.x) * 2., 0., 1.);

    float stripes = 1.;
    if(striped) {
        float dir = (mod(id.y+id.x, 2.) == 0.) ? 1. : -1.;
        float polar_angle = atan(translated_flipped_uv.y, translated_flipped_uv.x);
        float skewed_angle = polar_angle + (-dir * iTime) + (dir * dist_from_circle) * 3.;
        stripes = 1. - pow(sin(skewed_angle * 35.) / 2. + 0.5, 3.);
    }

    return circle * height * stripes + grid;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float zoom = 4.;
    vec2 uv = (fragCoord-.5*iResolution.xy)/ iResolution.y;
    uv *= (sin(iTime/3.) / 2. + 1.5) * zoom;
    uv += iTime/3.;

    float t1 = truchet(uv, .18, true);
    float t2 = truchet(uv + .5, .18, false);

    vec3 color = vec3(0.);
    color = color + t1 * vec3(1., 0., 0.);
    color = color + t2 * vec3(0., 1., 0.);
    
    fragColor = vec4(color, 1.);
}