// remap from one range to an other (liniar-interpol)
float remap(vec2 from, vec2 to, float value) {
  float t = (value-from.x) / (from.y-from.x);
  return mix(to.x, to.y, t);
}

float Ember(vec2 uv, float time, float count) {
  uv.x *= count;
  vec2 ember_uv = fract(uv);
  ember_uv.x -= .5;
  // ember_uv.y *= count;

  float radius = .03;
  float travel = time;
  float strength = 1. - time;
  vec2 spawn_pos = vec2(0., radius*2. - travel);
  
  vec2 dist_uv = ember_uv + spawn_pos;
  dist_uv.y *= count;
  float dist = length(dist_uv);
  float ember = 1.-smoothstep(-.01, .01, dist-radius);


  return ember * strength;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  // uv -= .5; // centers the coordinate system
  uv.x *= iResolution.x/iResolution.y; // compensates for the stretch when the ratio of the screen is not 1


  float time = fract(iTime / 3.);
  vec3 color = vec3(0.);

  float ember = Ember(uv, time, 10.);
  color += ember * vec3(1., 0., 0.);

  fragColor = vec4(color, 1.0);
}