vec2 cmul(vec2 a, vec2 b) {
  return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

float sigma(float x) {
  return 1.0f / (1.0 + exp(-x));
}

const float PI = 3.14159263;

float hueCurve(float hue) {
  hue = mod(hue, 1.f);
  if (hue < 0.f) {
    hue += 1.f;
  }
  if (hue < 1.f / 6.f) {
    return 1.f;
  } else if (hue < 2.f / 6.f) {
    return 2.f - 6.f * hue;
  } else if (hue < 4.f / 6.f) {
    return 0.f;
  } else if (hue < 5.f / 6.f) {
    return 6.f * hue - 4.f;
  } else {
    return 1.f;
  }
}

float mouseYadjuster() {
  return iMouse.y / iResolution.y * 2.f;
}

vec3 hueColor(float hue) {
  vec3 result;
  result.x = hueCurve(hue);
  result.y = hueCurve(hue + 1.f / 3.f);
  result.z = hueCurve(hue + 2.f / 3.f);
  return result / pow(length(result), 0.5f);
}

const float BRIGHTNESS = 0.0f;
const float CONTRAST = 12.0f;
const float COLOR_INTENSITY = 4.0f;

const vec3 COLOR_ADJUSTMENT = vec3(0.9f, 0.7f, 1.0f);

vec3 sigma3(vec3 p) {
  return vec3(sigma(p.x), sigma(p.y), sigma(p.z));
}

vec4 huePalette(float steps, float hue) {
  float sf = steps;
  sf = (sf - 0.5f + BRIGHTNESS) * CONTRAST;   
  vec3 c = hueColor(hue);
  c *= COLOR_ADJUSTMENT;
  c *= COLOR_INTENSITY;
  
  return vec4(sigma3(c + sf), 1.f);
}

const int MAX_STEPS = 70;
const float GAMMA = 0.6;

float juliaDepth(vec2 p, vec2 seed) {
  int steps = 0;
  vec2 t = p, t2;
  while (steps < 60) {
    t2 = cmul(t, t) + seed;
    if (length(t2) > 4.0f) {
      break;
    }
    steps++;
    t = t2;
  }
  
  if (steps == MAX_STEPS) {
    return 1.f;
  }
  
  float remainder = (4.f - length(t)) / (length(t2) - length(t));
  
  // this gamma value looks best to smooth out the remainder function
  return (float(steps) + pow(remainder, GAMMA)) / float(MAX_STEPS);
}

vec4 julia(vec2 p, vec2 seed) {    
  float depth = juliaDepth(p, seed);
  return huePalette(depth, p.x * 0.5f);
}

const vec2 JULIA = vec2(-0.835, -0.2321);

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // Normalized pixel coordinates (from 0 to 1)
  vec2 uv = (fragCoord - vec2(iResolution) / 2.0f) / iResolution.x * 3.36f;

  fragColor = julia(uv, JULIA);
}
