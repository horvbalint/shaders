const float PI = 3.1415;

vec3 rgb(float r, float g, float b) {
    return vec3(r / 255., g / 255., b / 255.);
}

float TaperBox(vec2 uv, float height, float bottom_width, float top_width, float blur) {
    uv.y -= height;

    float shade = smoothstep(blur, -blur, abs(uv.y) - height);
    float width = mix(bottom_width, top_width, (uv.y+height) / (2. * height));
    shade *= smoothstep(blur, -blur, abs(uv.x) - width);

    return shade;
}

float Tree(vec2 uv, float blur) {
    float dist = length(vec2(uv.x, uv.y - clamp(uv.y, -.3, .3)));

    float radius = mix(.1, .01, smoothstep(-.3, .3, uv.y));
    float shade = smoothstep(blur, -blur, dist - radius);

    return shade;
}

vec4 Puddle(vec2 uv, vec3 color) {
    uv.x /= 2.;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    float x = angle * 5.;
    float wobbly = (sin(x) + sin(2. * x + 3.)) / 300.;
    float disk = smoothstep(.02, .01, (dist + wobbly)-.1);

    return vec4(color, disk);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= .5; // centers the coordinate system
    uv.x *= iResolution.x/iResolution.y; // compensates for the stretch when the ratio of the screen is not 1

    vec3 color = vec3(0.);

    // color = vec3(TaperBox(uv + vec2(0., .5), .3, .7, .08, .005));
    color = vec3(Tree(uv, .005));

    fragColor = vec4(color, 1.0);
}