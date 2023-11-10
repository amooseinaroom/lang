
module gl;

import win32;

type HGLRC                u8 ref;
type HPBUFFERARB          u8 ref;
type HPBUFFEREXT          u8 ref;
type HGPUNV               u8 ref;
type PGPU_DEVICE          u8 ref;
type HVIDEOOUTPUTDEVICENV u8 ref;
type HVIDEOINPUTDEVICENV  u8 ref;
type HPVIDEODEV           u8 ref;

func wglGetProcAddress(name cstring) (address u8 ref)                     calling_convention "__stdcall" extern_binding("opengl32", true);
func wglCreateContext (device_context HDC) (gl_context HGLRC)             calling_convention "__stdcall" extern_binding("opengl32", true);
func wglDeleteContext ( gl_context HGLRC) (resukt u32)                    calling_convention "__stdcall" extern_binding("opengl32", true);
func wglMakeCurrent   (device_context HDC, gl_context HGLRC) (resukt u32) calling_convention "__stdcall" extern_binding("opengl32", true);
def WGL_WGLEXT_VERSION = 20211115;
def WGL_ARB_buffer_region = 1;
def WGL_FRONT_COLOR_BUFFER_BIT_ARB = 0x00000001;
def WGL_BACK_COLOR_BUFFER_BIT_ARB = 0x00000002;
def WGL_DEPTH_BUFFER_BIT_ARB = 0x00000004;
def WGL_STENCIL_BUFFER_BIT_ARB = 0x00000008;

func wglCreateBufferRegionARB_signature(hDC HDC, iLayerPlane s32, uType u32) (result HANDLE);
var global wglCreateBufferRegionARB wglCreateBufferRegionARB_signature;

func wglDeleteBufferRegionARB_signature(hRegion HANDLE);
var global wglDeleteBufferRegionARB wglDeleteBufferRegionARB_signature;

func wglSaveBufferRegionARB_signature(hRegion HANDLE, x s32, y s32, width s32, height s32) (result s32);
var global wglSaveBufferRegionARB wglSaveBufferRegionARB_signature;

func wglRestoreBufferRegionARB_signature(hRegion HANDLE, x s32, y s32, width s32, height s32, xSrc s32, ySrc s32) (result s32);
var global wglRestoreBufferRegionARB wglRestoreBufferRegionARB_signature;
def WGL_ARB_context_flush_control = 1;
def WGL_CONTEXT_RELEASE_BEHAVIOR_ARB = 0x2097;
def WGL_CONTEXT_RELEASE_BEHAVIOR_NONE_ARB = 0;
def WGL_CONTEXT_RELEASE_BEHAVIOR_FLUSH_ARB = 0x2098;
def WGL_ARB_create_context = 1;
def WGL_CONTEXT_DEBUG_BIT_ARB = 0x00000001;
def WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x00000002;
def WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
def WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092;
def WGL_CONTEXT_LAYER_PLANE_ARB = 0x2093;
def WGL_CONTEXT_FLAGS_ARB = 0x2094;

func wglCreateContextAttribsARB_signature(hDC HDC, hShareContext HGLRC, attribList s32 ref) (result HGLRC);
var global wglCreateContextAttribsARB wglCreateContextAttribsARB_signature;
def WGL_ARB_create_context_no_error = 1;
def WGL_CONTEXT_OPENGL_NO_ERROR_ARB = 0x31B3;
def WGL_ARB_create_context_profile = 1;
def WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126;
def WGL_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001;
def WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002;
def WGL_ARB_create_context_robustness = 1;
def WGL_CONTEXT_ROBUST_ACCESS_BIT_ARB = 0x00000004;
def WGL_LOSE_CONTEXT_ON_RESET_ARB = 0x8252;
def WGL_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB = 0x8256;
def WGL_NO_RESET_NOTIFICATION_ARB = 0x8261;
def WGL_ARB_extensions_string = 1;

func wglGetExtensionsStringARB_signature(hdc HDC) (result u8 ref);
var global wglGetExtensionsStringARB wglGetExtensionsStringARB_signature;
def WGL_ARB_framebuffer_sRGB = 1;
def WGL_FRAMEBUFFER_SRGB_CAPABLE_ARB = 0x20A9;
def WGL_ARB_make_current_read = 1;

func wglMakeContextCurrentARB_signature(hDrawDC HDC, hReadDC HDC, hglrc HGLRC) (result s32);
var global wglMakeContextCurrentARB wglMakeContextCurrentARB_signature;

func wglGetCurrentReadDCARB_signature() (result HDC);
var global wglGetCurrentReadDCARB wglGetCurrentReadDCARB_signature;
def WGL_ARB_multisample = 1;
def WGL_SAMPLE_BUFFERS_ARB = 0x2041;
def WGL_SAMPLES_ARB = 0x2042;
def WGL_ARB_pbuffer = 1;
def WGL_DRAW_TO_PBUFFER_ARB = 0x202D;
def WGL_MAX_PBUFFER_PIXELS_ARB = 0x202E;
def WGL_MAX_PBUFFER_WIDTH_ARB = 0x202F;
def WGL_MAX_PBUFFER_HEIGHT_ARB = 0x2030;
def WGL_PBUFFER_LARGEST_ARB = 0x2033;
def WGL_PBUFFER_WIDTH_ARB = 0x2034;
def WGL_PBUFFER_HEIGHT_ARB = 0x2035;
def WGL_PBUFFER_LOST_ARB = 0x2036;

func wglCreatePbufferARB_signature(hDC HDC, iPixelFormat s32, iWidth s32, iHeight s32, piAttribList s32 ref) (result HPBUFFERARB);
var global wglCreatePbufferARB wglCreatePbufferARB_signature;

func wglGetPbufferDCARB_signature(hPbuffer HPBUFFERARB) (result HDC);
var global wglGetPbufferDCARB wglGetPbufferDCARB_signature;

func wglReleasePbufferDCARB_signature(hPbuffer HPBUFFERARB, hDC HDC) (result s32);
var global wglReleasePbufferDCARB wglReleasePbufferDCARB_signature;

