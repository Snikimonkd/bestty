module bestty;

import std::io;

import pty;
import logger;

fn int main(String[] args) {
    if (catch excuse = logger::open()) {
        io::printfn("init logger excuse: %s", excuse);
    }
    defer logger::close();

    if (catch excuse = pty::open()) {
        io::printfn("open excuse: %s", excuse);
    }

    return 0;
}
