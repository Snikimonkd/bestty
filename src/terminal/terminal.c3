module terminal;

import font;
import window;
import logger;
import pty;
import parser;
import scrollback;
import glfw;
import opengl;
import std::collections::list;
import std::collections::map;
import std::time;

struct Term {
    Allocator allocator;
    font::GlyphsAtlas atlas;
    window::Window window;
    pty::Pty pty;
    parser::Parser parser;
    scrollback::Scrollback scrollback;

    HashMap{int, Time}* keyLogs;

    usz leftPadding;
    usz topPadding;
    usz fontSize;
}

fn void? Term.init(&self, usz fontSize, int width = 800, int height = 600, Allocator allocator = allocator::heap()) {
    self.allocator = allocator;
    self.fontSize = fontSize;
    self.window.init(width, height)!;
    self.atlas.init((CUInt)self.fontSize, self.window.width, self.window.height)!;
    font::Glyph ch = (*self.atlas.glyphs)['#']!;

    self.leftPadding = 5;
    self.topPadding = 5;

    usz rows = ((usz)self.window.height - self.window.top - self.topPadding) / self.atlas.maxHeight + 1;
    usz cols = (usz)self.window.width / (usz)ch.advance;

    self.scrollback.init(
        cols,
        rows,
        allocator,
    );

    self.pty.init(rows, cols)!;

    self.parser.init();
    self.keyLogs = allocator::new(allocator, HashMap{int, time::Time});
    self.keyLogs.init(allocator);

}

fn void Term.destroy(&self) {
    self.atlas.destroy();
    self.window.destroy();
    self.scrollback.destroy();

    self.keyLogs.free();
    allocator::free(self.allocator, self.keyLogs);
}

fn void? Term.run(&self) {
    // render loop
    while (!self.window.shouldClose()) {
        // poll events + process input
        self.processInput()!;

        // render
        self.window.clear();

        self.readFromPty()!;
        self.drawScrollback()!;

        // swap buffers
        self.window.swapBuffers();
    }
}

fn void? Term.readFromPty(&self) {
    List{char}? fromPty = self.pty.read(self.allocator);
    if (catch err = fromPty) {
        return;
    }
    defer fromPty.free();
    if (fromPty.len() == 0 ) {
        return;
    }

    // TODO: parser comes into play
    foreach (char c : fromPty) {
        parser::PtyAction? action = self.parser.next(c);
        if (catch err = action) {
            return err?;
        }

        self.scrollback.handle(action)!!;
    }
}

fn void? Term.drawScrollback(&self) {
    for (usz i = 0; i < self.scrollback.height; i++) {
        self.window.renderText(
            self.scrollback.lines[i],
            { self.leftPadding, self.window.height - self.atlas.maxHeight*(int)i - self.window.top - self.topPadding },
            self.atlas,
        )!;
    }

    self.window.renderText(
        {'█'},
        { self.leftPadding + self.scrollback.cursor.x*16, self.window.height - self.atlas.maxHeight*(int)self.scrollback.cursor.y - self.window.top - self.topPadding },
        self.atlas,
    )!;
}

fn void? Term.processInput(&self) {
    glfw::pollEvents();
    if (glfw::getKey(self.window.handle, glfw::KEY_ESCAPE) == glfw::PRESS) {
        glfw::setWindowShouldClose(self.window.handle, glfw::TRUE);
    }

    int diff = 'a'-'A';
    for (int i = glfw::KEY_A; i <= glfw::KEY_Z; i++) {
        if (glfw::getKey(self.window.handle, i) == glfw::PRESS) {
            if (!self.keyLogs.has_key(i)) {
                (*self.keyLogs)[i] = time::now();
            } else if (time::Time.diff_us(time::now(), (*self.keyLogs)[i]!) < time::MS*100) {
                continue;
            } else {
                (*self.keyLogs)[i] = time::now();
            }

            self.pty.write((char)(i+diff))!;
        }
    }

//    int diff = 'a'-'A';
//    for (int i = glfw::KEY_SPACE; i <= glfw::KEY_Z; i++) {
//        if (glfw::getKey(self.window.handle, i) == glfw::PRESS) {
//            if (!self.keyLogs.has_key(i)) {
//                (*self.keyLogs)[i] = time::now();
//            } else if (time::Time.diff_us(time::now(), (*self.keyLogs)[i]!) < time::MS*100) {
//                continue;
//            } else {
//                (*self.keyLogs)[i] = time::now();
//            }
//
//            self.pty.write((char)(i+diff))!;
//        }
//    }

    // enter
    if (glfw::getKey(self.window.handle, glfw::KEY_ENTER) == glfw::PRESS) {
        if (!self.keyLogs.has_key(glfw::KEY_ENTER)) {
            (*self.keyLogs)[glfw::KEY_ENTER] = time::now();
        } else if (time::Time.diff_us(time::now(), (*self.keyLogs)[glfw::KEY_ENTER]!) < time::MS*100) {
            return;
        } else {
            (*self.keyLogs)[glfw::KEY_ENTER] = time::now();
        }
        self.pty.write('\n')!;
    }

    // backspace
    if (glfw::getKey(self.window.handle, glfw::KEY_BACKSPACE) == glfw::PRESS) {
        if (!self.keyLogs.has_key(glfw::KEY_BACKSPACE)) {
            (*self.keyLogs)[glfw::KEY_BACKSPACE] = time::now();
        } else if (time::Time.diff_us(time::now(), (*self.keyLogs)[glfw::KEY_BACKSPACE]!) < time::MS*100) {
            return;
        } else {
            (*self.keyLogs)[glfw::KEY_BACKSPACE] = time::now();
        }
        self.pty.write('\b')!;
    }

    // space
    if (glfw::getKey(self.window.handle, glfw::KEY_SPACE) == glfw::PRESS) {
        if (!self.keyLogs.has_key(glfw::KEY_SPACE)) {
            (*self.keyLogs)[glfw::KEY_SPACE] = time::now();
        } else if (time::Time.diff_us(time::now(), (*self.keyLogs)[glfw::KEY_SPACE]!) < time::MS*100) {
            return;
        } else {
            (*self.keyLogs)[glfw::KEY_SPACE] = time::now();
        }
        self.pty.write(' ')!;
    }
}

