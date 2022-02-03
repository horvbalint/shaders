// remap from one range to an other (liniar-interpol)
float Remap(vec2 from, vec2 to, float value) {
  float t = (value-from.x) / (from.y-from.x);
  return mix(to.x, to.y, t);
}

float RandFromVec2(vec2 val) {
  return fract(sin(val.x * 113. + val.y * 6.) * 6234.);
}

float SmoothNoise(vec2 val) {
  vec2 localUV = fract(val);
  vec2 id = floor(val);

  // localUV = smoothstep(0., 1., localUV); 
  localUV = localUV * localUV * (3.-2.*localUV);

  float bottom_l = RandFromVec2(id);
  float bottom_r = RandFromVec2(id + vec2(1., 0.));
  float top_l = RandFromVec2(id + vec2(0., 1.));
  float top_r = RandFromVec2(id + vec2(1., 1.));

  float bottom = mix(bottom_l, bottom_r, localUV.x);
  float top = mix(top_l, top_r, localUV.x);

  return mix(bottom, top, localUV.y);
}

float LayeredSmoothNoise(vec2 val, int layerCount) {
  float noise = 0.;
  float strength_sum = 0.;

  for(int i=0; i<layerCount; ++i) {
    float zoom = pow(4., float(i+1));
    float strength = pow(.5, float(i));
    strength_sum += strength;

    noise += SmoothNoise(val * zoom) * strength;
  }

  return noise / strength_sum;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = fragCoord.xy / iResolution.xy;
  uv.x *= iResolution.x/iResolution.y;

  float offset = iTime*.1;
  float brightness = LayeredSmoothNoise(uv + offset, 5);

  fragColor = vec4(vec3(brightness), 1.);
}