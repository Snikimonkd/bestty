module terminal;

import glfw;
import opengl;
import font;
import logger;

CUInt vao, vbo;

distinct Color = float[<4>];

macro Color Color.fromHexRGBA(int $r, int $g, int $b, int $a) @operator(construct)
{
    return Color.fromFloatRGBA((float)$r, (float)$g, (float)$b, (float)$a);
}

macro Color Color.fromFloatRGBA(float $r, float $g, float $b, float $a) @operator(construct)
{
    return Color{ $r/255.0f, $g/255.0f, $b/255.0f, $a/255.0f };
}

Color background = Color.fromHexRGBA(0x28, 0x28, 0x28, 0xff);
Color foreground = Color.fromHexRGBA(0xfb, 0xf1, 0xc7, 0xff);

fault GLError {
    GL_INIT_ERROR,
    GL_CREATE_WINDOW_ERROR,
}

fn void! tmp() {
    if (!glfw::init()) {
        logger::printfn("getError: %s", gl::getError());
        return GLError.GL_INIT_ERROR?;
    }
    glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 3);
    glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 3);
    glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);

    $if env::DARWIN:
        glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, gl::GL_TRUE);
    $endif

    // glfw window creation
    glfw::Window* window;
    window = glfw::createWindow(WIDTH, HEIGHT, "bestty", null, null);
    if (!window) {
        glfw::terminate();
        logger::printfn("can't create window");
        return GLError.GL_CREATE_WINDOW_ERROR?;
    }
    glfw::makeContextCurrent(window);

    // OpenGL state
    gl::enable(gl::GL_CULL_FACE);
    gl::enable(gl::GL_BLEND);
    gl::blendFunc(gl::GL_SRC_ALPHA, gl::GL_ONE_MINUS_SRC_ALPHA);

    // compile and setup the shader
    font::GlyphsAtlas atlas;
    atlas.new_init(128)!;
    defer atlas.destroy();

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

    // render loop
    // -----------
    while (!glfw::windowShouldClose(window)) {
        // input
        // -----
        processInput(window);

        // render
        // ------
        gl::clearColor(background.r, background.g, background.b, background.a);
        gl::clear(gl::GL_COLOR_BUFFER_BIT);

        renderText(atlas, "[best]", {5, HEIGHT-(int)atlas.glyphs['['].size.y});

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfw::swapBuffers(window);
        glfw::pollEvents();
    }

    if (gl::getError() != 0) {
        logger::printfn("window close errors: %s", gl::getError());
    }
}

fn void processInput(glfw::Window *window) {
    if (glfw::getKey(window, glfw::KEY_ESCAPE) == glfw::PRESS)
    {
        glfw::setWindowShouldClose(window, glfw::TRUE);
    }
}

fn void renderText(font::GlyphsAtlas atlas, ZString text, int[<2>] pos)
{
    // activate corresponding render state
    gl::useProgram(atlas.programID);
    gl::uniform3f(gl::getUniformLocation(atlas.programID, "out_color"), foreground.r, foreground.g, foreground.b);
    gl::activeTexture(gl::GL_TEXTURE0);
    gl::bindVertexArray(vao);

    // iterate through all characters
    for (int i = 0; i < text.char_len(); i++)
    {
        char c = text[i];
        font::Glyph ch = atlas.glyphs[c];

        float xpos = (float)pos.x + ch.bearing.x;
        float ypos = (float)pos.y - (float)(ch.size.y - ch.bearing.y);

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
