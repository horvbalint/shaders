const float PI = 3.1415;
const vec2 MOON_POS = vec2(-.1, .08);
const vec3 MOON_COL = vec3(213./255., 225./255., 242./255.);
const float NUM_OF_TREES = 8.;

float hash(vec2 value) {
  return fract(sin(dot(value, vec2(19.9898, 78.233))) * 34258.5453);
}

vec2 rotate(vec2 pos, float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * pos;
}

float TaperBox(vec2 uv, float bottom_y, float top_y, float bottom_width, float top_width, float blur) {
  float alpha = smoothstep(-blur, blur, uv.y - bottom_y);
  alpha *= smoothstep(blur, -blur, uv.y - top_y);

  float width = mix(bottom_width, top_width, (uv.y - bottom_y)/(top_y-bottom_y));
  alpha *= smoothstep(blur, -blur, abs(uv.x) - width);

  return alpha;
}

vec4 Tree(vec2 uv, vec3 color, float rotation, float blur) {
  uv = rotate(uv, rotation/10.-.05);

  float main = TaperBox(uv, -.3, .2, .05, .05, blur);
  main += TaperBox(uv, .2, .45, .3, .15, blur);
  main += TaperBox(uv, .45, .7, .25, .08, blur);
  main += TaperBox(uv, .7, .9, .15, .0, blur);
  vec3 col = color * main;

  // shadows
  float shadow = 0.;
  shadow += TaperBox(uv + vec2(.35, 0.), .1, .2, .0, .5, blur);
  shadow += TaperBox(uv + vec2(-.25, 0.), .38, .45, .0, .5, blur);
  shadow += TaperBox(uv + vec2(.25, 0.), .63, .7, .0, .5, blur);
  col = mix(col, color * .6, shadow);

  return vec4(col, main);
}

float get_height(vec2 pos) {
  return sin(pos.x)/3. + sin(pos.x * 3.)/10.;
}

vec4 Layer(vec2 uv, vec3 color, float blur) {
  vec2 id = floor(uv);
  vec4 col = vec4(0.);

  float random = hash(vec2(id.x));
  vec2 scale = vec2(
    mix(1., 1.3, fract(random*10.)),
    mix(1., 1.1, fract(random*43.))
  );
  scale.x *= step(.5, random)* 2. - 1.;
  float offset = mix(-.2, .2, fract(random*27.));

  float tree_height = get_height(id + .5 - offset);
  vec2 tree_pos = vec2(fract(uv.x) - .5 + offset, uv.y - tree_height);
  vec4 tree = Tree(tree_pos * scale, color, fract(random*23.), blur);

  float alpha = clamp(col.a + tree.a, 0., 1.);
  col = vec4(mix(col.rgb, tree.rgb, tree.a), alpha);

  float ground_height = get_height(uv);
  float ground = smoothstep(blur, -blur, uv.y - ground_height);
  alpha = clamp(col.a + ground, 0., 1.);
  col = vec4(vec3(mix(col.rgb, color, ground)), alpha);

  return col;
}

float Moon(vec2 uv) {
  float dist = length(uv - MOON_POS);
  float alpha = smoothstep(.0015, -.0015, dist-.06);

  return clamp(alpha, 0., 1.);
}

float MoonHalo(vec2 uv) {
  float dist = length(uv - MOON_POS);

  return mix(.9, 0., dist*1.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  uv -= .5; // centers the coordinate system
  uv.x *= iResolution.x/iResolution.y; // compensates for the stretch when the ratio is not 1:1
  
  uv.y += .2;
  uv /= 2.;
  uv += (iMouse.xy / iResolution.xy -.5) / 10.;

  vec3 color = vec3(0.);

  float rand = hash(uv);
  float star = (1.-step(0.006, rand)) * rand * 100.;
  color = vec3(star);

  float halo = MoonHalo(uv);
  color = mix(color, MOON_COL * halo, halo);

  float moon = Moon(uv);
  color = mix(color, MOON_COL * moon, moon);

  for(float i=0.; i<1.; i+=1./NUM_OF_TREES) {
    vec2 pos = vec2(uv.x + i * 46.7 + iTime / 30. * (i + .3), uv.y);

    float rev_i = (1.-1./NUM_OF_TREES - i);
    float scale = mix(5., 20., rev_i);
    float shade = mix(.1, 1., rev_i);
    float blur = mix(.008, .03, rev_i);

    vec4 layer = Layer(pos * scale, MOON_COL * shade, blur);
    color = mix(color, layer.rgb, layer.a);
  }

  vec4 layer = Layer(vec2(uv.x + 0. + iTime/10., uv.y+.9), vec3(0.), .015);
  color = mix(color, layer.rgb, layer.a);

  fragColor = vec4(color, 1.);
}