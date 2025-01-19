module terminal;

import glfw;
import opengl;
import freetype;
import logger;
import std::thread;
import std::time;

def Mat = float[4][4];

CUInt vao, vbo;

struct Character {
    CUInt      textureID;
    float[<2>] size;
    float[<2>] bearing;
    UInt       advance;
}

fn void Mat.ortho(&self, float left, float right, float bottom, float top) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            (*self)[i][i] = 1;
        }
    }
    (*self)[0][0] = 2 / (right - left);
    (*self)[1][1] = 2 / (top - bottom);
    (*self)[2][2] = -1;
    (*self)[3][0] = -(right + left) / (right - left);
    (*self)[3][1] = -(top + bottom) / (top - bottom);
}

ZString vertexC = $embed("text.vs");
ZString fragmentC = $embed("text.fs");

fn int tmp() {
    if (!glfw::init()) {
        return -1;
    }
    glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 3);
    glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 3);
    glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);

    $if env::DARWIN:
        glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, gl::GL_TRUE);
    $endif

    // glfw window creation
    glfw::Window* window;
    window = glfw::createWindow(WIDTH, HEIGHT, "hello glfw", null, null);
    if (!window) {
        glfw::terminate();
        logger::printfn("can't create window");
        return -1;
    }
    glfw::makeContextCurrent(window);

    // OpenGL state
    gl::enable(gl::GL_CULL_FACE);
    gl::enable(gl::GL_BLEND);
    gl::blendFunc(gl::GL_SRC_ALPHA, gl::GL_ONE_MINUS_SRC_ALPHA);

    // compile and setup the shader
    Shader shader = initShader(vertexC, fragmentC)!!;
    Mat projection;
    projection.ortho(0.0f, (float)WIDTH, 0.0f, (float)HEIGHT);
    gl::useProgram(shader.id);
    gl::uniformMatrix4fv(gl::getUniformLocation(shader.id, "projection"), 1, (bool)gl::GL_FALSE, &projection);

    Allocator allocator = allocator::heap();
    Character[] chars = allocator::new_array(allocator, Character, 128);
    defer allocator::free(allocator, chars);

    buildAtlas(&chars);

    // configure VAO/VBO for texture quads
    // -----------------------------------
    gl::genVertexArrays(1, &vao);
    gl::genBuffers(1, &vbo);
    gl::bindVertexArray(vao);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, vbo);
    gl::bufferData(gl::GL_ARRAY_BUFFER, float.sizeof * 6 * 4, null, gl::GL_DYNAMIC_DRAW);
    gl::enableVertexAttribArray(0);
    gl::vertexAttribPointer(0, 4, gl::GL_FLOAT, (bool)gl::GL_FALSE, 4 * float.sizeof, null);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
    gl::bindVertexArray(0);

    logger::printfn("getError: %s", gl::getError());

    // render loop
    // -----------
    while (!glfw::windowShouldClose(window)) {
        // input
        // -----
        processInput(window);

        // render
        // ------
        gl::clearColor(0.1f, 0.1f, 0.1f, 1.0f);
        gl::clear(gl::GL_COLOR_BUFFER_BIT);

        renderText(shader.id, chars, "hello", {100, 100});

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfw::swapBuffers(window);
        glfw::pollEvents();
    }
    logger::printfn("getError: %s", gl::getError());

    return 0;
}

fn void processInput(glfw::Window *window) {
    if (glfw::getKey(window, glfw::KEY_ESCAPE) == glfw::PRESS)
    {
        glfw::setWindowShouldClose(window, glfw::TRUE);
    }
}

fn ft::Error buildAtlas(Character[]* chars) {
    // FreeType
    // --------
    ft::Library library;
    ft::Face face;
    CInt err;

    // init freetype lib
    err = ft::initFreeType(&library);
    if (err != 0) {
        logger::printfn("init free type err: %s", err);
        return err;
    }

    // load font as face
    err = ft::newFace(library, "/Library/Fonts/Arial Unicode.ttf", 0, &face);
    if (err != ft::OK) {
        logger::printfn("can't load font: %s", err);
        return err;
    }

    // set font size
    err = ft::setPixelSizes(face, 0, 48);
    if (err != ft::OK) {
        logger::printfn("can't set pixel sizes: %s", err);
        return err;
    }

    // disable byte-alignment restriction
    gl::pixelStorei(gl::GL_UNPACK_ALIGNMENT, 1);

    // load first 128 characters of ASCII set
    for (char c = 32; c < 128; c++)
    {
        // Load character glyph
        err = ft::loadChar(face, c, ft::LOAD_RENDER);
        if (err != ft::OK)
        {
            logger::printfn("can't load char: %s", err);
            return err;
        }

///        logger::printfn("%s", face.glyph.bitmap.width);
///        logger::printfn("%s", face.glyph.bitmap.rows);
///        for (int i = 0; i < face.glyph.bitmap.rows; i++) {
///            for (int j = 0; j < face.glyph.bitmap.width; j++) {
///                if (face.glyph.bitmap.buffer[i*face.glyph.bitmap.width + j] != 0) {
///                    logger::printf("*");
///                } else {
///                    logger::printf(" ");
///                }
///            }
///            logger::printf("\n");
///        }

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
            &(face.glyph.bitmap.buffer),
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
        (*chars)[c] = character;
    }
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);

    // destroy FreeType once we're finished
    ft::doneFace(face);
    ft::doneFreeType(library);

    return 0;
}

fn void renderText(int id, Character[] chars, ZString text, int[<2>] pos)
{
    // activate corresponding render state
    gl::useProgram(id);
    gl::uniform3f(gl::getUniformLocation(id, "textColor"), 0.5f, 0.8f, 0.2f);
    gl::activeTexture(gl::GL_TEXTURE0);
    gl::bindVertexArray(vao);

    // iterate through all characters
    for (int i = 0; i < text.char_len(); i++)
    {
        char c = text[i];
        Character ch = chars[c];

        float xpos = pos.x + ch.bearing.x;
        float ypos = pos.y - (ch.size.y - ch.bearing.y);

        float w = ch.size.x;
        float h = ch.size.y;
        float[4][6] vertices = {
            { xpos,     ypos + h,   0.0f, 0.0f },
            { xpos,     ypos,       0.0f, 1.0f },
            { xpos + w, ypos,       1.0f, 1.0f },

            { xpos,     ypos + h,   0.0f, 0.0f },
            { xpos + w, ypos,       1.0f, 1.0f },
            { xpos + w, ypos + h,   1.0f, 0.0f }
        };
        // render glyph texture over quad
        gl::bindTexture(gl::GL_TEXTURE_2D, ch.textureID);
        // update content of VBO memory
        gl::bindBuffer(gl::GL_ARRAY_BUFFER, vbo);
        gl::bufferSubData(gl::GL_ARRAY_BUFFER, 0, 4*6*float.sizeof, &vertices);

        gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
        // render quad
        gl::drawArrays(gl::GL_TRIANGLES, 0, 6);
        pos.x += (ch.advance >> 6);
        // logger::printfn("pos: %s", pos.x);
    }
    gl::bindVertexArray(0);
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);
}
