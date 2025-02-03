module terminal;

import font;
import window;
import logger;

import opengl;

struct Cursor {
    Char32 form;
    int x;
    int y;
}

struct Term {
    font::GlyphsAtlas atlas;
    window::Window window;
    Cursor cursor;
}

fn void! Term.init(&self, int width = 800, int height = 600) {
    self.window.init(width, height)!;

    self.atlas.new_init(32, self.window.width, self.window.height)!;
    self.cursor = {
        .form = '█',
        .x = 0,
        .y = 0,
    };
}

fn void Term.destroy(&self) {
    self.atlas.destroy();
    self.window.destroy();
}

fn void! Term.run(&self) {
    // render loop
    while (!self.window.shouldClose()) {
        // poll events + process input
        self.window.processInput();

        // render
        self.window.clear();
        self.window.renderText(
                Char32[]{'→', 'a','b','c','d','e','f','g','h','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'},
                { 5, self.window.height - self.atlas.maxHeight },
                self.atlas,)!;

        self.window.renderText(
                Char32[]{'→','W', 'W', 'W', 'A','B','C','D','E','F','G','H','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'},
                { 5, self.window.height - self.atlas.maxHeight-150 },
                self.atlas,)!;

        self.window.renderText(
                Char32[]{'#', '[', '█', ']', '█', 'ĕ', '¶', 'ʤ', ']', 'ȡ'},
                { 5, self.window.height - self.atlas.maxHeight-300 },
                self.atlas,)!;

        // swap buffers
        self.window.swapBuffers();
    }
}


