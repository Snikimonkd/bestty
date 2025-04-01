module terminal;
///
/// import glfw;
/// import opengl;
/// import freetype;
/// import logger;
/// import std::thread;
/// import std::time;
///
/// char *vertexShaderSource = "#version 330 core\n"
/// "layout (location = 0) in vec3 aPos;\n"
/// "void main()\n"
/// "{\n"
/// "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
/// "}\0";
///
/// char *fragmentShaderSource = "#version 330 core\n"
/// "out vec4 FragColor;\n"
/// "void main()\n"
/// "{\n"
/// "   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n"
/// "}\n\0";
///
/// fn int tri() {
///     if (!glfw::init()) {
///         return -1;
///     }
///     glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 3);
///     glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 3);
///     glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
///
/// 	$if env::DARWIN:
///         glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, gl::GL_TRUE);
/// 	$endif
///
///     // glfw window creation
///     glfw::GlfwWindow* window;
///     window = glfw::createWindow(800, 600, "hello glfw", null, null);
///     if (!window) {
///         glfw::terminate();
///         logger::printfn("can't create window");
///         return -1;
///     }
///     glfw::makeContextCurrent(window);
///
///     // build and compile our shader program
///     // ------------------------------------
///     // vertex shader
///     CUInt vertexShader = gl::createShader(gl::GL_VERTEX_SHADER);
///     gl::shaderSource(vertexShader, 1, &vertexShaderSource, null);
///     gl::compileShader(vertexShader);
///     // check for shader compile errors
///     CInt success;
///     char[512] infoLog;
///     gl::getShaderiv(vertexShader, gl::GL_COMPILE_STATUS, &success);
///     if (!success)
///     {
///         gl::getShaderInfoLog(vertexShader, 512, null, &infoLog);
///         logger::printfn("ERROR::SHADER::VERTEX::COMPILATION_FAILED: %s", infoLog);
///     }
///     // fragment shader
///     CUInt fragmentShader = gl::createShader(gl::GL_FRAGMENT_SHADER);
///     gl::shaderSource(fragmentShader, 1, &fragmentShaderSource, null);
///     gl::compileShader(fragmentShader);
///     // check for shader compile errors
///     gl::getShaderiv(fragmentShader, gl::GL_COMPILE_STATUS, &success);
///     if (!success)
///     {
///         gl::getShaderInfoLog(fragmentShader, 512, null, &infoLog);
///         logger::printfn("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED: %s", infoLog);
///     }
///     // link shaders
///     CUInt shaderProgram = gl::createProgram();
///     gl::attachShader(shaderProgram, vertexShader);
///     gl::attachShader(shaderProgram, fragmentShader);
///     gl::linkProgram(shaderProgram);
///     // check for linking errors
///     gl::getProgramiv(shaderProgram, gl::GL_LINK_STATUS, &success);
///     if (!success) {
///         gl::getProgramInfoLog(shaderProgram, 512, null, &infoLog);
///         logger::printfn("ERROR::SHADER::PROGRAm::COMPILATION_FAILED: %s", infoLog);
///     }
///     gl::deleteShader(vertexShader);
///     gl::deleteShader(fragmentShader);
///
///     // set up vertex data (and buffer(s)) and configure vertex attributes
///     // ------------------------------------------------------------------
///     float[] vertices = {
///         -0.5f, -0.5f, 0.0f, // left
///         0.5f, -0.5f, 0.0f, // right
///         0.0f,  0.5f, 0.0f  // top
///     };
///
///     CUInt vbo, vao;
///     gl::genVertexArrays(1, &vao);
///     gl::genBuffers(1, &vbo);
///     gl::bindVertexArray(vao);
///
///     gl::bindBuffer(gl::GL_ARRAY_BUFFER, vbo);
///     gl::bufferData(gl::GL_ARRAY_BUFFER, vertices.len * float.sizeof, vertices, gl::GL_STATIC_DRAW);
///
///     gl::vertexAttribPointer(0, 3, gl::GL_FLOAT, gl::GL_FALSE, 3 * float.sizeof, (void*)0);
///     gl::enableVertexAttribArray(0);
///
///     gl::bindBuffer(gl::GL_ARRAY_BUFFER, 0);
///
///     gl::bindVertexArray(0);
///
///     while (!glfw::windowShouldClose(window)) {
///         gl::clearColor(0.2f, 0.3f, 0.3f, 1.0f);
///         gl::clear(gl::GL_COLOR_BUFFER_BIT);
///
///         gl::useProgram(shaderProgram);
///         gl::bindVertexArray(vao);
///         gl::drawArrays(gl::GL_TRIANGLES, 0, 3);
///
///         glfw::swapBuffers(window);
///         glfw::pollEvents();
///     }
///     logger::printfn("getError: %s", gl::getError());
///
///     return 0;
/// }
