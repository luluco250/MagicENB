#ifndef MAGIC_ENB_UTILS_COMMON_HLSL
#define MAGIC_ENB_UTILS_COMMON_HLSL

//#region Preprocessor

#define STR(x) #x
#define NAMEOF(x) STR(x)

//#endregion

//#region Constants

static const float Pi = 3.14159;
static const float HalfPi = Pi * 0.5;
static const float DoublePi = Pi * 2.0;

static const float Epsilon = 1e-5;

static const float ContrastLogMidpoint = 0.18;

static const float Gamma = 2.2;
static const float GammaInv = rcp(Gamma);

static const float3 LumaWeights = float3(0.299, 0.587, 0.114);

//#endregion

//#region Uniforms

/*
 * x: Normalized timer in a 4.6 hours period.
 * y: Average framerate.
 * w: Frame time (seconds).
 */
float4 Timer;

/*
 * x: Screen width.
 * y: 1 / width.
 * z: Screen aspect ratio (width / height).
 * w: 1 / aspect ratio.
 */
float4 ScreenSize;

/*
 * Normalized value representing the current quality level:
 * 0.0   0.333    0.666     1.0
 *  | Full | Medium | Lowest |
 */
float AdaptiveQuality;

/*
 * x: Current weather index.
 * y: Previous weather index.
 * z: Normalized weather transition.
 * w: Time of day in 24 hours.
 *
 * Weather index 0 means ENB could not capture weather information.
 */
float4 Weather;

/*
 * Represents normalized interpolators for each time of the day:
 *   x: Dawn.
 *   y: Sunrise.
 *   z: Day.
 *   w: Sunset.
 */
float4 TimeOfDay1;

/*
 * Continuation of TimeOfDay1:
 *   x: Dusk.
 *   y: Night.
 *   z: Unused.
 *   w: Unused.
 */
float4 TimeOfDay2;

/*
 * Normalized interpolator between night and day time.
 */
float ENightDayFactor;

/*
 * Whether in an exterior or interior:
 * 0                     1
 * | Exterior | Interior |
 */
float EInteriorFactor;

/*
 * Current camera field of view.
 */
float FieldOfView;

/*
 * Keyboard-controlled temporary variables.
 * Controlled by holding any number key and pressing PageUp or PageDown to
 * increase or decrease the value, respectively, which starts at 1.0.
 *   x: Key 0.
 *   y: Key 1.
 *   y: Key 2.
 *   y: Key 3.
 */
float4 tempF1;

/*
 * Continuation of tempF1.
 *   x: Key 5.
 *   y: Key 6.
 *   z: Key 7.
 *   w: Key 8.
 */
float4 tempF2;

/*
 * Continuation of tempF2.
 *   x: Key 9.
 *   y: Key 0.
 *   z: Unused.
 *   w: Unused.
 */
float4 tempF3;

/*
 * xy: Normalized mouse cursor position.
 * z: Whether the ENB menu is visible or not.
 * w: Value determining which mouse buttons are pressed:
 *    0: None.
 *    1: Left.
 *    2: Right.
 *    3: Left + right.
 *    4: Middle.
 *    5: Left + middle.
 *    6: Right + middle.
 *    7: Left + right + middle.
 */
float4 tempInfo1;

/*
 * xy: Mouse cursor position at the last time the left button was clicked.
 * zw: Mouse cursor position at the last time the right button was clicked.
 */
float4 tempInfo2;

//#endregion

//#region Samplers

SamplerState Point
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};

SamplerState Linear
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

//#endregion

//#region Functions

float2 GetScreenResolution()
{
	float2 res = ScreenSize.x;
	res.y *= ScreenSize.w;
	return res;
}

float2 GetPixelSize()
{
	float2 ps = ScreenSize.y;
	ps.y *= ScreenSize.z;
	return ps;
}

float GetAspectRatio()
{
	return ScreenSize.z;
}

