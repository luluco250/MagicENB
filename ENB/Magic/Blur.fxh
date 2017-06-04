#ifndef BLUR_FXH
#define BLUR_FXH

#include "Common.fxh"

//Configurations

#define BLUR_SAMPLES 5
#define CIRCLE_BLUR_OFFSET_SAMPLES 6
#define CIRCLE_BLUR_ANGLE_SAMPLES 12

//static const float sigma = float(BLUR_SAMPLES) / 2.0;
static const float sigma = sqrt(BLUR_SAMPLES);

//Taken from here: https://en.wikipedia.org/wiki/Gaussian_blur#Mathematics
float gaussian_function(float2 i) {
    return (1.0 / (doublepi * sigma * sigma)) * exp(-((i.x * i.x + i.y * i.y) / (2.0 * sigma * sigma)));
}

static const float2 centered_offset = float(BLUR_SAMPLES) * 0.5;

float3 gaussian_blur(Texture2D tex, float2 uv, float2 scale) {    
    float2 ps = pixelsize * scale;

    float2 coord = 0.0;
    float weight = gaussian_function(coord);
    float3 col = tex.Sample(Sampler_Linear, uv).rgb * weight;
    float accum = weight;

    [unroll]
    for (int x = 1; x <= BLUR_SAMPLES; ++x) {
        [unroll]
        for (int y = 1; y <= BLUR_SAMPLES; ++y) {
            coord = float2(x, y) - centered_offset;
            weight = gaussian_function(coord);
            col += tex.Sample(Sampler_Linear, uv + ps * coord).rgb * weight;
            accum += weight;
        }
    }

    return col / accum;
}

float2 rot2D(float offset, float angle) {
	angle = degs2rads(angle);
	return float2(cos(angle), sin(angle)) * offset;
}

static const float angle_step = 360 / CIRCLE_BLUR_ANGLE_SAMPLES;

float3 circle_blur(Texture2D tex, float2 uv, float2 scale) {
	float2 ps = pixelsize * scale;
	float3 col = tex.Sample(Sampler_Linear, uv).rgb;
	
	float accum = 1.0;
	float weight = 0;
	float2 offcoord = 0;
	
	[unroll]
	for (int a = 0; a < 360; a += angle_step) {
		[unroll]
		for (int o = 1; o < CIRCLE_BLUR_OFFSET_SAMPLES; ++o) {
			offcoord = rot2D(o, a);
			weight = o;
			col += tex.Sample(Sampler_Linear, uv + ps * offcoord).rgb * weight;
			accum += o;
		}
	}

	return col / accum;
}

#endif