func wglDestroyPbufferARB_signature(hPbuffer HPBUFFERARB) (result s32);
var global wglDestroyPbufferARB wglDestroyPbufferARB_signature;

func wglQueryPbufferARB_signature(hPbuffer HPBUFFERARB, iAttribute s32, piValue s32 ref) (result s32);
var global wglQueryPbufferARB wglQueryPbufferARB_signature;
def WGL_ARB_pixel_format = 1;
def WGL_NUMBER_PIXEL_FORMATS_ARB = 0x2000;
def WGL_DRAW_TO_WINDOW_ARB = 0x2001;
def WGL_DRAW_TO_BITMAP_ARB = 0x2002;
def WGL_ACCELERATION_ARB = 0x2003;
def WGL_NEED_PALETTE_ARB = 0x2004;
def WGL_NEED_SYSTEM_PALETTE_ARB = 0x2005;
def WGL_SWAP_LAYER_BUFFERS_ARB = 0x2006;
def WGL_SWAP_METHOD_ARB = 0x2007;
def WGL_NUMBER_OVERLAYS_ARB = 0x2008;
def WGL_NUMBER_UNDERLAYS_ARB = 0x2009;
def WGL_TRANSPARENT_ARB = 0x200A;
def WGL_TRANSPARENT_RED_VALUE_ARB = 0x2037;
def WGL_TRANSPARENT_GREEN_VALUE_ARB = 0x2038;
def WGL_TRANSPARENT_BLUE_VALUE_ARB = 0x2039;
def WGL_TRANSPARENT_ALPHA_VALUE_ARB = 0x203A;
def WGL_TRANSPARENT_INDEX_VALUE_ARB = 0x203B;
def WGL_SHARE_DEPTH_ARB = 0x200C;
def WGL_SHARE_STENCIL_ARB = 0x200D;
def WGL_SHARE_ACCUM_ARB = 0x200E;
def WGL_SUPPORT_GDI_ARB = 0x200F;
def WGL_SUPPORT_OPENGL_ARB = 0x2010;
def WGL_DOUBLE_BUFFER_ARB = 0x2011;
def WGL_STEREO_ARB = 0x2012;
def WGL_PIXEL_TYPE_ARB = 0x2013;
def WGL_COLOR_BITS_ARB = 0x2014;
def WGL_RED_BITS_ARB = 0x2015;
def WGL_RED_SHIFT_ARB = 0x2016;
def WGL_GREEN_BITS_ARB = 0x2017;
def WGL_GREEN_SHIFT_ARB = 0x2018;
def WGL_BLUE_BITS_ARB = 0x2019;
def WGL_BLUE_SHIFT_ARB = 0x201A;
def WGL_ALPHA_BITS_ARB = 0x201B;
def WGL_ALPHA_SHIFT_ARB = 0x201C;
def WGL_ACCUM_BITS_ARB = 0x201D;
def WGL_ACCUM_RED_BITS_ARB = 0x201E;
def WGL_ACCUM_GREEN_BITS_ARB = 0x201F;
def WGL_ACCUM_BLUE_BITS_ARB = 0x2020;
def WGL_ACCUM_ALPHA_BITS_ARB = 0x2021;
def WGL_DEPTH_BITS_ARB = 0x2022;
def WGL_STENCIL_BITS_ARB = 0x2023;
def WGL_AUX_BUFFERS_ARB = 0x2024;
def WGL_NO_ACCELERATION_ARB = 0x2025;
def WGL_GENERIC_ACCELERATION_ARB = 0x2026;
def WGL_FULL_ACCELERATION_ARB = 0x2027;
def WGL_SWAP_EXCHANGE_ARB = 0x2028;
def WGL_SWAP_COPY_ARB = 0x2029;
def WGL_SWAP_UNDEFINED_ARB = 0x202A;
def WGL_TYPE_RGBA_ARB = 0x202B;
def WGL_TYPE_COLORINDEX_ARB = 0x202C;

func wglGetPixelFormatAttribivARB_signature(hdc HDC, iPixelFormat s32, iLayerPlane s32, nAttributes u32, piAttributes s32 ref, piValues s32 ref) (result s32);
var global wglGetPixelFormatAttribivARB wglGetPixelFormatAttribivARB_signature;

func wglGetPixelFormatAttribfvARB_signature(hdc HDC, iPixelFormat s32, iLayerPlane s32, nAttributes u32, piAttributes s32 ref, pfValues f32 ref) (result s32);
var global wglGetPixelFormatAttribfvARB wglGetPixelFormatAttribfvARB_signature;

func wglChoosePixelFormatARB_signature(hdc HDC, piAttribIList s32 ref, pfAttribFList f32 ref, nMaxFormats u32, piFormats s32 ref, nNumFormats u32 ref) (result s32);
var global wglChoosePixelFormatARB wglChoosePixelFormatARB_signature;
def WGL_ARB_pixel_format_float = 1;
def WGL_TYPE_RGBA_FLOAT_ARB = 0x21A0;
def WGL_ARB_render_texture = 1;
def WGL_BIND_TO_TEXTURE_RGB_ARB = 0x2070;
def WGL_BIND_TO_TEXTURE_RGBA_ARB = 0x2071;
def WGL_TEXTURE_FORMAT_ARB = 0x2072;
def WGL_TEXTURE_TARGET_ARB = 0x2073;
def WGL_MIPMAP_TEXTURE_ARB = 0x2074;
def WGL_TEXTURE_RGB_ARB = 0x2075;
def WGL_TEXTURE_RGBA_ARB = 0x2076;
def WGL_NO_TEXTURE_ARB = 0x2077;
def WGL_TEXTURE_CUBE_MAP_ARB = 0x2078;
def WGL_TEXTURE_1D_ARB = 0x2079;
def WGL_TEXTURE_2D_ARB = 0x207A;
def WGL_MIPMAP_LEVEL_ARB = 0x207B;
def WGL_CUBE_MAP_FACE_ARB = 0x207C;
def WGL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB = 0x207D;
def WGL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB = 0x207E;
def WGL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB = 0x207F;
def WGL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB = 0x2080;
def WGL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB = 0x2081;
def WGL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB = 0x2082;
def WGL_FRONT_LEFT_ARB = 0x2083;
def WGL_FRONT_RIGHT_ARB = 0x2084;
def WGL_BACK_LEFT_ARB = 0x2085;
def WGL_BACK_RIGHT_ARB = 0x2086;
def WGL_AUX0_ARB = 0x2087;
def WGL_AUX1_ARB = 0x2088;
def WGL_AUX2_ARB = 0x2089;
def WGL_AUX3_ARB = 0x208A;
def WGL_AUX4_ARB = 0x208B;
def WGL_AUX5_ARB = 0x208C;
def WGL_AUX6_ARB = 0x208D;
def WGL_AUX7_ARB = 0x208E;
def WGL_AUX8_ARB = 0x208F;
def WGL_AUX9_ARB = 0x2090;

