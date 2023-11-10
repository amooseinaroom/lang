
// bindings to precompiled library for stb_truetype.h
// see license at the bottom of the file

module stb_truetype;

func stbtt_InitFont                      (info stbtt_fontinfo ref, data u8 ref, offset s32) (result s32)    extern_binding("stb_truetype", false);
func stbtt_ScaleForPixelHeight           (info stbtt_fontinfo ref, pixels f32) (result f32)                 extern_binding("stb_truetype", false);
func stbtt_GetFontVMetrics               (info stbtt_fontinfo ref, ascent s32 ref, descent s32 ref, lineGap s32 ref) extern_binding("stb_truetype", false);

func stbtt_GetCodepointBitmapBoxSubpixel(info stbtt_fontinfo ref, codepoint s32, scale_x f32, scale_y f32, shift_x f32, shift_y f32, ix0 s32 ref, iy0 s32 ref, ix1 s32 ref, iy1 s32 ref)   extern_binding("stb_truetype", false);
func stbtt_MakeCodepointBitmapSubpixel   (info stbtt_fontinfo ref, output u8 ref, out_w s32, out_h s32, out_stride s32, scale_x f32, scale_y f32, shift_x f32, shift_y f32, codepoint s32) extern_binding("stb_truetype", false);
func stbtt_GetCodepointHMetrics          (info stbtt_fontinfo ref, codepoint s32, advanceWidth s32 ref, leftSideBearing s32 ref)                                                           extern_binding("stb_truetype", false);
func stbtt_GetCodepointKernAdvance       (info stbtt_fontinfo ref, ch1 s32, ch2 s32) (result s32)                                                                                          extern_binding("stb_truetype", false);

struct stbtt_fontinfo
{
    userdata u8 ref;
    data u8 ref;              // pointer to .ttf file
    fontstart s32;         // offset of start of font
    
    numGlyphs s32;                     // number of glyphs, needed for range checking

    loca s32;
    head s32;
    glyf s32;
    hhea s32;
    hmtx s32;
    kern s32;
    gpos s32;
    svg s32; // table locations as offset from start of .ttf
    index_map s32;                     // a cmap mapping for our chosen character encoding
    indexToLocFormat s32;              // format needed to map from glyph index to glyph

    cff         stbtt__buf;                    // cff font data
    charstrings stbtt__buf;            // the charstring index
    gsubrs      stbtt__buf;                 // global charstring subroutines index
    subrs       stbtt__buf;                  // private charstring subroutines index
    fontdicts   stbtt__buf;              // array of font dicts
    fdselect    stbtt__buf;               // map from glyph to fontdict
};

struct stbtt__buf
{
   data u8 ref;
   cursor s32;
   size s32;
}

// copied from stb_truetype.h
// 
// ------------------------------------------------------------------------------
// This software is available under 2 licenses -- choose whichever you prefer.
// ------------------------------------------------------------------------------
// ALTERNATIVE A - MIT License
// Copyright (c) 2017 Sean Barrett
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ------------------------------------------------------------------------------
// ALTERNATIVE B - Public Domain (www.unlicense.org)
// This is free and unencumbered software released into the public domain.
// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
// software, either in source code form or as a compiled binary, for any purpose,
// commercial or non-commercial, and by any means.
// In jurisdictions that recognize copyright laws, the author or authors of this
// software dedicate any and all copyright interest in the software to the public
// domain. We make this dedication for the benefit of the public at large and to
// the detriment of our heirs and successors. We intend this dedication to be an
// overt act of relinquishment in perpetuity of all present and future rights to
// this software under copyright law.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// ------------------------------------------------------------------------------
// 