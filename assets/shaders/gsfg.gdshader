shader_type spatial;

#define USE_RIM 1

#define USE_PIXELART 1
#define USE_SMOOTH_PIXELART 1

#define USE_ALPHA 1
#define USE_DISABLE_CULL 1

#define USE_SUBSURFACESCATTERING 1

render_mode
	#if USE_DISABLE_CULL
		cull_disabled;
	#else
		cull_back;
	#endif

group_uniforms Toon;
uniform float     ToonRampOffset:     hint_range(0.0, 1.0) = 0.5;
uniform float     ToonRampSmoothness: hint_range(0.0, 1.0) = 0.05;
uniform vec3      ToonRampTinting:    source_color;

group_uniforms Ripple;
uniform vec2 R = vec2(.8, .6);
uniform float scale = 0.5;
uniform float speed = 1.0;
uniform vec3 direction = vec3(1,1,0);
uniform float distortion = 0.5;
uniform float layers = 2.;
uniform float shades = 3.;
uniform int steps = 6;

uniform vec3 tint = vec3(.459,.765,1.);

group_uniforms Texture;
uniform float blend: hint_range(0.0, 1.0) = 0.5;
#if (USE_SMOOTH_PIXELART || !USE_PIXELART)
	uniform sampler2D Texture:            source_color, filter_linear_mipmap_anisotropic;
#else
	uniform sampler2D Texture:            source_color, filter_nearest_mipmap_anisotropic;
#endif

#if USE_RIM
	float fresnel(float amount, vec3 normal, vec3 view) {
		return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
	}
#endif

vec4 texture_point_smooth(sampler2D smp, vec2 uv, vec2 pixel_size) {
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	vec2 lxy = sqrt(ddx * ddx + ddy * ddy);

	vec2 uv_pixels = uv / pixel_size;

	vec2 uv_pixels_floor = round(uv_pixels) - vec2(0.5f);
	vec2 uv_dxy_pixels = uv_pixels - uv_pixels_floor;

	uv_dxy_pixels = clamp((uv_dxy_pixels - vec2(0.5f)) * pixel_size / lxy + vec2(0.5f), 0.0f, 1.0f);

	uv = uv_pixels_floor * pixel_size;

	return textureGrad(smp, uv + uv_dxy_pixels * pixel_size, ddx, ddy);
}

float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }

float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < steps; ++i, a /= 2.) {
        seed += direction * TIME*speed*.01/a;
        seed.z += result*distortion;
        result += gyroid(seed/a)*a;
    }
    return result;
}

void fragment() {
	vec4 textureColor;
	vec2 tex_size = 1.0f / vec2(textureSize(Texture, 0));
	textureColor = texture_point_smooth(Texture, UV, tex_size);
	ALBEDO = textureColor.rgb;
	vec2 p = (2.*UV-R)/R.y;
    float shape = fbm(vec3(p*scale, 0.));
    float gradient = fract(shape*layers);
    float shade = round(pow(gradient, 4.)*shades)/shades;
    vec3 color = mix(tint*mix(.6,.8,gradient), vec3(1), shade);
    ALBEDO = mix(color,ALBEDO,blend);
}

void light() {
	DIFFUSE_LIGHT = vec3(0.5);
}