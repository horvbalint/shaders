precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
  vec2 uv = (gl_FragCoord.xy - .5*u_resolution.xy) / u_resolution.y;
  uv *= 15.;

  float a = .785; // 45deg in radian
  float c = cos(a);
  float s = sin(a);
  uv *= mat2(c, -s, s, c);

  float t = u_time * 5.;
  vec2 lv = fract(uv) - .5;

  bool isInverse = false;

  for(float i=-1.; i<2.; i+=1.) {
    for(float j=-1.; j<2.; j+=1.) {
      vec2 id = floor(uv - vec2(i, j));
      float distFromOrigin = length(id);
      float distFromLocalOrigin = length(uv - id);
      float radius = (sin((t - distFromOrigin * 2.) / 3.) * .3 + .6);

      if(distFromLocalOrigin <= radius) isInverse = !isInverse;
    }
  }

  float col = 0.;
  if(isInverse) col = 1. - col;

  gl_FragColor = vec4(vec3(col), 1.0);
}