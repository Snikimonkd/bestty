module bestty;

import std::io;
import std::thread;
import std::time;
import logger;

import pty;
import parser;
import chan;
import terminal;

fn int main(String[] args) {
    logger::open()!!;
    defer logger::close();

    pty::Pty! pty = pty::init();
    if (catch err = pty) {
        io::printfn("can't init pty: %s", err);
        return -1;
    }

    parser::Parser parser = {};

    terminal::Terminal terminal = terminal::init(pty, parser);
    terminal.run()!!;

    return 0;
}
