module logger;

import std::io;
import std::io::file;
import std::os;
import libc;

io::File out;

fn void! open() {
    out = file::open("bestty.log", "w")!;
}

fn void close() {
    if (catch excuse = out.close()) {
        io::printf("can't close log file: %v", excuse);
    }
}

fn void printfn(String format, args...) {
    io::printfn(format, ...args);
    if (catch err = io::fprintfn(&out, format, ...args)) {
        io::printfn("logger printfn error: err: %s", err);
    }
}

fn void printf(String format, args...) {
    io::printf(format, ...args);
    if (catch err = io::fprintf(&out, format, ...args)) {
        io::printfn("logger printf error: err: %s", err);
    }
}

