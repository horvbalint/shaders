const float PI = 3.1415;

vec3 rgb(int r, int g, int b) {
  return vec3(float(r) / 255., float(g) / 255., float(b) / 255.);
}

vec2 rotate(vec2 pos, float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * pos;
}

float hash(vec2 value) {
  return fract(sin(dot(value, vec2(13.9841, 78.832))) * 51538.9493);
}

vec4 Forest(vec2 uv, float zoom, float blur, vec3[4] palette, vec2 shift) {
  uv *= zoom;
  uv += shift;

  vec4 forest_color = vec4(rgb(74, 38, 8), 1);

  vec2 road_pos = uv - vec2(.5, 0.);
  float road_mask = step(.6, abs(road_pos.x));
  forest_color.rgb = mix(forest_color.rgb, rgb(48, 56, 67), 1.-road_mask); // TODO: optimize

  float pavement_mask = step(.53, abs(road_pos.x)) * (1.-step(.6, abs(road_pos.x)));
  forest_color.rgb = mix(forest_color.rgb, rgb(207, 191, 178), pavement_mask); // TODO: optimize

  float day_length = 1.;
  float night_time = sin(iTime / day_length - 1.5) / 2. + .5;
  float shadow_time = sin(iTime / day_length) / 2.;

  vec2 shadow_shift_amount = vec2(shadow_time/2.);

  for(float i=-1.; i<=1.; i++) {
    for(float j=-1.; j<=1.; j++) {
      vec2 id = floor(uv) + vec2(i, j);
      float random = hash(id);
      vec2 local_uv = fract(uv) - vec2(.5) - vec2(i, j);

      // // shifting the uv, so we get nice shapes
      float rotation = random * 2. * PI;
      local_uv = rotate(local_uv, rotation);
      local_uv += vec2(random - .5);

      vec2 shadow_shift = rotate(shadow_shift_amount, rotation);
      vec2 shadow_uv = local_uv - shadow_shift;

      vec2 edge_shift = fract(random * vec2(10., 100.)) * 10. + 10.;
      shadow_uv += sin(shadow_uv.yx * edge_shift + iTime) / (edge_shift + 10.);
      local_uv += sin(local_uv.yx * edge_shift + iTime) / (edge_shift + 10.);

      // calculating the base cirlce
      float size = .4 + random / 5.;
      
      float tree_dist = length(local_uv);
      float tree_mask = smoothstep(blur, -blur, tree_dist - size);

      float shadow_dist = length(shadow_uv);
      float shadow_mask = smoothstep(blur, -blur, shadow_dist - size);

      // choosing a random color + gradient
      int color_index = int(fract(random * 23.) * 4.);
      
      vec3 base_color = vec3(1.);
      if(color_index == 0) base_color = palette[0];
      else if(color_index == 1) base_color = palette[1];
      else if(color_index == 2) base_color = palette[2];
      else base_color = palette[3];

      float color_shift = fract(random * 78.) / 20. + .05;
      vec3 center_color = base_color + color_shift;
      vec3 edge_color = base_color - color_shift;
      vec3 color = mix(center_color, edge_color, length(local_uv + shadow_shift)*2.);

      float road_mask = step(.5, abs(id.x));
      float shadow_alpha = shadow_mask * road_mask;
      forest_color.rgb = mix(forest_color.rgb, vec3(0.), shadow_alpha/3. * night_time);

      float tree_alpha = tree_mask * road_mask;
      forest_color.rgb = mix(forest_color.rgb, color.rgb, tree_alpha);
    }
  }

  forest_color.rgb = mix(forest_color.rgb, rgb(12, 15, 28), 1.-(night_time * .8 + .2));

  return forest_color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord.xy / iResolution.xy;
  uv -= .5; // centers the coordinate system
  uv.x *= iResolution.x/iResolution.y; // compensates for the stretch when the ratio of the screen is not 1

  vec3 palette[4];
  palette[0] = rgb(150, 146, 72);
  palette[1] = rgb(246, 76, 37);
  palette[2] = rgb(150, 42, 56);
  palette[3] = rgb(255, 160, 17);

  vec4 color = vec4(rgb(43, 48, 38), 1.);

  vec4 forest = Forest(uv, 18., .02, palette, vec2(2.35, -.5));
  color.rgb = mix(color.rgb, forest.rgb, forest.a);

  fragColor = color;
}