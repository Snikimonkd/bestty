module font;

import freetype;
import opengl;

import logger;

struct Character {
    CUInt      textureID;
    float[<2>] size;
    float[<2>] bearing;
    UInt       advance;
}

fn Character[]! buildCharsAtlas() {
    Allocator allocator = allocator::heap();
    Character[] chars = allocator::new_array(allocator, Character, 128);

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

    // load font as face
    err = ft::newFace(library, "/Users/slukash/Library/Fonts/Iosevka-Medium.ttf", 0, &face);
    if (err != 0) {
        logger::printfn("can't load font: %s", ft::CINT_TO_ERROR[err]);
        return ft::CINT_TO_ERROR[err]?;
    }

    // set font size
    err = ft::setCharSize(face, 0, 24 * 64, 72, 0);
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

        // generate texture
        CUInt texture;
        gl::genTextures(1, &texture);
        gl::bindTexture(gl::GL_TEXTURE_2D, texture);
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
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_WRAP_S, gl::GL_CLAMP_TO_EDGE);
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_WRAP_T, gl::GL_CLAMP_TO_EDGE);
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MIN_FILTER, gl::GL_LINEAR);
        gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MAG_FILTER, gl::GL_LINEAR);

        // now store character for later use
        Character character = {
            .textureID = texture,
            .size = { face.glyph.bitmap.width, face.glyph.bitmap.rows},
            .bearing = { face.glyph.bitmap_left, face.glyph.bitmap_top},
            .advance = (uint)face.glyph.advance.x,
        };
        (chars)[c] = character;
    }
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);

    // destroy FreeType once we're finished
    ft::doneFace(face);
    ft::doneFreeType(library);

    return chars;
}
