module terminal;

import glfw;
import opengl;
import freetype;
import logger;

fn int tmp() {
    ft::Library library;
    int err = ft::initFreeType(&library);
    if (err != ft::Error.OK.code) {
        logger::printfn("inti free type err: %s", err);
        return -1;
    }

    ft::Face aface;
    err = ft::newFace(library, "/Users/slukash/Library/Fonts/Iosevka-Medium.ttf", 0, &aface);
    if (err == ft::Error.UNKNOWN_FILE_FORMAT.code) {
        logger::printfn("unknown file format");
        return -1;
    } else if (err != ft::Error.OK.code) {
        return -1;
    }

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
