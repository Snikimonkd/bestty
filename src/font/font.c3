module font;

import freetype;
import opengl;

import logger;

struct Glyph {
    CUInt      textureID;
    float[<2>] size;
    float[<2>] bearing;
    UInt       advance;
}

struct GlyphsAtlas {
    ft::Library library;
    ft::Face face;

    CUInt programID;
    Allocator allocator;

    Glyph[] glyphs;

    int maxHeight;
}

fn void! GlyphsAtlas.new_init(&self, usz size, int width, int height) => self.init(size, width, height, allocator::heap());

fn void GlyphsAtlas.destroy(&self) {
    allocator::free(self.allocator, self.glyphs);

    ft::doneFace(self.face);
    ft::doneFreeType(self.library);
}

fn void! GlyphsAtlas.init(&self, usz size, int width, int height, Allocator allocator) {
    self.glyphs = allocator::new_array(allocator, Glyph, size);
	defer catch allocator::free(allocator, self.glyphs);

    self.allocator = allocator;
    self.programID = compileAndLinkShaders(width, height)!;

    // FreeType
    // --------
    CInt err;

    // init freetype lib
    err = ft::initFreeType(&self.library);
    if (err != 0) {
        logger::printfn("init free type err: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    // load font as face
    err = ft::newFace(self.library, "/Users/slukash/Library/Fonts/Iosevka-Medium.ttf", 0, &self.face);
    if (err != 0) {
        logger::printfn("can't load font: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }


    CULong value = 'u' << 24 | 'n' << 16 | 'i' << 8 | 'c';
    err = ft::selectCharmap(self.face, value);
    if (err != 0) {
        logger::printfn("can't set unicode: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    // set font size
    err = ft::setPixelSizes(self.face, 0, 24);
    if (err != 0) {
        logger::printfn("can't set pixel sizes: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    // load first 128 characters of ASCII set
    for (char c = 32; c < 128; c++)
    {
        self.load_unicode(c)!;
    }
    self.load_unicode('█')!;
    self.load_unicode('ĕ')!;
    self.load_unicode('¶')!;
    self.load_unicode('ʤ')!;
}

fn void! GlyphsAtlas.load_unicode(&self, ULong charcode) {
    // disable byte-alignment restriction
    gl::pixelStorei(gl::GL_UNPACK_ALIGNMENT, 1);

    CInt err;

    err = ft::loadChar(self.face, charcode, ft::LOAD_RENDER);
    if (err != 0)
    {
        logger::printfn("can't load glyph: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    err = ft::renderGlryph(self.face.glyph, ft::RENDER_MODE_SDF);
    if (err != 0)
    {
        logger::printfn("can't load char: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    // generate texture
    CUInt texture;
    gl::genTextures(1, &texture);
    gl::bindTexture(gl::GL_TEXTURE_2D, texture);
    // TODO: render one big texture with all characters but not many small independent ones
    gl::texImage2D(
        gl::GL_TEXTURE_2D,
        0,
        gl::GL_RED,
        self.face.glyph.bitmap.width,
        self.face.glyph.bitmap.rows,
        0,
        gl::GL_RED,
        gl::GL_UNSIGNED_BYTE,
        self.face.glyph.bitmap.buffer,
    );

    // set texture options
    gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_WRAP_S, gl::GL_CLAMP_TO_BORDER);
    gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_WRAP_T, gl::GL_CLAMP_TO_BORDER);
    gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MIN_FILTER, gl::GL_LINEAR);
    gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MAG_FILTER, gl::GL_LINEAR);

    // now store character for later use
    Glyph glyph = {
        .textureID = texture,
        .size = { self.face.glyph.bitmap.width, self.face.glyph.bitmap.rows},
        .bearing = { self.face.glyph.bitmap_left, self.face.glyph.bitmap_top},
        .advance = (uint)self.face.glyph.advance.x,
    };
    self.glyphs[charcode] = glyph;
    if (self.face.glyph.bitmap_top > self.maxHeight)  {
        logger::printfn("%s", self.face.glyph.bitmap_top);
        self.maxHeight = self.face.glyph.bitmap_top;
    }

    gl::bindTexture(gl::GL_TEXTURE_2D, 0);
}
