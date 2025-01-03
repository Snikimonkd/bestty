module chan;

import std::thread;
import std::time;
import std::collections::linkedlist;

fault ChanErr {
    CHAN_EMPTY,
}

// simple go-like channel
struct Chan {
    LinkedList(<char>) ll;
    thread::Mutex m;
}

fn Chan! init() {
    Chan c;
    c.ll.new_init();
    c.m.init()!!;
    return c;
}

fn void! Chan.push(&self, char c) {
    self.m.lock()!!;
    defer self.m.unlock()!!;
    // push to linked list
    self.ll.push_front(c);
}

fn char! Chan.pop(&self) {
    self.m.lock()!!;
    defer self.m.unlock()!!;
    char! c = self.ll.pop();
    if (catch err = c) {
        if (err == IteratorResult.NO_MORE_ELEMENT) {
            return ChanErr.CHAN_EMPTY?;
        }
        return err?;
    }

    return c;
}

fn void! Chan.push_str(&self, ZString str) {
    self.m.lock()!!;
    defer self.m.unlock()!!;

    for (int i = 0; i < str.char_len(); i++) {
        char c = str[i];
        self.ll.push_front(c);
    }
}
