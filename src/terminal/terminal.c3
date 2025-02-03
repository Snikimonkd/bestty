module terminal;

import font;
import window;
import logger;
import pty;
import parser;

import opengl;

import std::collections::list;

struct Cursor {
    Char32 form;
    int x;
    int y;
}

struct Term {
    Allocator allocator;
    font::GlyphsAtlas atlas;
    window::Window window;
    Cursor cursor;
    pty::Pty pty;
    parser::Parser parser;
    parser::Scrollback scrollback;
}

fn void! Term.init(&self, int width = 800, int height = 600, Allocator allocator = allocator::heap()) {
    self.allocator = allocator;
    self.window.init(width, height)!;
    self.pty.init()!;
    self.scrollback.init();
    self.parser.init();

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
    self.scrollback.destroy();
}

fn void! Term.run(&self) {
    // render loop
    while (!self.window.shouldClose()) {
        // poll events + process input
        self.window.processInput();

        // render
        self.window.clear();

        self.readFromPty()!;
        self.drawScrollback()!;

        // swap buffers
        self.window.swapBuffers();
    }
}

fn void! Term.readFromPty(&self) {
    List(<char>)! fromPty = self.pty.read(self.allocator);
    if (catch err = fromPty) {
        return;
    }
    defer fromPty.free();
    if (fromPty.len() == 0 ) {
        return;
    }

    logger::printfn("1: %s", fromPty);

    // TODO: parser comes into play
    foreach (char c : fromPty) {
        parser::PtyAction! action = self.parser.next(c);
        if (catch err = action) {
            return err?;
        }

        self.scrollback.handle(action)!!;
    }
}

fn void! Term.drawScrollback(&self) {
    List(<UTF8String>) fromScrollback = self.scrollback.render(10000, self.window.height/self.atlas.maxHeight, self.allocator);
    defer {
        for (int i = 0; i < fromScrollback.len(); i++) {
            fromScrollback[i].free();
        }
        fromScrollback.free();
    }

    for (int i = 0; i < fromScrollback.len(); i++) {
        self.window.renderText(
                fromScrollback[i].array_view(),
                { 5, self.window.height - self.atlas.maxHeight*i - self.window.top - 2 },
                self.atlas)!;
    }
}

fn void! Term.drawCursor(&self) {
    self.window.renderText(
            {'█'},
            { self.cursor.x, self.cursor.y },
            self.atlas)!;
}
