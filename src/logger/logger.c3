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

// logger::printfn("errno: %d", libc::errno());
// errno: <INVALID>
fn void printfn(String format, args...) {
    if (catch excuse = io::fprintfn(&out, format, args)) {
        io::printfn("can't write to log: %s", excuse);
    }
}

