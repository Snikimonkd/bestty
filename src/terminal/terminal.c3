module terminal;

import font;
import window;
import logger;
import pty;
import parser;
import glfw;
import opengl;
import std::collections::list;
import std::collections::map;
import std::time;

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

    HashMap(<int, Time>)* keyLogs;

    int leftPadding;
    int topPadding;
}

fn void! Term.init(&self, int width = 800, int height = 600, Allocator allocator = allocator::heap()) {
    self.allocator = allocator;
    self.window.init(width, height)!;
    self.pty.init()!;
    self.scrollback.init();
    self.parser.init();
    self.keyLogs = allocator::new(allocator, HashMap(<int, time::Time>));
    self.keyLogs.new_init();

    self.atlas.new_init(32, self.window.width, self.window.height)!;
    self.cursor = {
        .form = '█',
        .x = 0,
        .y = 0,
    };
    self.leftPadding = 5;
    self.topPadding = 5;
}

fn void Term.destroy(&self) {
    self.atlas.destroy();
    self.window.destroy();
    self.scrollback.destroy();

    self.keyLogs.free();
    allocator::free(self.allocator, self.keyLogs);
}

fn void! Term.run(&self) {
    // render loop
    while (!self.window.shouldClose()) {
        // poll events + process input
        self.processInput()!;

        // render
        self.window.clear();

        self.readFromPty()!;
        self.drawScrollback()!;
        self.drawCursor()!;

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
                { self.leftPadding, self.window.height - self.atlas.maxHeight*i - self.window.top - self.topPadding },
                self.atlas)!;
    }
}

fn void! Term.drawCursor(&self) {
    self.window.renderText(
            { self.cursor.form },
            { self.cursor.x, self.cursor.y },
            self.atlas)!;
}

fn void! Term.processInput(&self) {
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

    // backspace
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

