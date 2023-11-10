
// bindings to precompiled library for stb_iamge.h
// see license at the bottom of the file

module stb_image;

func stbi_info_from_memory(buffer u8 ref, len s32, x s32 ref, y s32 ref, comp s32 ref) (ok s32) extern_binding("stb_image", false);
func stbi_load_from_memory(buffer u8 ref, len s32, x s32 ref, y s32 ref, comp s32 ref, req_comp s32) (pixels u8 ref) extern_binding("stb_image", false);
func stbi_loadf_from_memory(buffer u8 ref, len s32, x s32 ref, y s32 ref, comp s32 ref, req_comp s32) (pixels f32 ref) extern_binding("stb_image", false);
func stbi_image_free(pixels u8 ref) extern_binding("stb_image", false);
func stbi_set_flip_vertically_on_load(flag_true_if_should_flip s32) extern_binding("stb_image", false);

// copied from stb_image.h
//------------------------------------------------------------------------------
//This software is available under 2 licenses -- choose whichever you prefer.
//------------------------------------------------------------------------------
//ALTERNATIVE A - MIT License
//Copyright (c) 2017 Sean Barrett
//Permission is hereby granted, free of charge, to any person obtaining a copy of
//this software and associated documentation files (the "Software"), to deal in
//the Software without restriction, including without limitation the rights to
//use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//of the Software, and to permit persons to whom the Software is furnished to do
//so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//------------------------------------------------------------------------------
//ALTERNATIVE B - Public Domain (www.unlicense.org)
//This is free and unencumbered software released into the public domain.
//Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
//software, either in source code form or as a compiled binary, for any purpose,
//commercial or non-commercial, and by any means.
//In jurisdictions that recognize copyright laws, the author or authors of this
//software dedicate any and all copyright interest in the software to the public
//domain. We make this dedication for the benefit of the public at large and to
//the detriment of our heirs and successors. We intend this dedication to be an
//overt act of relinquishment in perpetuity of all present and future rights to
//this software under copyright law.
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//------------------------------------------------------------------------------
