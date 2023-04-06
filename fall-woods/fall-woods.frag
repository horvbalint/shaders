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

vec4 Forest(vec2 uv, float zoom, float blur, vec2 shift, vec3[4] palette) {
  uv *= zoom;

  vec4 forest_color = vec4(0.);

  for(float i=-1.; i<=1.; i++) {
    for(float j=-1.; j<=1.; j++) {

      vec2 local_uv = fract(uv) - vec2(.5) + shift;
      vec2 id = floor(uv) + vec2(i, j);
      float random = hash(id);

      // // shifting the uv, so we get nice shapes
      float rotation = random * PI;
      local_uv = rotate(local_uv, rotation);
      local_uv += vec2((random - .5) / 2.);

      float x_shift = fract(random * 10.) * 10. + 10.;
      float y_shift = fract(random * 100.) * 10. + 10.;

      local_uv.x += sin(local_uv.y * x_shift + u_time) / (x_shift + 10.);
      local_uv.y += sin(local_uv.x * y_shift + u_time) / (y_shift + 10.);

      // calculating the base cirlce
      float dist = length(local_uv - rotate(vec2(i, j), rotation));
      float size = .3 + random / 5.;
      float silhouette = smoothstep(blur, -blur, dist - size);

      // choosing a random color + gradient
      float col_random = fract(random * 23.);
      int color_index = int(col_random * 4.);
      
      vec3 base_color = vec3(1.);
      if(color_index == 0) base_color = palette[0];
      else if(color_index == 1) base_color = palette[1];
      else if(color_index == 2) base_color = palette[2];
      else if(color_index == 3) base_color = palette[3];

      vec3 shifted_color = base_color - col_random / 5.;
      vec3 color = mix(shifted_color, base_color, dist*2.);

      forest_color.rgb = mix(forest_color.rgb, color.rgb, silhouette);
      forest_color.a = max(forest_color.a, silhouette);
    }
  }

  return forest_color;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  uv -= .5; // centers the coordinate system
  uv.x *= u_resolution.x/u_resolution.y; // compensates for the stretch when the ratio of the screen is not 1

  vec3 palette[4];
  palette[0] = vec3(150. / 255., 146. / 255., 72. / 255.);
  palette[1] = vec3(246. / 255., 76. / 255., 37. / 255.);
  palette[2] = vec3(150. / 255., 42. / 255., 56. / 255.);
  palette[3] = vec3(2421. / 255., 160. / 255., 17. / 255.);

  vec4 color = vec4(rgb(43, 48, 38), 1.);

  vec4 forest = Forest(uv, 20., .01, vec2(0.), palette);
  color.rgb = mix(color.rgb, forest.rgb * .7, forest.a);

  forest = Forest(uv, 20., .01, vec2(.5, .5), palette);
  color.rgb = mix(color.rgb, forest.rgb, forest.a);

  gl_FragColor = color;
}