func wglBindTexImageARB_signature(hPbuffer HPBUFFERARB, iBuffer s32) (result s32);
var global wglBindTexImageARB wglBindTexImageARB_signature;

func wglReleaseTexImageARB_signature(hPbuffer HPBUFFERARB, iBuffer s32) (result s32);
var global wglReleaseTexImageARB wglReleaseTexImageARB_signature;

func wglSetPbufferAttribARB_signature(hPbuffer HPBUFFERARB, piAttribList s32 ref) (result s32);
var global wglSetPbufferAttribARB wglSetPbufferAttribARB_signature;
def WGL_ARB_robustness_application_isolation = 1;
def WGL_CONTEXT_RESET_ISOLATION_BIT_ARB = 0x00000008;
def WGL_ARB_robustness_share_group_isolation = 1;
def WGL_3DFX_multisample = 1;
def WGL_SAMPLE_BUFFERS_3DFX = 0x2060;
def WGL_SAMPLES_3DFX = 0x2061;
def WGL_3DL_stereo_control = 1;
def WGL_STEREO_EMITTER_ENABLE_3DL = 0x2055;
def WGL_STEREO_EMITTER_DISABLE_3DL = 0x2056;
def WGL_STEREO_POLARITY_NORMAL_3DL = 0x2057;
def WGL_STEREO_POLARITY_INVERT_3DL = 0x2058;

func wglSetStereoEmitterState3DL_signature(hDC HDC, uState u32) (result s32);
var global wglSetStereoEmitterState3DL wglSetStereoEmitterState3DL_signature;
def WGL_AMD_gpu_association = 1;
def WGL_GPU_VENDOR_AMD = 0x1F00;
def WGL_GPU_RENDERER_STRING_AMD = 0x1F01;
def WGL_GPU_OPENGL_VERSION_STRING_AMD = 0x1F02;
def WGL_GPU_FASTEST_TARGET_GPUS_AMD = 0x21A2;
def WGL_GPU_RAM_AMD = 0x21A3;
def WGL_GPU_CLOCK_AMD = 0x21A4;
def WGL_GPU_NUM_PIPES_AMD = 0x21A5;
def WGL_GPU_NUM_SIMD_AMD = 0x21A6;
def WGL_GPU_NUM_RB_AMD = 0x21A7;
def WGL_GPU_NUM_SPI_AMD = 0x21A8;

func wglGetGPUIDsAMD_signature(maxCount u32, ids u32 ref) (result u32);
var global wglGetGPUIDsAMD wglGetGPUIDsAMD_signature;

func wglGetGPUInfoAMD_signature(id u32, property s32, dataType GLenum, size u32, data u8 ref) (result s32);
var global wglGetGPUInfoAMD wglGetGPUInfoAMD_signature;

func wglGetContextGPUIDAMD_signature(hglrc HGLRC) (result u32);
var global wglGetContextGPUIDAMD wglGetContextGPUIDAMD_signature;

func wglCreateAssociatedContextAMD_signature(id u32) (result HGLRC);
var global wglCreateAssociatedContextAMD wglCreateAssociatedContextAMD_signature;

func wglCreateAssociatedContextAttribsAMD_signature(id u32, hShareContext HGLRC, attribList s32 ref) (result HGLRC);
var global wglCreateAssociatedContextAttribsAMD wglCreateAssociatedContextAttribsAMD_signature;

func wglDeleteAssociatedContextAMD_signature(hglrc HGLRC) (result s32);
var global wglDeleteAssociatedContextAMD wglDeleteAssociatedContextAMD_signature;

func wglMakeAssociatedContextCurrentAMD_signature(hglrc HGLRC) (result s32);
var global wglMakeAssociatedContextCurrentAMD wglMakeAssociatedContextCurrentAMD_signature;

func wglGetCurrentAssociatedContextAMD_signature() (result HGLRC);
var global wglGetCurrentAssociatedContextAMD wglGetCurrentAssociatedContextAMD_signature;

func wglBlitContextFramebufferAMD_signature(dstCtx HGLRC, srcX0 GLint, srcY0 GLint, srcX1 GLint, srcY1 GLint, dstX0 GLint, dstY0 GLint, dstX1 GLint, dstY1 GLint, mask GLbitfield, filter GLenum);
var global wglBlitContextFramebufferAMD wglBlitContextFramebufferAMD_signature;
def WGL_ATI_pixel_format_float = 1;
def WGL_TYPE_RGBA_FLOAT_ATI = 0x21A0;
def WGL_ATI_render_texture_rectangle = 1;
def WGL_TEXTURE_RECTANGLE_ATI = 0x21A5;
def WGL_EXT_colorspace = 1;
def WGL_COLORSPACE_EXT = 0x309D;
def WGL_COLORSPACE_SRGB_EXT = 0x3089;
def WGL_COLORSPACE_LINEAR_EXT = 0x308A;
def WGL_EXT_create_context_es2_profile = 1;
def WGL_CONTEXT_ES2_PROFILE_BIT_EXT = 0x00000004;
def WGL_EXT_create_context_es_profile = 1;
def WGL_CONTEXT_ES_PROFILE_BIT_EXT = 0x00000004;
def WGL_EXT_depth_float = 1;
def WGL_DEPTH_FLOAT_EXT = 0x2040;
def WGL_EXT_display_color_table = 1;

