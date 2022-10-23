precision highp float;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

const float PI = 3.1415;

vec3 rgb(int r, int g, int b) {
  return vec3(float(r) / 255., float(g) / 255., float(b) / 255.);
}

vec2 rotate(vec2 pos, float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * pos;
}

float hash(vec2 value) {
  return fract(sin(dot(value, vec2(19.9898, 78.233))) * 34258.5453);
}

float hash(float value) {
  return fract(sin(dot(value, 19.9898)) * 34258.5453);
}

float TaperBox(vec2 uv, float bottom_y, float top_y, float bottom_width, float top_width, float blur) {
  float alpha = smoothstep(-blur, blur, uv.y - bottom_y);
  alpha *= smoothstep(blur, -blur, uv.y - top_y);

  float width = mix(bottom_width, top_width, (uv.y - bottom_y)/(top_y-bottom_y));
  alpha *= smoothstep(blur, -blur, abs(uv.x) - width);

  return alpha;
}

float roundedRect(vec2 uv, vec2 size, float radius) {
  return length(max(abs(uv)-size+radius,0.0))-radius;
}

vec4 Window(vec2 uv, float blur) {
  // calculating movement
  uv += sin(u_time)/100.;

  float time = fract(u_time / 3.);
  float shouldBump = step(.95, time);
  float bump = sin((time-.95) * 20. * PI) * .003;
  uv.y += shouldBump * bump;

  // calculating shape
  float ratio = u_resolution.x/u_resolution.y;
  float width = .5 * ratio - .05;
  float height = .45;

  float cut_out = roundedRect(uv, vec2(width, height), .1);
  cut_out = smoothstep(blur, -blur, cut_out);

  // adding color
  vec3 color = mix(rgb(30, 20, 20), rgb(13, 9, 5), uv.x + .5 - uv.y);

  return vec4(color, 1.-cut_out);
}

vec3 Sky(vec2 uv, vec3 from, vec3 to) {
  return mix(from, to, rotate(uv, .05).y * 2.);
}

vec4 Mountains(vec2 uv, float blur) {
  float size = 50.;
  float x = uv.x * size - u_time;
  float height = ((sin(x / 3.) + 1.)) + sin(x/4. + 2.) + (sin(x + 3.)/2.) + (sin(x*3. + 1.)/9.);

  float silluete = smoothstep(blur, -blur, (uv.y * size) - height);
  vec3 color = mix(rgb(0, 0, 0), rgb(153, 105, 106), clamp((uv.y + .2) * 5., 0., 1.));

  return vec4(color, silluete);
}

float WindTurbine(vec2 uv, float random, float blur) {
  uv *= 5.;
  uv.y -= .5;

  float color = TaperBox(uv, -.5, .2, .03, .015, blur);

  float deg_60 = 2.*PI/3.;
  float rotation = -(u_time*(random+.5)) + random*60.;
  vec2 blade_uv = uv - vec2(0., .2);
  color += TaperBox(rotate(blade_uv, rotation), 0., .35, .024, .01, blur);
  color += TaperBox(rotate(blade_uv, rotation + deg_60), 0., .35, .024, .01, blur);
  color += TaperBox(rotate(blade_uv, rotation + 2.*deg_60), 0., .35, .024, .01, blur);

  return clamp(color, 0., 1.);
}

float getHillHeight(float x) {
  x = x * 25.;
  return sin(x/5.) - 2. + (sin(x/2. + 4.)/7.) + (sin(x + 3.)/10.);
}

vec4 Hills(vec2 uv, float blur) {
  float size = 2.;
  float x = uv.x * size - u_time/15.;
  float height = getHillHeight(x);
  float y = uv.y * size * 25. - height;

  float silluete = smoothstep(blur, -blur, y);
  vec3 color = mix(rgb(0, 0, 0), rgb(82, 68, 44), clamp((uv.y + .4) * 3., 0., 1.));

  float id = floor(x);
  float random = hash(id);
  float offset = mix(-.35, .35, random);
  float turbine_x = fract(x) - .5 + offset;
  float turbine_height = getHillHeight(id + .5 - offset);
  float turbine_y = uv.y * size * 25. - turbine_height;

  float turbine = WindTurbine(vec2(turbine_x, turbine_y / 25.), random, 0.01);
  color += turbine * rgb(126, 115, 133);

  return vec4(color, clamp(silluete + turbine, 0. ,1.));
}

vec4 Field(vec2 uv, float blur) {
  float size = 50.;
  float x = uv.x * size - u_time*8.;
  float height = sin(x/10.)-5. + sin(x/4.)/3.;

  float silluete = smoothstep(blur, -blur, (uv.y * size) - height);
  vec3 color = mix(rgb(34, 36, 14), rgb(52, 54, 28), clamp((uv.y + .4) * 4., 0., 1.));

  return vec4(color, silluete);
}

vec4 Plane(vec2 uv) {
  float width = u_resolution.x/u_resolution.y;

  float speed = 50.;
  float rotation = PI / 2.2;
  float x_pos = fract(u_time/speed) * width * 3.;
  vec2 final_uv = rotate(uv, rotation) + vec2(-.4, .5*width - x_pos);

  float plane = TaperBox(final_uv, -.005, .005, .002, .0, .002);
  vec4 color = vec4(plane * rgb(153, 105, 106), plane);

  float progress = clamp(-final_uv.y / width / 2., 0., 1.);
  float trail_blur = progress / 50. + .005;
  float y_shift = (sin(uv.x * 30.) / 500.) * progress;
  float trail = TaperBox(final_uv + vec2(y_shift, 0.), -2.*width, 0., .015, 0.0004, trail_blur);
  float alpha = trail * (1. - progress);
  color.rgb = mix(color.rgb, vec3(trail * rgb(215, 134, 141)), alpha);
  color.a = max(color.a, alpha);

  return vec4(color);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv -= .5; // centers the coordinate system
    uv.x *= u_resolution.x/u_resolution.y; // compensates for the stretch when the ratio of the screen is not 1

    vec3 color = Sky(uv, rgb(245, 129, 116), rgb(148, 145, 197));

    vec4 mountains = Mountains(uv, 0.1);
    color = mix(color, mountains.rgb, mountains.a);

    vec4 hills = Hills(uv, 0.1);
    color = mix(color, hills.rgb, hills.a);

    vec4 field = Field(uv, 0.1);
    color = mix(color, field.rgb, field.a);

    vec4 plane = Plane(uv);
    color += plane.rgb;

    vec4 window = Window(uv, 0.005);
    color = mix(color, window.rgb, window.a);

    gl_FragColor = vec4(color, 1.0);
}