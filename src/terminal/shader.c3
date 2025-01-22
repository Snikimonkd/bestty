module terminal;

import glfw;
import opengl;
import logger;

struct Shader {
    CUInt id;
}

fault ShaderError {
    COMPILATION_ERROR,
}

fn CUInt! initShader(ZString vertexCode, ZString fragmentCode) {
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
        return ShaderError.COMPILATION_ERROR?;
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
        return ShaderError.COMPILATION_ERROR?;
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
        return ShaderError.COMPILATION_ERROR?;
    }

    // delete the shaders as they're linked into our program now and no longer necessary
    gl::deleteShader(vertex);
    gl::deleteShader(fragment);

    return id;
}