func wglCreateDisplayColorTableEXT_signature(id GLushort) (result GLboolean);
var global wglCreateDisplayColorTableEXT wglCreateDisplayColorTableEXT_signature;

func wglLoadDisplayColorTableEXT_signature(table GLushort ref, length GLuint) (result GLboolean);
var global wglLoadDisplayColorTableEXT wglLoadDisplayColorTableEXT_signature;

func wglBindDisplayColorTableEXT_signature(id GLushort) (result GLboolean);
var global wglBindDisplayColorTableEXT wglBindDisplayColorTableEXT_signature;

func wglDestroyDisplayColorTableEXT_signature(id GLushort);
var global wglDestroyDisplayColorTableEXT wglDestroyDisplayColorTableEXT_signature;
def WGL_EXT_extensions_string = 1;

func wglGetExtensionsStringEXT_signature() (result u8 ref);
var global wglGetExtensionsStringEXT wglGetExtensionsStringEXT_signature;
def WGL_EXT_framebuffer_sRGB = 1;
def WGL_FRAMEBUFFER_SRGB_CAPABLE_EXT = 0x20A9;
def WGL_EXT_make_current_read = 1;

func wglMakeContextCurrentEXT_signature(hDrawDC HDC, hReadDC HDC, hglrc HGLRC) (result s32);
var global wglMakeContextCurrentEXT wglMakeContextCurrentEXT_signature;

func wglGetCurrentReadDCEXT_signature() (result HDC);
var global wglGetCurrentReadDCEXT wglGetCurrentReadDCEXT_signature;
def WGL_EXT_multisample = 1;
def WGL_SAMPLE_BUFFERS_EXT = 0x2041;
def WGL_SAMPLES_EXT = 0x2042;
def WGL_EXT_pbuffer = 1;
def WGL_DRAW_TO_PBUFFER_EXT = 0x202D;
def WGL_MAX_PBUFFER_PIXELS_EXT = 0x202E;
def WGL_MAX_PBUFFER_WIDTH_EXT = 0x202F;
def WGL_MAX_PBUFFER_HEIGHT_EXT = 0x2030;
def WGL_OPTIMAL_PBUFFER_WIDTH_EXT = 0x2031;
def WGL_OPTIMAL_PBUFFER_HEIGHT_EXT = 0x2032;
def WGL_PBUFFER_LARGEST_EXT = 0x2033;
def WGL_PBUFFER_WIDTH_EXT = 0x2034;
def WGL_PBUFFER_HEIGHT_EXT = 0x2035;

func wglCreatePbufferEXT_signature(hDC HDC, iPixelFormat s32, iWidth s32, iHeight s32, piAttribList s32 ref) (result HPBUFFEREXT);
var global wglCreatePbufferEXT wglCreatePbufferEXT_signature;

func wglGetPbufferDCEXT_signature(hPbuffer HPBUFFEREXT) (result HDC);
var global wglGetPbufferDCEXT wglGetPbufferDCEXT_signature;

func wglReleasePbufferDCEXT_signature(hPbuffer HPBUFFEREXT, hDC HDC) (result s32);
var global wglReleasePbufferDCEXT wglReleasePbufferDCEXT_signature;

func wglDestroyPbufferEXT_signature(hPbuffer HPBUFFEREXT) (result s32);
var global wglDestroyPbufferEXT wglDestroyPbufferEXT_signature;

func wglQueryPbufferEXT_signature(hPbuffer HPBUFFEREXT, iAttribute s32, piValue s32 ref) (result s32);
var global wglQueryPbufferEXT wglQueryPbufferEXT_signature;
def WGL_EXT_pixel_format = 1;
def WGL_NUMBER_PIXEL_FORMATS_EXT = 0x2000;
def WGL_DRAW_TO_WINDOW_EXT = 0x2001;
def WGL_DRAW_TO_BITMAP_EXT = 0x2002;
def WGL_ACCELERATION_EXT = 0x2003;
def WGL_NEED_PALETTE_EXT = 0x2004;
def WGL_NEED_SYSTEM_PALETTE_EXT = 0x2005;
def WGL_SWAP_LAYER_BUFFERS_EXT = 0x2006;
def WGL_SWAP_METHOD_EXT = 0x2007;
def WGL_NUMBER_OVERLAYS_EXT = 0x2008;
def WGL_NUMBER_UNDERLAYS_EXT = 0x2009;
def WGL_TRANSPARENT_EXT = 0x200A;
def WGL_TRANSPARENT_VALUE_EXT = 0x200B;
def WGL_SHARE_DEPTH_EXT = 0x200C;
def WGL_SHARE_STENCIL_EXT = 0x200D;
def WGL_SHARE_ACCUM_EXT = 0x200E;
def WGL_SUPPORT_GDI_EXT = 0x200F;
def WGL_SUPPORT_OPENGL_EXT = 0x2010;
def WGL_DOUBLE_BUFFER_EXT = 0x2011;
def WGL_STEREO_EXT = 0x2012;
def WGL_PIXEL_TYPE_EXT = 0x2013;
def WGL_COLOR_BITS_EXT = 0x2014;
def WGL_RED_BITS_EXT = 0x2015;
def WGL_RED_SHIFT_EXT = 0x2016;
def WGL_GREEN_BITS_EXT = 0x2017;
def WGL_GREEN_SHIFT_EXT = 0x2018;
def WGL_BLUE_BITS_EXT = 0x2019;
def WGL_BLUE_SHIFT_EXT = 0x201A;
def WGL_ALPHA_BITS_EXT = 0x201B;
def WGL_ALPHA_SHIFT_EXT = 0x201C;
def WGL_ACCUM_BITS_EXT = 0x201D;
def WGL_ACCUM_RED_BITS_EXT = 0x201E;
def WGL_ACCUM_GREEN_BITS_EXT = 0x201F;
def WGL_ACCUM_BLUE_BITS_EXT = 0x2020;
def WGL_ACCUM_ALPHA_BITS_EXT = 0x2021;
def WGL_DEPTH_BITS_EXT = 0x2022;
def WGL_STENCIL_BITS_EXT = 0x2023;
def WGL_AUX_BUFFERS_EXT = 0x2024;
def WGL_NO_ACCELERATION_EXT = 0x2025;
def WGL_GENERIC_ACCELERATION_EXT = 0x2026;
def WGL_FULL_ACCELERATION_EXT = 0x2027;
def WGL_SWAP_EXCHANGE_EXT = 0x2028;
def WGL_SWAP_COPY_EXT = 0x2029;
def WGL_SWAP_UNDEFINED_EXT = 0x202A;
def WGL_TYPE_RGBA_EXT = 0x202B;
def WGL_TYPE_COLORINDEX_EXT = 0x202C;

