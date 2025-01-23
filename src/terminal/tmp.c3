module terminal;

import glfw;
import opengl;
import font;
import logger;

def Mat = float[4][4];

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

fault Error {
    GL_INIT,
}

fn int! tmp() {
    if (!glfw::init()) {
        logger::printfn("getError: %s", gl::getError());
        return Error.GL_INIT?;
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
        return -1;
    }
    glfw::makeContextCurrent(window);

    // OpenGL state
    gl::enable(gl::GL_CULL_FACE);
    gl::enable(gl::GL_BLEND);
    gl::blendFunc(gl::GL_SRC_ALPHA, gl::GL_ONE_MINUS_SRC_ALPHA);

    // compile and setup the shader
    CUInt programID = initShader(vertexC, fragmentC)!!;
    Mat projection;
    projection.ortho(0.0f, (float)WIDTH, 0.0f, (float)HEIGHT);
    gl::useProgram(programID);
    gl::uniformMatrix4fv(gl::getUniformLocation(programID, "projection"), 1, (bool)gl::GL_FALSE, &projection);

    Character[] chars = font::buildCharsAtlas()!;

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

        renderText(programID, chars, "[bestty]", {5, HEIGHT-(int)chars['['].size.y});

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

fn void renderText(CUInt id, Character[] chars, ZString text, int[<2>] pos)
{
    // activate corresponding render state
    gl::useProgram(id);
    gl::uniform3f(gl::getUniformLocation(id, "textColor"), foreground.r, foreground.g, foreground.b);
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
