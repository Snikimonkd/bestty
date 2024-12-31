module bestty;

import std::io;

import pty;
import logger;
import window;

fn int main(String[] args) {
    if (catch err = logger::open()) {
        io::printfn("init logger err: %s", err);
        return -1;
    }
    defer logger::close();

    pty::Pty! pty = pty::open();
    if (catch err = pty) {
        io::printfn("open err: %s", err);
        return -1;
    }

     if (catch err = window::run(pty)) {
         io::printfn("run window err: %s", err);
         return -1;
     }

     return 0;
}