func wglGetPixelFormatAttribivEXT_signature(hdc HDC, iPixelFormat s32, iLayerPlane s32, nAttributes u32, piAttributes s32 ref, piValues s32 ref) (result s32);
var global wglGetPixelFormatAttribivEXT wglGetPixelFormatAttribivEXT_signature;

func wglGetPixelFormatAttribfvEXT_signature(hdc HDC, iPixelFormat s32, iLayerPlane s32, nAttributes u32, piAttributes s32 ref, pfValues f32 ref) (result s32);
var global wglGetPixelFormatAttribfvEXT wglGetPixelFormatAttribfvEXT_signature;

func wglChoosePixelFormatEXT_signature(hdc HDC, piAttribIList s32 ref, pfAttribFList f32 ref, nMaxFormats u32, piFormats s32 ref, nNumFormats u32 ref) (result s32);
var global wglChoosePixelFormatEXT wglChoosePixelFormatEXT_signature;
def WGL_EXT_pixel_format_packed_float = 1;
def WGL_TYPE_RGBA_UNSIGNED_FLOAT_EXT = 0x20A8;
def WGL_EXT_swap_control = 1;

func wglSwapIntervalEXT_signature(interval s32) (result s32);
var global wglSwapIntervalEXT wglSwapIntervalEXT_signature;

func wglGetSwapIntervalEXT_signature() (result s32);
var global wglGetSwapIntervalEXT wglGetSwapIntervalEXT_signature;
def WGL_EXT_swap_control_tear = 1;
def WGL_I3D_digital_video_control = 1;
def WGL_DIGITAL_VIDEO_CURSOR_ALPHA_FRAMEBUFFER_I3D = 0x2050;
def WGL_DIGITAL_VIDEO_CURSOR_ALPHA_VALUE_I3D = 0x2051;
def WGL_DIGITAL_VIDEO_CURSOR_INCLUDED_I3D = 0x2052;
def WGL_DIGITAL_VIDEO_GAMMA_CORRECTED_I3D = 0x2053;

func wglGetDigitalVideoParametersI3D_signature(hDC HDC, iAttribute s32, piValue s32 ref) (result s32);
var global wglGetDigitalVideoParametersI3D wglGetDigitalVideoParametersI3D_signature;

func wglSetDigitalVideoParametersI3D_signature(hDC HDC, iAttribute s32, piValue s32 ref) (result s32);
var global wglSetDigitalVideoParametersI3D wglSetDigitalVideoParametersI3D_signature;
def WGL_I3D_gamma = 1;
def WGL_GAMMA_TABLE_SIZE_I3D = 0x204E;
def WGL_GAMMA_EXCLUDE_DESKTOP_I3D = 0x204F;

func wglGetGammaTableParametersI3D_signature(hDC HDC, iAttribute s32, piValue s32 ref) (result s32);
var global wglGetGammaTableParametersI3D wglGetGammaTableParametersI3D_signature;

func wglSetGammaTableParametersI3D_signature(hDC HDC, iAttribute s32, piValue s32 ref) (result s32);
var global wglSetGammaTableParametersI3D wglSetGammaTableParametersI3D_signature;

func wglGetGammaTableI3D_signature(hDC HDC, iEntries s32, puRed u16 ref, puGreen u16 ref, puBlue u16 ref) (result s32);
var global wglGetGammaTableI3D wglGetGammaTableI3D_signature;

func wglSetGammaTableI3D_signature(hDC HDC, iEntries s32, puRed u16 ref, puGreen u16 ref, puBlue u16 ref) (result s32);
var global wglSetGammaTableI3D wglSetGammaTableI3D_signature;
def WGL_I3D_genlock = 1;
def WGL_GENLOCK_SOURCE_MULTIVIEW_I3D = 0x2044;
def WGL_GENLOCK_SOURCE_EXTERNAL_SYNC_I3D = 0x2045;
def WGL_GENLOCK_SOURCE_EXTERNAL_FIELD_I3D = 0x2046;
def WGL_GENLOCK_SOURCE_EXTERNAL_TTL_I3D = 0x2047;
def WGL_GENLOCK_SOURCE_DIGITAL_SYNC_I3D = 0x2048;
def WGL_GENLOCK_SOURCE_DIGITAL_FIELD_I3D = 0x2049;
def WGL_GENLOCK_SOURCE_EDGE_FALLING_I3D = 0x204A;
def WGL_GENLOCK_SOURCE_EDGE_RISING_I3D = 0x204B;
def WGL_GENLOCK_SOURCE_EDGE_BOTH_I3D = 0x204C;

func wglEnableGenlockI3D_signature(hDC HDC) (result s32);
var global wglEnableGenlockI3D wglEnableGenlockI3D_signature;

func wglDisableGenlockI3D_signature(hDC HDC) (result s32);
var global wglDisableGenlockI3D wglDisableGenlockI3D_signature;

func wglIsEnabledGenlockI3D_signature(hDC HDC, pFlag s32 ref) (result s32);
var global wglIsEnabledGenlockI3D wglIsEnabledGenlockI3D_signature;

func wglGenlockSourceI3D_signature(hDC HDC, uSource u32) (result s32);
var global wglGenlockSourceI3D wglGenlockSourceI3D_signature;

