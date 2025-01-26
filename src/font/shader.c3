module font;

import glfw;
import opengl;
import logger;
import terminal;

ZString vertexCode = $embed("vert.glsl");
ZString fragmentCode = $embed("frag.glsl");

struct Shader {
    CUInt id;
}

fault ShaderError {
    VERTEX_SHADER_COMPILATION_ERROR,
    FRAGMENT_SHADER_COMPILATION_ERROR,
    PROGRAM_LINKING_ERROR,
}

def Mat = float[4][4];

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

fn CUInt! compileAndLinkShaders() {
    CUInt vertex, fragment;
    CInt ok;
    // vertex shader
    vertex = gl::createShader(gl::GL_VERTEX_SHADER);
    gl::shaderSource(vertex, 1, &vertexCode, null);
    gl::compileShader(vertex);
    // check errors
    gl::getShaderiv(vertex, gl::GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char[1024] infoLog;
        gl::getShaderInfoLog(vertex, 1024, null, &infoLog);
        logger::printfn("can't compile vertex shader: %s", (ZString)&infoLog);
        return ShaderError.VERTEX_SHADER_COMPILATION_ERROR?;
    }

    // fragment Shader
    fragment = gl::createShader(gl::GL_FRAGMENT_SHADER);
    gl::shaderSource(fragment, 1, &fragmentCode, null);
    gl::compileShader(fragment);
    // check errors
    gl::getShaderiv(vertex, gl::GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char[1024] infoLog;
        gl::getShaderInfoLog(fragment, 1024, null, &infoLog);
        logger::printfn("can't compile frangments shader: %s", (ZString)&infoLog);
        return ShaderError.FRAGMENT_SHADER_COMPILATION_ERROR?;
    }

    // shader Program
    CUInt id = gl::createProgram();
    gl::attachShader(id, vertex);
    gl::attachShader(id, fragment);
    gl::linkProgram(id);
    // check errors
    gl::getProgramiv(id, gl::GL_LINK_STATUS, &ok);
    if (!ok) {
        char[1024] infoLog;
        gl::getProgramInfoLog(id, 1024, null, &infoLog);
        logger::printfn("can't compile program: %s", (ZString)&infoLog);
        return ShaderError.PROGRAM_LINKING_ERROR?;
    }

    // delete the shaders as they're linked into our program now and no longer necessary
    gl::deleteShader(vertex);
    gl::deleteShader(fragment);

    Mat projection;
    projection.ortho(0.0f, (float)terminal::WIDTH, 0.0f, (float)terminal::HEIGHT);
    gl::useProgram(id);
    gl::uniformMatrix4fv(gl::getUniformLocation(id, "projection"), 1, (bool)gl::GL_FALSE, &projection);

    return id;
}
