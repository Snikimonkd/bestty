module bestty;

import std::io;
import std::thread;
import std::time;

import logger;
import pty;
import parser;
import terminal;

fn int main(String[] args) {
    mem::@report_heap_allocs_in_scope() {
        logger::open()!!;
        defer logger::close();

        //
        //    parser::Parser parser = { .state = parser::State.GROUND };
        //
        //    terminal::Terminal terminal = terminal::init(pty, parser);
        //    terminal.run()!!;

        Term term;
        term.init(32)!!;
        defer term.destroy();

        term.run()!!;
    };

    return 0;
}