func wglGetGenlockSourceI3D_signature(hDC HDC, uSource u32 ref) (result s32);
var global wglGetGenlockSourceI3D wglGetGenlockSourceI3D_signature;

func wglGenlockSourceEdgeI3D_signature(hDC HDC, uEdge u32) (result s32);
var global wglGenlockSourceEdgeI3D wglGenlockSourceEdgeI3D_signature;

func wglGetGenlockSourceEdgeI3D_signature(hDC HDC, uEdge u32 ref) (result s32);
var global wglGetGenlockSourceEdgeI3D wglGetGenlockSourceEdgeI3D_signature;

func wglGenlockSampleRateI3D_signature(hDC HDC, uRate u32) (result s32);
var global wglGenlockSampleRateI3D wglGenlockSampleRateI3D_signature;

func wglGetGenlockSampleRateI3D_signature(hDC HDC, uRate u32 ref) (result s32);
var global wglGetGenlockSampleRateI3D wglGetGenlockSampleRateI3D_signature;

func wglGenlockSourceDelayI3D_signature(hDC HDC, uDelay u32) (result s32);
var global wglGenlockSourceDelayI3D wglGenlockSourceDelayI3D_signature;

func wglGetGenlockSourceDelayI3D_signature(hDC HDC, uDelay u32 ref) (result s32);
var global wglGetGenlockSourceDelayI3D wglGetGenlockSourceDelayI3D_signature;

func wglQueryGenlockMaxSourceDelayI3D_signature(hDC HDC, uMaxLineDelay u32 ref, uMaxPixelDelay u32 ref) (result s32);
var global wglQueryGenlockMaxSourceDelayI3D wglQueryGenlockMaxSourceDelayI3D_signature;
def WGL_I3D_image_buffer = 1;
def WGL_IMAGE_BUFFER_MIN_ACCESS_I3D = 0x00000001;
def WGL_IMAGE_BUFFER_LOCK_I3D = 0x00000002;

func wglCreateImageBufferI3D_signature(hDC HDC, dwSize u32, uFlags u32) (result u8 ref);
var global wglCreateImageBufferI3D wglCreateImageBufferI3D_signature;

func wglDestroyImageBufferI3D_signature(hDC HDC, pAddress u8 ref) (result s32);
var global wglDestroyImageBufferI3D wglDestroyImageBufferI3D_signature;

func wglAssociateImageBufferEventsI3D_signature(hDC HDC, pEvent HANDLE ref, pAddress u8 ref ref, pSize u32 ref, count u32) (result s32);
var global wglAssociateImageBufferEventsI3D wglAssociateImageBufferEventsI3D_signature;

func wglReleaseImageBufferEventsI3D_signature(hDC HDC, pAddress u8 ref ref, count u32) (result s32);
var global wglReleaseImageBufferEventsI3D wglReleaseImageBufferEventsI3D_signature;
def WGL_I3D_swap_frame_lock = 1;

func wglEnableFrameLockI3D_signature() (result s32);
var global wglEnableFrameLockI3D wglEnableFrameLockI3D_signature;

func wglDisableFrameLockI3D_signature() (result s32);
var global wglDisableFrameLockI3D wglDisableFrameLockI3D_signature;

func wglIsEnabledFrameLockI3D_signature(pFlag s32 ref) (result s32);
var global wglIsEnabledFrameLockI3D wglIsEnabledFrameLockI3D_signature;

func wglQueryFrameLockMasterI3D_signature(pFlag s32 ref) (result s32);
var global wglQueryFrameLockMasterI3D wglQueryFrameLockMasterI3D_signature;
def WGL_I3D_swap_frame_usage = 1;

func wglGetFrameUsageI3D_signature(pUsage f32 ref) (result s32);
var global wglGetFrameUsageI3D wglGetFrameUsageI3D_signature;

func wglBeginFrameTrackingI3D_signature() (result s32);
var global wglBeginFrameTrackingI3D wglBeginFrameTrackingI3D_signature;

func wglEndFrameTrackingI3D_signature() (result s32);
var global wglEndFrameTrackingI3D wglEndFrameTrackingI3D_signature;

func wglQueryFrameTrackingI3D_signature(pFrameCount u32 ref, pMissedFrames u32 ref, pLastMissedUsage f32 ref) (result s32);
var global wglQueryFrameTrackingI3D wglQueryFrameTrackingI3D_signature;
def WGL_NV_DX_interop = 1;
def WGL_ACCESS_READ_ONLY_NV = 0x00000000;
def WGL_ACCESS_READ_WRITE_NV = 0x00000001;
def WGL_ACCESS_WRITE_DISCARD_NV = 0x00000002;

func wglDXSetResourceShareHandleNV_signature(dxObject u8 ref, shareHandle HANDLE) (result s32);
var global wglDXSetResourceShareHandleNV wglDXSetResourceShareHandleNV_signature;

func wglDXOpenDeviceNV_signature(dxDevice u8 ref) (result HANDLE);
var global wglDXOpenDeviceNV wglDXOpenDeviceNV_signature;

func wglDXCloseDeviceNV_signature(hDevice HANDLE) (result s32);
var global wglDXCloseDeviceNV wglDXCloseDeviceNV_signature;

func wglDXRegisterObjectNV_signature(hDevice HANDLE, dxObject u8 ref, name GLuint, type GLenum, access GLenum) (result HANDLE);
var global wglDXRegisterObjectNV wglDXRegisterObjectNV_signature;

func wglDXUnregisterObjectNV_signature(hDevice HANDLE, hObject HANDLE) (result s32);
var global wglDXUnregisterObjectNV wglDXUnregisterObjectNV_signature;

func wglDXObjectAccessNV_signature(hObject HANDLE, access GLenum) (result s32);
var global wglDXObjectAccessNV wglDXObjectAccessNV_signature;

func wglDXLockObjectsNV_signature(hDevice HANDLE, count GLint, hObjects HANDLE ref) (result s32);
var global wglDXLockObjectsNV wglDXLockObjectsNV_signature;

