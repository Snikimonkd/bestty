module window;

import opengl;
import glfw;

import logger;
import font;

fn float[<4>] fromHexRGBA(int r, int g, int b, int a) {
    return fromFloatRGBA((float)r, (float)g, (float)b, (float)a);
}

macro float[<4>] fromFloatRGBA(float r, float g, float b, float a) {
    float[<4>] tmp = { r/255.0f, g/255.0f, b/255.0f, a/255.0f };
    return tmp;
}

faultdef
    GL_INIT_ERROR,
    GL_CREATE_WINDOW_ERROR;


struct Window {
    glfw::GlfwWindow* handle;

    float[<4>] bg;
    float[<4>] fg;

    CUInt vao;
    CUInt vbo;

    int width;
    int height;
    int top;
}

fn void? Window.init(&self,
        int width = 1200,
        int height = 800,
        float[<4>] bg = fromHexRGBA(0x28, 0x28, 0x28, 0xff),
        float[<4>] fg = fromHexRGBA(0xfb, 0xf1, 0xc7, 0xff),
        ) {
    self.width = width;
    self.height = height;
    self.bg = bg;
    self.fg = fg;

    opengl::loadGL((GLLoadFn)&glfw::getProcAddress);
    if (!glfw::init()) {
        logger::printfn("getError: %s", gl::getError());
        return GL_INIT_ERROR?;
    }
    glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 3);
    glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 3);
    glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
    glfw::windowHint(glfw::RESIZABLE, glfw::FALSE);

    $if env::DARWIN:
        glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, gl::GL_TRUE);
    $endif

    // glfw window creation
    self.handle = glfw::createWindow(self.width, self.height, "ttyob", null, null);
    if (!self.handle) {
        opengl::loadGL((GLLoadFn)&glfw::getProcAddress);
        glfw::terminate();
        logger::printfn("can't create window");
        return GL_CREATE_WINDOW_ERROR?;
    }
    glfw::makeContextCurrent(self.handle);

    glfw::getWindowFrameSize(self.handle, null, &self.top, null, null);

    // OpenGL state
    opengl::loadGL((GLLoadFn)&glfw::getProcAddress);
    gl::enable(gl::GL_CULL_FACE);
    gl::enable(gl::GL_BLEND);
    gl::blendFunc(gl::GL_SRC_ALPHA, gl::GL_ONE_MINUS_SRC_ALPHA);

    // configure VAO/VBO for texture quads
    // -----------------------------------
    gl::genVertexArrays(1, &self.vao);
    gl::genBuffers(1, &self.vbo);
    gl::bindVertexArray(self.vao);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, self.vbo);
    gl::bufferData(gl::GL_ARRAY_BUFFER, float.sizeof * 6 * 4, null, gl::GL_DYNAMIC_DRAW);
    gl::enableVertexAttribArray(0);
    gl::vertexAttribPointer(0, 4, gl::GL_FLOAT, gl::GL_FALSE, 4 * float.sizeof, null);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
    gl::bindVertexArray(0);
}

fn void Window.destroy(&self) {
    glfw::destroyWindow(self.handle);
    glfw::terminate();

    if (gl::getError() != 0) {
        logger::printfn("window close errors: %s", gl::getError());
    }
}

fn bool Window.shouldClose(&self) {
    return (bool)glfw::windowShouldClose(self.handle);
}

fn void Window.clear(&self) {
        gl::clearColor(self.bg.r, self.bg.g, self.bg.b, self.bg.a);
        gl::clear(gl::GL_COLOR_BUFFER_BIT);
}

fn void Window.swapBuffers(&self) {
    glfw::swapBuffers(self.handle);
}

fn void? Window.renderCursor(&self, Char32 shape, int[<2>] pos, font::GlyphsAtlas atlas) {
    // activate corresponding render state
    gl::useProgram(atlas.programID);
    gl::uniform3f(gl::getUniformLocation(atlas.programID, "out_color"), self.fg.r, self.fg.g, self.fg.b);
    gl::activeTexture(gl::GL_TEXTURE0);
    gl::bindVertexArray(self.vao);

    font::Glyph ch;
    if (!atlas.glyphs.has_key(shape)) {
        ch = atlas.load_unicode(shape)!;
    } else {
        ch = (*atlas.glyphs)[shape]!;
    }

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
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, self.vbo);
    gl::bufferSubData(gl::GL_ARRAY_BUFFER, 0, 4*6*float.sizeof, &vertices);

    gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
    // render quad
    gl::drawArrays(gl::GL_TRIANGLES, 0, 6);

    gl::bindVertexArray(0);
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);
}

fn void? Window.renderText(&self, Char32[] text, usz[<2>] pos, font::GlyphsAtlas atlas)
{
    // activate corresponding render state
    gl::useProgram(atlas.programID);
    gl::uniform3f(gl::getUniformLocation(atlas.programID, "out_color"), self.fg.r, self.fg.g, self.fg.b);
    gl::activeTexture(gl::GL_TEXTURE0);
    gl::bindVertexArray(self.vao);

    // iterate through all characters
    for (int i = 0; i < text.len; i++)
    {
        Char32 c = text[i];
        if (c == '\n' ||  c == '\0') {
            break;
        }
        font::Glyph ch;
        if (!atlas.glyphs.has_key(c)) {
            ch = atlas.load_unicode(c)!;
        } else {
            ch = (*atlas.glyphs)[c]!;
        }

//        if (ch.size.x == 0 || ch.size.y == 0) {
//            // logger::printfn("no symbol: %s", text[i]);
//            continue;
//        }

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
        gl::bindBuffer(gl::GL_ARRAY_BUFFER, self.vbo);
        gl::bufferSubData(gl::GL_ARRAY_BUFFER, 0, 4*6*float.sizeof, &vertices);

        gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
        // render quad
        gl::drawArrays(gl::GL_TRIANGLES, 0, 6);

        // move
        pos.x += (usz)ch.advance;
    }
    gl::bindVertexArray(0);
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);
}
