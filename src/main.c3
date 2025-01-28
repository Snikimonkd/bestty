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
        //    pty::Pty! pty = pty::init();
        //    if (catch err = pty) {
        //        io::printfn("can't init pty: %s", err);
        //        return -1;
        //    }
        //
        //    parser::Parser parser = { .state = parser::State.GROUND };
        //
        //    terminal::Terminal terminal = terminal::init(pty, parser);
        //    terminal.run()!!;

        Term term;
        term.init()!!;
        defer term.destroy();

        term.run()!!;
    };

    return 0;
}