func wglDXUnlockObjectsNV_signature(hDevice HANDLE, count GLint, hObjects HANDLE ref) (result s32);
var global wglDXUnlockObjectsNV wglDXUnlockObjectsNV_signature;
def WGL_NV_DX_interop2 = 1;
def WGL_NV_copy_image = 1;

func wglCopyImageSubDataNV_signature(hSrcRC HGLRC, srcName GLuint, srcTarget GLenum, srcLevel GLint, srcX GLint, srcY GLint, srcZ GLint, hDstRC HGLRC, dstName GLuint, dstTarget GLenum, dstLevel GLint, dstX GLint, dstY GLint, dstZ GLint, width GLsizei, height GLsizei, depth GLsizei) (result s32);
var global wglCopyImageSubDataNV wglCopyImageSubDataNV_signature;
def WGL_NV_delay_before_swap = 1;

func wglDelayBeforeSwapNV_signature(hDC HDC, seconds GLfloat) (result s32);
var global wglDelayBeforeSwapNV wglDelayBeforeSwapNV_signature;
def WGL_NV_float_buffer = 1;
def WGL_FLOAT_COMPONENTS_NV = 0x20B0;
def WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV = 0x20B1;
def WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV = 0x20B2;
def WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV = 0x20B3;
def WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV = 0x20B4;
def WGL_TEXTURE_FLOAT_R_NV = 0x20B5;
def WGL_TEXTURE_FLOAT_RG_NV = 0x20B6;
def WGL_TEXTURE_FLOAT_RGB_NV = 0x20B7;
def WGL_TEXTURE_FLOAT_RGBA_NV = 0x20B8;
def WGL_NV_gpu_affinity = 1;

func wglEnumGpusNV_signature(iGpuIndex u32, phGpu HGPUNV ref) (result s32);
var global wglEnumGpusNV wglEnumGpusNV_signature;

func wglEnumGpuDevicesNV_signature(hGpu HGPUNV, iDeviceIndex u32, lpGpuDevice PGPU_DEVICE) (result s32);
var global wglEnumGpuDevicesNV wglEnumGpuDevicesNV_signature;

func wglCreateAffinityDCNV_signature(phGpuList HGPUNV ref) (result HDC);
var global wglCreateAffinityDCNV wglCreateAffinityDCNV_signature;

func wglEnumGpusFromAffinityDCNV_signature(hAffinityDC HDC, iGpuIndex u32, hGpu HGPUNV ref) (result s32);
var global wglEnumGpusFromAffinityDCNV wglEnumGpusFromAffinityDCNV_signature;

func wglDeleteDCNV_signature(hdc HDC) (result s32);
var global wglDeleteDCNV wglDeleteDCNV_signature;
def WGL_NV_multigpu_context = 1;
def WGL_CONTEXT_MULTIGPU_ATTRIB_NV = 0x20AA;
def WGL_CONTEXT_MULTIGPU_ATTRIB_SINGLE_NV = 0x20AB;
def WGL_CONTEXT_MULTIGPU_ATTRIB_AFR_NV = 0x20AC;
def WGL_CONTEXT_MULTIGPU_ATTRIB_MULTICAST_NV = 0x20AD;
def WGL_CONTEXT_MULTIGPU_ATTRIB_MULTI_DISPLAY_MULTICAST_NV = 0x20AE;
def WGL_NV_multisample_coverage = 1;
def WGL_COVERAGE_SAMPLES_NV = 0x2042;
def WGL_COLOR_SAMPLES_NV = 0x20B9;
def WGL_NV_present_video = 1;
def WGL_NUM_VIDEO_SLOTS_NV = 0x20F0;

func wglEnumerateVideoDevicesNV_signature(hDc HDC, phDeviceList HVIDEOOUTPUTDEVICENV ref) (result s32);
var global wglEnumerateVideoDevicesNV wglEnumerateVideoDevicesNV_signature;

func wglBindVideoDeviceNV_signature(hDc HDC, uVideoSlot u32, hVideoDevice HVIDEOOUTPUTDEVICENV, piAttribList s32 ref) (result s32);
var global wglBindVideoDeviceNV wglBindVideoDeviceNV_signature;

func wglQueryCurrentContextNV_signature(iAttribute s32, piValue s32 ref) (result s32);
var global wglQueryCurrentContextNV wglQueryCurrentContextNV_signature;
def WGL_NV_render_depth_texture = 1;
def WGL_BIND_TO_TEXTURE_DEPTH_NV = 0x20A3;
def WGL_BIND_TO_TEXTURE_RECTANGLE_DEPTH_NV = 0x20A4;
def WGL_DEPTH_TEXTURE_FORMAT_NV = 0x20A5;
def WGL_TEXTURE_DEPTH_COMPONENT_NV = 0x20A6;
def WGL_DEPTH_COMPONENT_NV = 0x20A7;
def WGL_NV_render_texture_rectangle = 1;
def WGL_BIND_TO_TEXTURE_RECTANGLE_RGB_NV = 0x20A0;
def WGL_BIND_TO_TEXTURE_RECTANGLE_RGBA_NV = 0x20A1;
def WGL_TEXTURE_RECTANGLE_NV = 0x20A2;
def WGL_NV_swap_group = 1;

func wglJoinSwapGroupNV_signature(hDC HDC, group GLuint) (result s32);
var global wglJoinSwapGroupNV wglJoinSwapGroupNV_signature;

func wglBindSwapBarrierNV_signature(group GLuint, barrier GLuint) (result s32);
var global wglBindSwapBarrierNV wglBindSwapBarrierNV_signature;

func wglQuerySwapGroupNV_signature(hDC HDC, group GLuint ref, barrier GLuint ref) (result s32);
var global wglQuerySwapGroupNV wglQuerySwapGroupNV_signature;

func wglQueryMaxSwapGroupsNV_signature(hDC HDC, maxGroups GLuint ref, maxBarriers GLuint ref) (result s32);
var global wglQueryMaxSwapGroupsNV wglQueryMaxSwapGroupsNV_signature;

func wglQueryFrameCountNV_signature(hDC HDC, count GLuint ref) (result s32);
var global wglQueryFrameCountNV wglQueryFrameCountNV_signature;

