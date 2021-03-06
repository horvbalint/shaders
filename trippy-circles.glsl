void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord.xy - .5*iResolution.xy) / iResolution.y;
  uv *= 15.;

  float a = .785; // 45deg in radian
  float c = cos(a);
  float s = sin(a);
  uv *= mat2(c, -s, s, c);

  float t = iTime * 5.;
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

  fragColor = vec4(vec3(col), 1.0);
}