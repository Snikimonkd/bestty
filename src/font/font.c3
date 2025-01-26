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
    CUInt programID;
    Allocator allocator;

    Glyph[] glyphs;
}

fn void! GlyphsAtlas.new_init(&self, usz size) => self.init(size, allocator::heap());

fn void GlyphsAtlas.destroy(&self) {
    allocator::free(self.allocator, self.glyphs);
}

fn void! GlyphsAtlas.init(&self, usz size, Allocator allocator) {
    self.glyphs = allocator::new_array(allocator, Glyph, size);
	defer catch allocator::free(allocator, self.glyphs);

    self.allocator = allocator;
    self.programID = compileAndLinkShaders()!;

    // FreeType
    // --------
    ft::Library library;
    ft::Face face;
    CInt err;

    // init freetype lib
    err = ft::initFreeType(&library);
    if (err != 0) {
        logger::printfn("init free type err: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }
    defer catch ft::doneFreeType(library);
    defer ft::doneFreeType(library);

    // load font as face
    err = ft::newFace(library, "/Users/slukash/Library/Fonts/Iosevka-Medium.ttf", 0, &face);
    if (err != 0) {
        logger::printfn("can't load font: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }
    defer catch ft::doneFace(face);
    defer ft::doneFace(face);

    // set font size
    err = ft::setPixelSizes(face, 0, 24);
    if (err != 0) {
        logger::printfn("can't set pixel sizes: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    // disable byte-alignment restriction
    gl::pixelStorei(gl::GL_UNPACK_ALIGNMENT, 1);

    // load first 128 characters of ASCII set
    for (char c = 32; c < 128; c++)
    {
        // Load character glyph
        err = ft::loadChar(face, c, ft::LOAD_RENDER);
        if (err != 0)
        {
            logger::printfn("can't load char: %s", err);
            return ft::CINT_TO_ERROR[err]?;
        }

        err = ft::renderGlryph(face.glyph, ft::RENDER_MODE_SDF);
        if (err != 0)
        {
            logger::printfn("can't load char: %s", err);
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
            face.glyph.bitmap.width,
            face.glyph.bitmap.rows,
            0,
            gl::GL_RED,
            gl::GL_UNSIGNED_BYTE,
            face.glyph.bitmap.buffer,
        );

        // set texture options
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_WRAP_S, gl::GL_CLAMP_TO_BORDER);
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_WRAP_T, gl::GL_CLAMP_TO_BORDER);
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MIN_FILTER, gl::GL_LINEAR);
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MAG_FILTER, gl::GL_LINEAR);

        // now store character for later use
        Glyph glyph = {
            .textureID = texture,
            .size = { face.glyph.bitmap.width, face.glyph.bitmap.rows},
            .bearing = { face.glyph.bitmap_left, face.glyph.bitmap_top},
            .advance = (uint)face.glyph.advance.x,
        };
        self.glyphs[c] = glyph;
    }
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);
}
