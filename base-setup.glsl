// remap from one range to an other (liniar-interpol)
float remap(vec2 from, vec2 to, float value) {
  float t = (value-from.x) / (from.y-from.x);
  return mix(to.x, to.y, t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= .5; // centers the coordinate system
    uv.x *= iResolution.x/iResolution.y; // compensates for the stretch when the ratio of the screen is not 1

    fragColor = vec4(uv.x, uv.y, 0., 1.0);
}