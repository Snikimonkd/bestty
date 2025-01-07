module terminal;

import glfw;
import opengl;
import freetype;
import logger;

fn int tmp() {
    CInt err;
    ft::Library library;
    defer ft::doneFreeType(library);
    err = ft::initFreeType(&library);
    if (err != ft::Error.OK.code) {
        logger::printfn("inti free type err: %s", err);
        return -1;
    }

    ft::Face face;
    defer ft::doneFace(face);
    err = ft::newFace(library, "/Users/slukash/Library/Fonts/Iosevka-Medium.ttf", 0, &face);
    if (err != ft::Error.OK.code) {
        logger::printfn("can't load font: %s", err);
        return -1;
    } 

//    ft::UInt idx = ft::getCharIndex(face, 'h');
//    if (idx == 0) {
//        logger::printfn("can't get char index: %s", err);
//        return -1;
//    }
//
//    err = ft::loadGlyph(face, idx, 0);
//    if (err != ft::Error.OK.code) {
//        logger::printfn("can't load glyph: %s", err);
//        return -1;
//    }
    
    err = ft::setPixelSizes(face, 0, 48); 
    if (err != ft::Error.OK.code) {
        logger::printfn("can't set pixel sizes: %s", err);
        return -1;
    }

    if(ft::loadChar(face, 'X', 1<<2)) {
        logger::printfn("can't load char: %s", err);
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
