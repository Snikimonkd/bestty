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

struct Term {
    font::GlyphsAtlas atlas;
    glfw::Window* window;
    int width;
    int height;
    int top;

//    glfw::Cursor* cursor; // createStandardCursor(int shape) @extern("glfwCreateStandardCursor");
//    int x; //fn void setCursor(Window* window, Cursor* cursor) @extern("glfwSetCursor");
//    int y; //fn void setCursorPos(Window* window, double xpos, double ypos) @extern("glfwSetCursorPos");
}

fn void! Term.init(&self, int width = 800, int height = 600) {
    self.width = width;
    self.height = height;
    // U+258C

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
    self.window = glfw::createWindow(self.width, self.height, "bestty", null, null);
    if (!self.window) {
        glfw::terminate();
        logger::printfn("can't create window");
        return GLError.GL_CREATE_WINDOW_ERROR?;
    }
    glfw::makeContextCurrent(self.window);

    glfw::getWindowFrameSize(self.window, null, &self.top, null, null);

    // OpenGL state
    gl::enable(gl::GL_CULL_FACE);
    gl::enable(gl::GL_BLEND);
    gl::blendFunc(gl::GL_SRC_ALPHA, gl::GL_ONE_MINUS_SRC_ALPHA);

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

    self.atlas.new_init(12000, self.width, self.height)!;
}

fn void! Term.destroy(&self) {
    self.atlas.destroy();
    glfw::destroyWindow(self.window);
    glfw::terminate();
}

fault GLError {
    GL_INIT_ERROR,
    GL_CREATE_WINDOW_ERROR,
}

fn void! tmp() {
    Term term;
    term.init()!;
    defer term.destroy()!!;

    // render loop
    // -----------
    while (!glfw::windowShouldClose(term.window)) {
        // input
        // -----
        term.processInput();

        // render
        // ------
        gl::clearColor(background.r, background.g, background.b, background.a);
        gl::clear(gl::GL_COLOR_BUFFER_BIT);

        term.renderText(Char32[]{'[', 'b', 'e', 's', 't', '█', ']', '█', 'ĕ', '¶', 'ʤ', ']'}, { 5, term.height - term.atlas.maxHeight });
        // (CULong[]){'[', 'b', 'e', 's', 't', '█', ']', '█', 'ĕ', '¶', '¶'}

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfw::swapBuffers(term.window);
        glfw::pollEvents();
    }

    if (gl::getError() != 0) {
        logger::printfn("window close errors: %s", gl::getError());
    }
}

fn void Term.processInput(&self) {
    if (glfw::getKey(self.window, glfw::KEY_ESCAPE) == glfw::PRESS)
    {
        logger::printfn("pressed");
        glfw::setWindowShouldClose(self.window, glfw::TRUE);
    }
}

fn void Term.renderText(&self, Char32[] text, int[<2>] pos)
{
    // activate corresponding render state
    gl::useProgram(self.atlas.programID);
    gl::uniform3f(gl::getUniformLocation(self.atlas.programID, "out_color"), foreground.r, foreground.g, foreground.b);
    gl::activeTexture(gl::GL_TEXTURE0);
    gl::bindVertexArray(vao);

    // iterate through all characters
    for (int i = 0; i < text.len; i++)
    {
        Char32 c = text[i];
        font::Glyph ch = self.atlas.glyphs[c];

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