func wglResetFrameCountNV_signature(hDC HDC) (result s32);
var global wglResetFrameCountNV wglResetFrameCountNV_signature;
def WGL_NV_vertex_array_range = 1;

func wglAllocateMemoryNV_signature(size GLsizei, readfreq GLfloat, writefreq GLfloat, priority GLfloat) (result u8 ref);
var global wglAllocateMemoryNV wglAllocateMemoryNV_signature;

func wglFreeMemoryNV_signature(pointer u8 ref);
var global wglFreeMemoryNV wglFreeMemoryNV_signature;
def WGL_NV_video_capture = 1;
def WGL_UNIQUE_ID_NV = 0x20CE;
def WGL_NUM_VIDEO_CAPTURE_SLOTS_NV = 0x20CF;

func wglBindVideoCaptureDeviceNV_signature(uVideoSlot u32, hDevice HVIDEOINPUTDEVICENV) (result s32);
var global wglBindVideoCaptureDeviceNV wglBindVideoCaptureDeviceNV_signature;

func wglEnumerateVideoCaptureDevicesNV_signature(hDc HDC, phDeviceList HVIDEOINPUTDEVICENV ref) (result u32);
var global wglEnumerateVideoCaptureDevicesNV wglEnumerateVideoCaptureDevicesNV_signature;

func wglLockVideoCaptureDeviceNV_signature(hDc HDC, hDevice HVIDEOINPUTDEVICENV) (result s32);
var global wglLockVideoCaptureDeviceNV wglLockVideoCaptureDeviceNV_signature;

func wglQueryVideoCaptureDeviceNV_signature(hDc HDC, hDevice HVIDEOINPUTDEVICENV, iAttribute s32, piValue s32 ref) (result s32);
var global wglQueryVideoCaptureDeviceNV wglQueryVideoCaptureDeviceNV_signature;

func wglReleaseVideoCaptureDeviceNV_signature(hDc HDC, hDevice HVIDEOINPUTDEVICENV) (result s32);
var global wglReleaseVideoCaptureDeviceNV wglReleaseVideoCaptureDeviceNV_signature;
def WGL_NV_video_output = 1;
def WGL_BIND_TO_VIDEO_RGB_NV = 0x20C0;
def WGL_BIND_TO_VIDEO_RGBA_NV = 0x20C1;
def WGL_BIND_TO_VIDEO_RGB_AND_DEPTH_NV = 0x20C2;
def WGL_VIDEO_OUT_COLOR_NV = 0x20C3;
def WGL_VIDEO_OUT_ALPHA_NV = 0x20C4;
def WGL_VIDEO_OUT_DEPTH_NV = 0x20C5;
def WGL_VIDEO_OUT_COLOR_AND_ALPHA_NV = 0x20C6;
def WGL_VIDEO_OUT_COLOR_AND_DEPTH_NV = 0x20C7;
def WGL_VIDEO_OUT_FRAME = 0x20C8;
def WGL_VIDEO_OUT_FIELD_1 = 0x20C9;
def WGL_VIDEO_OUT_FIELD_2 = 0x20CA;
def WGL_VIDEO_OUT_STACKED_FIELDS_1_2 = 0x20CB;
def WGL_VIDEO_OUT_STACKED_FIELDS_2_1 = 0x20CC;

func wglGetVideoDeviceNV_signature(hDC HDC, numDevices s32, hVideoDevice HPVIDEODEV ref) (result s32);
var global wglGetVideoDeviceNV wglGetVideoDeviceNV_signature;

func wglReleaseVideoDeviceNV_signature(hVideoDevice HPVIDEODEV) (result s32);
var global wglReleaseVideoDeviceNV wglReleaseVideoDeviceNV_signature;

func wglBindVideoImageNV_signature(hVideoDevice HPVIDEODEV, hPbuffer HPBUFFERARB, iVideoBuffer s32) (result s32);
var global wglBindVideoImageNV wglBindVideoImageNV_signature;

func wglReleaseVideoImageNV_signature(hPbuffer HPBUFFERARB, iVideoBuffer s32) (result s32);
var global wglReleaseVideoImageNV wglReleaseVideoImageNV_signature;

func wglSendPbufferToVideoNV_signature(hPbuffer HPBUFFERARB, iBufferType s32, pulCounterPbuffer u32 ref, bBlock s32) (result s32);
var global wglSendPbufferToVideoNV wglSendPbufferToVideoNV_signature;

func wglGetVideoInfoNV_signature(hpVideoDevice HPVIDEODEV, pulCounterOutputPbuffer u32 ref, pulCounterOutputVideo u32 ref) (result s32);
var global wglGetVideoInfoNV wglGetVideoInfoNV_signature;
def WGL_OML_sync_control = 1;

func wglGetSyncValuesOML_signature(hdc HDC, ust s64 ref, msc s64 ref, sbc s64 ref) (result s32);
var global wglGetSyncValuesOML wglGetSyncValuesOML_signature;

func wglGetMscRateOML_signature(hdc HDC, numerator s32 ref, denominator s32 ref) (result s32);
var global wglGetMscRateOML wglGetMscRateOML_signature;

func wglSwapBuffersMscOML_signature(hdc HDC, target_msc s64, divisor s64, remainder s64) (result s64);
var global wglSwapBuffersMscOML wglSwapBuffersMscOML_signature;

func wglSwapLayerBuffersMscOML_signature(hdc HDC, fuPlanes s32, target_msc s64, divisor s64, remainder s64) (result s64);
var global wglSwapLayerBuffersMscOML wglSwapLayerBuffersMscOML_signature;

func wglWaitForMscOML_signature(hdc HDC, target_msc s64, divisor s64, remainder s64, ust s64 ref, msc s64 ref, sbc s64 ref) (result s32);
var global wglWaitForMscOML wglWaitForMscOML_signature;

func wglWaitForSbcOML_signature(hdc HDC, target_sbc s64, ust s64 ref, msc s64 ref, sbc s64 ref) (result s32);
var global wglWaitForSbcOML wglWaitForSbcOML_signature;
