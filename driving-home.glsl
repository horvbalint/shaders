// remap from one range to an other (liniar-interpol)
float remap(vec2 from, vec2 to, float value) {
  float t = (value-from.x) / (from.y-from.x);
  return mix(to.x, to.y, t);
}

float randf(float seed) {
  return fract(sin(seed*3456.) * 6547.);
}

vec3 randvec3(float seed) {
  return fract(sin(seed*vec3(123., 1024., 3456.)) * vec3(6547., 345., 8799.));
}

struct Ray {
  vec3 origin, dir;
};

Ray getRay(vec2 uv, vec3 camPos, vec3 lookAt, float zoom) {
  Ray ray;
  ray.origin = camPos;
  
  vec3 forward = normalize(lookAt - camPos);
  vec3 right = cross(vec3(0, 1, 0), forward);
  vec3 up = cross(forward, right);
  vec3 center = ray.origin + forward * zoom;
  vec3 intersect = center + uv.x * right + uv.y * up;

  ray.dir = normalize(intersect - ray.origin); 

  return ray;
}

vec3 closestPoint(Ray ray, vec3 point) {
  return ray.origin + max(0., dot(point - ray.origin, ray.dir)) * ray.dir;
}

float distRay(Ray ray, vec3 point) {
  return length(point - closestPoint(ray, point));
}

float bokeh(Ray ray, vec3 point, float size, float blur) {
  float dist = distRay(ray, point);

  size *= length(point);
  float color = smoothstep(size, size*(1.-blur), dist);
  color *= mix(.6, 1., smoothstep(size*.8, size, dist));
  return color;
}

vec3 streetLights(Ray ray, float time) {
    const float s = 1./8.; // 0.1

    float side = step(ray.dir.x, 0.)  * s * .5;
    ray.dir.x = abs(ray.dir.x);

    float mask = 0.;
    for(float i=0.; i<1.; i+=s) {
      float ti = fract(time + i + side);
      vec3 point = vec3(2.3, 2., 100.-(ti * 100.));
      mask += bokeh(ray, point, .04, .1) * ti * ti * ti;
    }

    return vec3(1., .7, .2) * mask;
}

vec3 envLights(Ray ray, float time) {
    const float s = 1./5.; // 0.1

    float side = step(ray.dir.x, 0.)  * s * .5;
    ray.dir.x = abs(ray.dir.x);

    vec3 color = vec3(0.);
    for(float i=0.; i<1.; i+=s) {
      float ti = fract(time + i + side);
      vec3 rand3 = randvec3(i+side*100.);

      float occlusion = sin(ti*6.28*10.*rand3.x)/2.+1.;
      float fade = occlusion;
      float x = mix(2.5, 10., rand3.x);
      float y = mix(.1, 1.5, rand3.y);
      vec3 point = vec3(x, y, 50.-(ti * 50.));

      vec3 col = rand3.zxy;
      color += bokeh(ray, point, .04, .1)*fade*col*.2;
    }

    return color;
}

vec3 headLights(Ray ray, float time) {
    time *= 2.;
    float mask = 0.;

    float circlePos = .25;
    float rectPos = circlePos * 1.2;

    const float s = 1./30.; // 0.1
    for(float i=0.; i<1.; i+=s) {
      float n = randf(i);
      if(n > .1) continue;

      float ti = fract(time + i);
      float z = 100.-(ti * 100.);
      float fade = pow(ti, 6.);
      float focus = smoothstep(.9, 1., ti);
      float size = mix(.05, .03, ti);

      mask += bokeh(ray, vec3(-1.-circlePos, .15, z), size, .1) * fade;
      mask += bokeh(ray, vec3(-1.+circlePos, .15, z), size, .1) * fade;

      mask += bokeh(ray, vec3(-1.-rectPos, .15, z), size, .1) * fade;
      mask += bokeh(ray, vec3(-1.+rectPos, .15, z), size, .1) * fade;
    
      float ref = 0.;
      ref += bokeh(ray, vec3(-1.-rectPos, -.15, z), size * 3., 1.) * fade;
      ref += bokeh(ray, vec3(-1.+rectPos, -.15, z), size * 3., 1.) * fade;
    
      mask += ref * focus;
    }

    return vec3(.9, .9, 1.) * mask;
}

