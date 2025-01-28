module terminal;

import font;
import window;
import logger;

struct Term {
    font::GlyphsAtlas atlas;
    window::Window window;
}

fn void! Term.init(&self, int width = 800, int height = 600) {
    self.window.init(width, height)!;

    self.atlas.new_init(12000, self.window.width, self.window.height)!;
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
                Char32[]{'[', 'b', 'e', '█', ']', '█', 'ĕ', '¶', 'ʤ', ']', 'ȡ'},
                { 5, self.window.height - self.atlas.maxHeight },
                self.atlas,
                )!;
        // (CULong[]){'[', 'b', 'e', 's', 't', '█', ']', '█', 'ĕ', '¶', '¶'}
        // {[best█]█ĕ¶¶}ʤȡ

        // swap buffers
        self.window.swapBuffers();
    }
}