float ApplyContrast(float x, float contrast)
{
	x = log2(x + Epsilon);
	x = ContrastLogMidpoint + (x - ContrastLogMidpoint) * contrast;
	return max(0.0, exp2(x) - Epsilon);
}

float3 BoxBlur1D(Texture2D tex, float2 uv, float2 dir, int samples)
{
	float halfSamples = samples * 0.5;
	uv -= dir * halfSamples;

	float3 color = tex.Sample(Linear, uv).rgb;

	[unroll]
	for (int i = 1; i < samples; ++i)
	{
		uv += dir;
		color += tex.Sample(Linear, uv).rgb;
	}

	color /= samples;
	return color;
}

float3 BoxBlur2D(Texture2D tex, float2 uv, float2 scale, int2 samples)
{
	float2 halfSamples = samples * 0.5;
	uv -= scale * halfSamples;

	float initX = uv.x;
	float3 color = 0.0;

	[unroll]
	for (int x = 0; x < samples.x; ++x)
	{
		[unroll]
		for (int y = 0; y < samples.y; ++y)
		{
			color += tex.Sample(Linear, uv).rgb;
			uv.x += scale.x;
		}

		uv.x = initX;
		uv.y += scale.y;
	}

	color.rgb /= samples.x * samples.y;
	return color.rgb;
}

float Gaussian1D(float x, float sigma)
{
	float o = sigma * sigma;

	return
		(1.0 / sqrt(DoublePi * o)) *
		exp(-((x * x) / (2.0 * o)));
}

float Gaussian2D(float2 i, float sigma)
{
	float o = sigma * sigma;

	return
		(1.0 / (DoublePi * o)) *
		exp(-((i.x * i.x + i.y * i.y) / (2.0 * o)));
}

float3 GaussianBlur1D(
	Texture2D tex,
	float2 uv,
	float2 dir,
	int samples,
	float sigma)
{
	float halfSamples = samples * 0.5;

	float4 color = 0.0;
	uv -= dir * halfSamples;

	[unroll]
	for (int i = 0; i < samples; ++i)
	{
		float weight = Gaussian1D(i - halfSamples, sigma);
		color += float4(tex.Sample(Linear, uv).rgb, 1.0) * weight;
		uv += dir;
	}

	color.rgb /= color.a;
	return color.rgb;
}

float3 GaussianBlur2D(
	Texture2D tex,
	float2 uv,
	float2 scale,
	int2 samples,
	float sigma)
{
	float2 halfSamples = samples * 0.5;
	float4 color = 0.0;

	uv -= scale * halfSamples;
	float initX = uv.x;

	[unroll]
	for (int x = 0; x < samples.x; ++x)
	{
		[unroll]
		for (int y = 0; y < samples.y; ++y)
		{
			float2 i = int2(x, y) - halfSamples;
			float weight = Gaussian2D(i, sigma);

			color += float4(tex.Sample(Linear, uv).rgb, 1.0) * weight;
			uv.x += scale.x;
		}

		uv.x = initX;
		uv.y += scale.y;
	}

	color.rgb /= color.a;
	return color.rgb;
}

//#endregion

//#region Shaders

void PostProcessVS(
	float3 v : POSITION,
	out float4 p : SV_POSITION,
	inout float2 uv : TEXCOORD)
{
	p = float4(v, 1.0);
}

/*
 * Simple texture write shader.
 */
float4 CopyPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD,
	uniform Texture2D tex,
	uniform SamplerState sp) : SV_TARGET
{
	return tex.Sample(sp, uv);
}

float4 GammaToLinearPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD,
	uniform Texture2D tex,
	uniform SamplerState sp) : SV_TARGET
{
	float4 color = tex.Sample(sp, uv);
	color.rgb = pow(abs(color.rgb), Gamma);
	return color;
}

float4 LinearToGammaPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD,
	uniform Texture2D tex,
	uniform SamplerState sp) : SV_TARGET
{
	float4 color = tex.Sample(sp, uv);
	color.rgb = pow(abs(color.rgb), GammaInv);
	return color;
}

//#endregion

#endif // Include guard.