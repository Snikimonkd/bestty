module parser;

import logger;
import std::collections::list;

def UTF8String = List(<Char32>);

fault ScrollbackError {
    UNIMPLEMENTED_ACTION,
}

struct Scrollback {
    // TODO for now dstring is ok, need to change to something more efficient like linkedlist of dstrings array maybe?
    List(<Char32>) buf;
}

fn void Scrollback.init(&self, Allocator allocator = allocator::heap()) {
    self.buf.new_init(1024, allocator);
}

fn void Scrollback.destroy(&self) {
    self.buf.free();
}

fn void! Scrollback.handle(&self, PtyAction action) {
    switch (action.type) {
        case PRINT:
            // todo skip for now because raylib stops printing after \0 in string
//            if (action.payload.print == '\0') {
//                return;
//            }
            logger::printfn("print: %s, %c", (Char32)action.payload.print, (Char32)action.payload.print);
            self.buf.push((Char32)action.payload.print);
            return;
        case NONE:
            return;
        case EXECUTE:
            self.handle_execute(action.payload.execute)!!;
            logger::printfn("print: %s", (Char32)action.payload.print);
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
            self.buf.push('\n');
        case '\t':
            // todo: handle this
            self.buf.push('\t');
        case '\b':
            self.buf.pop()!;
        default:
            logger::printfn("unknown execute action: %d", c);
            return;
    }
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
