module terminal;

import glfw;
import opengl;
import freetype;

fn int tmp() {
    glfw::Window* window;
    if (!glfw::init()) {
        return -1;
    }

    window = glfw::createWindow(800, 600, "hello glfw", null, null);
    if (!window) {
        glfw::terminate();
        return -1;
    }

    glfw::makeContextCurrent(window);

    while (!glfw::windowShouldClose(window)) {
        gl::clear(gl::GL_COLOR_BUFFER_BIT);

        glfw::swapBuffers(window);

        glfw::pollEvents();
    }

    return 0;
}
