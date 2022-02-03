float circle(vec2 uv, vec2 position, float radius, float blurWidth) {
  float dist = length(uv-position);
  return 1.-smoothstep(radius-blurWidth, radius, dist);
}

float smileyFace(vec2 uv, vec2 position, float size, float blur) {
  uv -= position;
  uv /= size;

  float head = circle(uv, vec2(0.), .3, blur);
  float eyes = circle(vec2(abs(uv.x), uv.y), vec2(.13, +.1), .07, blur);
  float mouth = circle(uv, vec2(0.), .25, blur);
  mouth -= circle(uv, vec2(0, .24), .4, blur);

  return head - eyes - clamp(mouth, 0., 1.);
}

float band(float k, float start, float end, float blur) {
  float brightness = 0.;
  brightness += smoothstep(start-blur, start+blur, k);
  brightness *= 1.-smoothstep(end-blur, end+blur, k);

  return brightness;
}

float rect(vec2 uv, vec2 pos, float width, float height, float blur) {
  uv -= pos;
  return band(uv.x, -width/2., width/2., blur) * band(uv.y, -height/2., height/2., blur);
}

float remap(vec2 from, vec2 to, float value) {
  float t = (value-from.x) / (from.y-from.x);
  return mix(to.x, to.y, t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= .5;
    uv.x *= iResolution.x/iResolution.y;

    float brightness = 0.;
    vec3 targetCol = vec3(1.);

    // targetCol = vec3(1., 1., 0.);
    // brightness += smileyFace(uv, vec2(0.), 1., .0);
    // brightness += smileyFace(abs(uv), vec2(.3), .2, .0);

    float x = uv.x;
    float y = uv.y - sin(x * 8. + iGlobalTime) * .1;

    float xDiff = remap(vec2(-.4, .4), vec2(.2, .0), x);
    float blur = pow(xDiff*3., 2.);
    float height = blur / 2. + .01;

    brightness += rect(vec2(x, y), vec2(0.), .8, height, blur);

    fragColor = vec4(targetCol * brightness, 1.0);
}