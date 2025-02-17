module scrollback;

import ring;
import logger;
import parser;

import std::collections::list;

def UTF8String = List(<Char32>);

fault ScrollbackError {
    UNIMPLEMENTED_ACTION,
}

struct Cursor {
    Char32 form;
    int x;
    int y;
}

struct Scrollback {
    Ring(<UTF8String>) buf;
    Cursor cursor;
}

fn void Scrollback.init(&self, usz size, Allocator allocator = allocator::heap()) {
    self.buf.init(size, allocator);
    self.cursor = {
        .form = '█',
        .x = 0,
        .y = 0,
    };
}

/// fn void! Term.drawCursor(&self) {
///     self.window.renderText(
///             { self.cursor.form },
///             { self.cursor.x, self.cursor.y },
///             self.atlas)!;
/// }

fn void Scrollback.destroy(&self) {
    self.buf.destroy();
}

fn void! Scrollback.handle(&self, PtyAction action) {
    switch (action.type) {
        case PRINT:
            self.push((Char32)action.payload.print);
            // logger::printfn("print: %s, %c", (Char32)action.payload.print, (Char32)action.payload.print);
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

fn void! Scrollback.handle_execute(&self, char c) {
    switch (c) {
        case '\n':
            self.cursor.x = 0;
            self.cursor.y += 1;
            self.buf.push("");
        case '\t':
            // todo: handle this
            self.push('\t');
        case '\b':
            self.buf.pop();
        default:
            logger::printfn("unknown execute action: %d", c);
            return;
    }
}

fn void Scrollback.push(&self, Char32 c) {
    if (self.buf.buf[self.cursor.y].len() < self.cursor.x) {
        self.buf.buf[self.cursor.y].push(c);
        return;
    }

    self.buf.buf[self.cursor.y].insert_at(c, self.cursor.x);
}

fn List(<UTF8String>) Scrollback.render(&self, usz width, usz height, Allocator allocator = allocator::heap()) {
    List(<UTF8String>) ret;
    ret.new_init(256, allocator);
    UTF8String str;
    str.new_init(256, allocator);
    for (long i = self.buf.len()-1; i >= 0; i--) {
        if (ret.len() == height) {
            str.free();
            ret.reverse();
            return ret;
        }
        // TODO: line wrapping
        if (self.buf[i] == '\n') {
            str.reverse();
            ret.push(str);
            UTF8String tmp;
            tmp.new_init(256, allocator);
            str = tmp;
        } else {
            str.push(self.buf[i]);
        }
    }

    str.reverse();
    ret.push(str);

    ret.reverse();
    return ret;
}
