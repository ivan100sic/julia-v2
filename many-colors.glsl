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

const float DEBUG_SCALEDOWN = 1.f;

const float MAIN_W = 597.f;
const float MAIN_H = MAIN_W * 9.f / 16.f;
const float SIDE_W = 526.f;
const float SIDE_H = SIDE_W * 9.f / 16.f;

const vec2 MAIN_WH = vec2(MAIN_W, MAIN_H);
const vec2 SIDE_WH = vec2(SIDE_W, SIDE_H);

const vec3 QHD = vec3(2560.f, 1440.f, 0.f) / DEBUG_SCALEDOWN;
const vec3 FOURK = vec3(3840.f, 2160.f, 0.f) / DEBUG_SCALEDOWN;

// Main monitor: 4K, width 597mm
// Side monitors: QHD, width 526mm

vec3 monitorSize(float width) {
  return vec3(width, width * 9.f / 16.f, 0.f);
}

vec2 sceneTransform(vec2 screen) {
  // Compute physical coordinates, relative to bottom left corner of main monitor
  vec2 physCoords;
  if (screen.x < QHD.x) {
    // left screen
    screen.y -= FOURK.y - QHD.y;
    physCoords = screen * SIDE_WH / QHD.xy;
    physCoords.x -= SIDE_W;
    physCoords.y += MAIN_H - SIDE_H;
  } else if (screen.x < QHD.x + FOURK.x) {
    // main monitor
    screen.x -= QHD.x;
    physCoords = screen * monitorSize(MAIN_W).xy / FOURK.xy;
  } else {
    // right screen
    // TODO: implement
    physCoords = (screen - QHD.xz - FOURK.xz) * monitorSize(SIDE_W).xy / QHD.xy
      + monitorSize(SIDE_W).xz
      + monitorSize(MAIN_W).xz;
  }

  // Center at middle of main monitor
  physCoords -= monitorSize(MAIN_W).xy / 2.f;

  vec2 complexCoords = physCoords * 3.36f / (MAIN_W + 2.f * SIDE_W);
  return complexCoords;
}

// Square root of number of antialiasing samples 
const int AA = 8;

void mainImage(out vec4 outColor, in vec2 screen) {
  vec4 sum = vec4(0.f);

  const float aa_f = float(AA);

  for (int i = 0; i < AA; i++) {
    for (int j = 0; j < AA; j++) {
      vec4 color = julia(
        sceneTransform(screen + vec2(i, j) / aa_f),
        JULIA);
      sum += clamp(color, vec4(0.f), vec4(1.f));
    }
  }

  outColor = sum / (aa_f * aa_f);
}
