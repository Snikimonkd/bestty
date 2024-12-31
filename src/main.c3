module bestty;

import std::io;

import pty;
import logger;
import window;
import parser;

fn int main(String[] args) {
    ZString tmp = "hello world\x1b";

    parser::Parser p;
    p.init();

    for (int i = 0; i < tmp.char_len(); i++) {
        parser::Action! action = p.next(tmp[i]);
        if (catch err = action) {
            io::printfn("err: %s", err);
            return -1;
        }

        switch (action.type) {
            case PRINT:
                io::printf("%c", action.data.print);
            case NONE:
                io::printfn("none");
            default:
                io::printfn("unknwon action: %s", action.type);
                return -1;
        }
    }
    return 0;
//    if (catch err = logger::open()) {
//        io::printfn("init logger err: %s", err);
//        return -1;
//    }
//    defer logger::close();
//
//    pty::Pty! pty = pty::open();
//    if (catch err = pty) {
//        io::printfn("open err: %s", err);
//        return -1;
//    }
//
//     if (catch err = window::run(pty)) {
//         io::printfn("run window err: %s", err);
//         return -1;
//     }
//
//     return 0;
}
