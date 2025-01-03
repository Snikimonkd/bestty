module bestty;

import std::io;
import std::thread;
import std::time;
import logger;

import pty;
import parser;
import chan;
import window;

fn int main(String[] args) {
    logger::open()!!;
    defer logger::close();

    thread::ConditionVariable cond;
    cond.init()!!;

    pty::Pty! pty = pty::init();
    if (catch err = pty) {
        io::printfn("can't init pty: %s", err);
        return -1;
    }

    window::Window window = window::init(pty);

    parser::Parser parser = {};

    window.run()!!;

   // ZString tmp = "hello\n world\x1b";

   // parser::Parser p;

   // for (int i = 0; i < tmp.char_len(); i++) {

   // }

   // if (catch err = window::run()) {
   //     io::printfn("run window err: %s", err);
   //     return -1;
   // }

    return 0;
}
