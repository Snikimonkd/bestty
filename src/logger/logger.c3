module logger;

module std::io::file;
module std::io;

File out;

fn void! open() {
    out = file::open("lek", "w")!;
}

fn void! write(char[] text) {
    out.write(text)!;
}
