module terminal;

import glfw;
import opengl;
import freetype;
import logger;

def Mat = float[1024][1024];

fn void ortho(Mat* m,float left, float right, float bottom, float top) {
	(*m)[0][0] = 2 / (right - left);
    (*m)[1][1] = 2 / (top - bottom);
    (*m)[2][2] = - 1;
    (*m)[3][0] = - (right + left) / (right - left);
    (*m)[3][1] = - (top + bottom) / (top - bottom);
}

char[*] vertexC = "#version 330 core\nlayout (location = 0) in vec4 vertex; // <vec2 pos, vec2 tex>\nout vec2 TexCoords;\nuniform mat4 projection;\nvoid main()\n{\n    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);\n    TexCoords = vertex.zw;}\0";

char[*] fragmentC = "#version 330 core\nin vec2 TexCoords;\nout vec4 color;\nuniform sampler2D text;\nuniform vec3 textColor;\nvoid main()\n{\n    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(text, TexCoords).r);\n    color = vec4(textColor, 1.0) * sampled;\n}\0";

fn int tmp() {
    // glfw: initialize and configure
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
    window = glfw::createWindow(800, 600, "hello glfw", null, null);
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
    Shader shader = initShader(&vertexC, &fragmentC)!!;
    Mat projection;
    ortho(&projection, 0.0f, (float)WIDTH, 0.0f, (float)HEIGHT);
    gl::useProgram(shader.id);
    gl::uniformMatrix4fv(gl::getUniformLocation(shader.id, "projection"), 1, (bool)gl::GL_FALSE, &projection[0][0]);

    // FreeType
    CInt err;
    ft::Library library;
    defer ft::doneFreeType(library);
    // All functions return a value different than 0 whenever an error occurred
    err = ft::initFreeType(&library);
    if (err != ft::Error.OK.code) {
        logger::printfn("inti free type err: %s", err);
        return -1;
    }

    // load font as face
    ft::Face face;
    defer ft::doneFace(face);
    err = ft::newFace(library, "/Users/slukash/Library/Fonts/Iosevka-Medium.ttf", 0, &face);
    if (err != ft::Error.OK.code) {
        logger::printfn("can't load font: %s", err);
        return -1;
    }

    // set size to load glyphs as
    err = ft::setPixelSizes(face, 0, 48);
    if (err != ft::Error.OK.code) {
        logger::printfn("can't set pixel sizes: %x", err);
        return -1;
    }

    // Load character glyph
    if(ft::loadChar(face, 'X', 1<<2)) {
        logger::printfn("can't load char: %s", err);
        return -1;
    }

    // generate texture
    CUInt texture;
    gl::genTextures(1, &texture);
    gl::bindTexture(gl::GL_TEXTURE_2D, texture);

    // disable byte-alignment restriction
    gl::pixelStorei(gl::GL_UNPACK_ALIGNMENT, 1);

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

    // save something
    int[<2>] size = {face.glyph.bitmap.width, face.glyph.bitmap.rows};
    int[<2>] bearing = {face.glyph.bitmap_left, face.glyph.bitmap_top};

    //
    gl::bindTexture(gl::GL_TEXTURE_2D, 0);

    // configure VAO/VBO for texture quads
    CUInt vao, vbo;
    gl::genVertexArrays(1, &vao);
    gl::genBuffers(1, &vbo);
    gl::bindVertexArray(vao);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, vbo);
    gl::bufferData(gl::GL_ARRAY_BUFFER, float.sizeof * 6 * 4, null, gl::GL_DYNAMIC_DRAW);
    gl::enableVertexAttribArray(0);
    gl::vertexAttribPointer(0, 4, gl::GL_FLOAT, (bool)gl::GL_FALSE, 4 * float.sizeof, null);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
    gl::bindVertexArray(0);

    //

    while (!glfw::windowShouldClose(window)) {
        gl::clearColor(0.2f, 0.3f, 0.3f, 1.0f);
        gl::clear(gl::GL_COLOR_BUFFER_BIT);

        gl::useProgram(shader.id);

        gl::uniform3f(gl::getUniformLocation(shader.id, "textColor"), 0.5f, 0.8f, 0.2f);
        gl::activeTexture(gl::GL_TEXTURE0);
        gl::bindVertexArray(vao);

        // update content of VBO memory
        float xpos = 25.0f + bearing.x;
        float ypos = 25.0f - (float)(size.y - bearing.y);

        float w = size.x;
        float h = size.y;

        float[4][6] vertices = {
            { xpos,     ypos + h,   0.0f, 0.0f },
            { xpos,     ypos,       0.0f, 1.0f },
            { xpos + w, ypos,       1.0f, 1.0f },

            { xpos,     ypos + h,   0.0f, 0.0f },
            { xpos + w, ypos,       1.0f, 1.0f },
            { xpos + w, ypos + h,   1.0f, 0.0f }
        };
        // render glyph texture over quad
        gl::bindTexture(gl::GL_TEXTURE_2D, texture);
        // update content of VBO memory
        gl::bindBuffer(gl::GL_ARRAY_BUFFER, vbo);
        gl::bufferSubData(gl::GL_ARRAY_BUFFER, 0, vertices.len, (void*)&vertices);

        gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
        // render quad
        gl::drawArrays(gl::GL_TRIANGLES, 0, 6);

        gl::bindVertexArray(0);
        gl::bindTexture(gl::GL_TEXTURE_2D, 0);


        glfw::swapBuffers(window);
        glfw::pollEvents();
    }

    return 0;
}
