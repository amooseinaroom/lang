#version 330

#define SMAA_GLSL_3
#define SMAA_PRESET_MEDIUM
#define SMAA_RT_METRICS metrics

#define SMAA_AREATEX_SELECT(sample)   sample.rg
#define SMAA_SEARCHTEX_SELECT(sample) sample.r

#define SMAA_INCLUDE_VS 0
#define SMAA_INCLUDE_PS 1

uniform vec4 metrics; // 1 / width, 1 / height, width, height