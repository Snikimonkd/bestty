module scrollback;

import ring;
import logger;
import parser;

import std::collections::list;

faultdef
    UNIMPLEMENTED_ACTION;

struct Cursor {
    Char32 form;
    usz x;
    usz y;
}

struct Scrollback {
    // Ring(<UTF8String>) lines;
    Char32[][] lines;
    Cursor cursor;
    usz width;
    usz height;
    Allocator allocator;
}

fn void Scrollback.init(&self, usz width, usz height, Allocator allocator = allocator::heap()) {
    logger::printfn("[scrollback] width: %s, height: %s", width, height);
    self.allocator = allocator;
    self.width = width;
    self.height = height;
    self.lines = allocator::new_array(allocator, Char32[], height);
    for (usz i = 0; i < height; i++) {
        // one more for '\0'
        self.lines[i] = (Char32[])allocator::new_array(allocator, Char32, width+1);
    }
    self.cursor = {
        .form = '█',
        .x = 0,
        .y = 0,
    };
}

fn void Scrollback.destroy(&self) {
    for (usz i = 0; i < self.height; i++) {
        allocator::free(self.allocator, self.lines[i]);
    }
    allocator::free(self.allocator, self.lines);
}

fn void? Scrollback.handle(&self, PtyAction action) {
    switch (action.type) {
        case PRINT:
            self.push((Char32)action.payload.print)!;
            return;
        case NONE:
            return;
        case EXECUTE:
            self.handle_execute(action.payload.execute)!!;
            // logger::printfn("print: %s", (Char32)action.payload.print);
            return;
        default:
            // TODO for now just ignore evrething
            logger::printfn("unknown scrollback action: %s", action.type);
            return;
    }
}

fn void? Scrollback.spin(&self) {
    // empty the first line
    self.lines[0][0] = '\0';
    // make the last line empty
    Char32[] tmp = self.lines[0];
    for (usz i = 0; i < self.height-1; i++) {
        self.lines[i] = self.lines[i+1];
    }
    self.lines[self.height-1] = tmp;
}

fn void? Scrollback.handle_execute(&self, char c) {
    switch (c) {
        case '\n':
            // end current line
            self.lines[self.cursor.y][self.cursor.x] = '\n';

            // move cursor to the next line
            self.cursor.x = 0;
            // if elaready on the last line
            if (self.cursor.y == self.height-1) {
                self.spin()!;
            } else {
                self.cursor.y++;
            }
        case '\t':
            // todo: handle this
            self.push('\t')!;
        case '\b':
            // wtf???
            logger::printfn("unexpected b");
        default:
            logger::printfn("unknown execute action: %d", c);
            return;
    }
}

fn void? Scrollback.push(&self, Char32 c) {
    if (self.cursor.x == self.width-1) {
        // handle line wrapping
        self.cursor.x = 0;
        if (self.cursor.y == self.height-1) {
            self.spin()!;
        } else {
            self.cursor.y++;
        }
        self.lines[self.cursor.y][self.cursor.x] = c;
        self.lines[self.cursor.y][self.cursor.x+1] = '\0';
    } else {
        self.lines[self.cursor.y][self.cursor.x] = c;
        self.lines[self.cursor.y][self.cursor.x+1] = '\0';
    }
    self.cursor.x++;
}