vec3 tailLights(Ray ray, float time) {
    time /= 2.5;
    float mask = 0.;

    float circlePos = .25;
    float rectPos = circlePos * 1.2;

    const float s = 1./20.; // 0.1
    for(float i=0.; i<1.; i+=s) {
      float n = randf(i);
      if(n > .3) continue;

      float lane = step(.1, n);
      float ti = fract(time + i);
      float z = 100.-(ti * 100.);
      float fade = pow(ti, 6.);
      float focus = smoothstep(.9, 1., ti);
      float size = mix(.05, .03, ti);

      float laneShift = 1.-smoothstep(.93, 1., ti);
      float x = 1.5 - lane * (laneShift);
      
      float blink = step(0., sin((time-10.)*200.)) * 7. * lane * step(.92, ti);

      mask += bokeh(ray, vec3(x-circlePos, .15, z), size, .1) * fade;
      mask += bokeh(ray, vec3(x+circlePos, .15, z), size, .1) * fade;

      mask += bokeh(ray, vec3(x-rectPos, .15, z), size, .1) * fade;
      mask += bokeh(ray, vec3(x+rectPos, .15, z), size, .1) * fade * (1.+blink);
    
      float ref = 0.;
      ref += bokeh(ray, vec3(x-rectPos, -.15, z), size * 3., 1.) * fade;
      ref += bokeh(ray, vec3(x+rectPos, -.15, z), size * 3., 1.) * fade  * (1.+blink*.1);
    
      mask += ref * focus;
    }

    return vec3(1., .1, .03) * mask;
}

vec2 rain(vec2 uv, float time) {
  time *= 40.;

  vec2 aspect = vec2(3., 1.);
  vec2 st = uv * aspect;
  vec2 id = floor(st);
  st.y += time * .21;
  float gridOffset = fract(sin(id.x * 716.34)*768.34);
  st.y += gridOffset;
  uv.y += gridOffset;
  id = floor(st);
  st = fract(st) - .5;

  time += fract(sin(id.x * 76.34 + id.y * 1453.7)*6.283) * 6.28;
  
  float y = -sin(time+sin(time+sin(time)*.5)) * .43;
  vec2 position1 = vec2(0., y);
  vec2 offset1 = (st-position1)/aspect;

  vec2 point = offset1;
  if(offset1.y > 0.) point.y *= .5;
  float dist = length(point);
  float mask1 = smoothstep(.07, .0, dist);

  vec2 offset2 = (fract(uv*aspect.x*vec2(1., 2.)) -.5) / vec2(1., 2.);
  dist = length(vec2(offset2.x, offset2.y * 1.));
  float visible = smoothstep(-.1, .1, st.y - position1.y);
  float mask2 = smoothstep(.3 * (.5 - st.y), .0, dist) * visible;

  // if(st.x>.46) mask1 = 1.;
  // if(st.y>.49) mask1 = 1.;

  // return vec2(mask1 + mask2);
  return vec2(mask1*offset1*30. + mask2*offset2*10.);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv -= .5; // centers the coordinate system
    uv.x *= iResolution.x / iResolution.y; // compensates for the stretch when the ratio of the screen is not 1

    // vec2 mouse = iMouse.xy/iResolution.xy;
    // float time = iTime * .05 + mouse.x;
    float time = iTime * .05 + .7;
    vec3 camPos = vec3(.5, .2, 0.);
    vec3 lookAt = vec3(.5, .2, 1.);

    vec2 rainDistortion = rain(uv*5., time) * .5;
    rainDistortion += rain(uv*8., time) * .5;

    uv.x += sin(uv.y*70.) * .005;
    uv.y += sin(uv.x*170.) * .003;
    Ray ray = getRay(uv-rainDistortion*.5, camPos, lookAt, 2.);

    vec3 color = vec3(0., 0., 0.);
    color += streetLights(ray, time);
    color += headLights(ray, time);
    color += tailLights(ray, time);
    color += envLights(ray, time);

    color += (ray.dir.y+.25) * vec3(.2, .1, .5);

    // color = vec3(rainDistortion, 0.);
    gl_FragColor = vec4(vec3(color), 1.0);
}