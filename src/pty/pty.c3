module pty;

import logger;

import std::io;
import std::os;
import std::os::env;
import std::net::os;
import std::time;
import std::thread;

import libc;

const usz BUF_SIZE = 128;

fault PtyError {
    EXEC_SHELL_ERROR,
    FORK_ERROR,
    WRITE_ERROR,
    READ_ERROR,
    GET_FLAGS_ERROR,
    SET_FLAGS_ERROR,

    EMPTY,
}

enum Key : ushort (ushort code) {
    UP = 201,
}

def Fd = CInt;

struct Pty {
    Fd master;
}

fn void! Pty.init(&self, Fd master) {
    int flags = fcntl(master, F_GETFL, 0);
    if (flags == -1) {
        logger::printfn("can't get master fd flags: %s", libc::errno());
        return PtyError.GET_FLAGS_ERROR?;
    }

    int a = fcntl(master, F_SETFL, flags | os::O_NONBLOCK);
    if (a == -1) {
        logger::printfn("can't set master fd flags: %s", libc::errno());
        return PtyError.SET_FLAGS_ERROR?;
    }

    *self = { .master = master };
    return;
}

fn void prt(char* str, int len) {
    logger::printfn("################");
    for (int i = 0; i < len; i++) {
        logger::printf("%c",str[i]);
    }
    logger::printfn("\n################");
    for (int i = 0; i < len; i++) {
        logger::printf("%s,",str[i]);
    }
    logger::printfn("\n################");
}

fn char! Pty.readChar(&self) {
    char c;
    isz res = 0;
    while(res != 1) {
        res = libc::read(self.master, &c, 1);
        if (res == -1 && libc::errno() != errno::EAGAIN) {
            logger::printfn("can't read from master fd: %s", libc::errno());
            return PtyError.READ_ERROR?;
        }
        if (res == 0 || (res == -1 && libc::errno() == errno::EAGAIN)) {
            return PtyError.EMPTY?;
        }
    }

    return c;
}

fn DString! Pty.read(&self) {
    DString res;
    while (true) {
        char! c = self.readChar();
        if (catch err = c) {
            if (err == PtyError.EMPTY) {
                return res;
            }
            return err?;
        }

        // FIXME - don't skip
        if (c < 256 && c != '\x1B' && c != '\x1b' && c != '\r') {
            res.append_char(c);
        }
    }
}

fn void! Pty.write(&self, ZString cmd) {
    isz written = 0;
    isz len = cmd.char_len();
    while (written < len) {
        isz res = libc::write(self.master, (char*)cmd[written:len], len-written);
        if (res == -1) {
            logger::printfn("can't write to master fd: %s", libc::errno());
            return PtyError.WRITE_ERROR?;
        }
        written += res;
    }
    logger::printfn("successfult written: %s", cmd);

    return;
}

struct Termios {
    //    tcflag_t        c_iflag;
    //    tcflag_t        c_oflag;
    //    tcflag_t        c_cflag;
    //    tcflag_t        c_lflag;
    uint        c_iflag;
    uint        c_oflag;
    uint        c_cflag;
    uint        c_lflag;

    // cc_t            c_cc[NCCS];
    uint[16]            c_cc;

    // uint32_t        reserved[3];
    uint[3]        reserved;

    // speed_t         c_ispeed;
    // speed_t         c_ospeed;
    uint         c_ispeed;
    uint         c_ospeed;
}

struct Winsize {
    ushort ws_row;	/* rows, in characters */
    ushort ws_col;	/* columns, in characters */
    ushort ws_xpixel;	/* horizontal size, pixels */
    ushort ws_ypixel;	/* vertical size, pixels */
}

// struct FdSet {
//     CInt[32] fds_bits;
// }
//
// struct Timeval {
//     long    tv_sec;
//     long    tv_usec;
// }

// extern fn void fd_set(CInt fd, FdSet *set) @extern("__darwin_fd_set");
// extern fn void fd_zero(FdSet *set, isz s) @extern("bzero");
// extern fn int fd_isset(CInt fd, FdSet *set) @extern("FD_ISSET");

extern fn CInt forkpty(CInt *amaster, char *name, Termios *termp, Winsize *winp);
extern fn CInt execvp(ZString path, ZString*[] argv);
extern fn int fcntl(CInt socket, int cmd, ...);

const int F_GETFD = 1;
const int F_SETFD = 2;
const int F_GETFL = 3;
const int F_SETFL = 4;

fn Pty! open() {
    Allocator allocator = allocator::heap();

    Fd master;
    Winsize ws = Winsize{};

    int pid = forkpty(&master, null, null, &ws);
    if (pid == -1) {
        logger::printfn("can't fork pty");
        io::printfn("error");
        return PtyError.FORK_ERROR?;
    }

    // child
    if (pid == 0) {
//        String sh = env::get_var("SHELL", allocator)!;
//        defer (void)free(sh);
//        ZString*[] args = {&&((ZString)sh), null};

        env::set_var("BASH_SILENCE_DEPRECATION_WARNING", "1", true);
        ZString*[] tmp = {&&((ZString)"sh"), null};
        CInt res = execvp(*tmp[0], tmp);
        if (res == -1) {
            logger::printfn("[SLAVE] can't exec shell");
            return PtyError.EXEC_SHELL_ERROR?;
        }

        thread::sleep(time::SEC);
        logger::printfn("[SLAVE] i can't be here");
    }

    Pty pty;
    pty.init(master)!;

   // thread::sleep(2*time::SEC);
   // DString shell_init;
   // defer shell_init.free();
   // while FOO: (true) {
   //     char! c = pty.read_key();
   //     if (catch err = c) {
   //         switch (err) {
   //             case PtyError.EMPTY:
   //                 break FOO;
   //             case PtyError.CONTROL:
   //                 continue;
   //             default:
   //                 return err?;
   //         }
   //     }
   //     switch ((char)c) {
   //         case Key.UP.code:
   //             // todo
   //         default:
   //             shell_init.append_char(c);
   //     }
   // }
   // logger::printf("%s", shell_init);

   // // write
   // pty.write("ls -lah\n")!;

   // thread::sleep(2*time::SEC);

   // DString cmd_res;
   // defer cmd_res.free();
   // while (true) {
   //     char! c = pty.read_key();
   //     if (catch err = c) {
   //         if (err == PtyError.EMPTY) {
   //             logger::printfn("nothing to read");
   //             break;
   //         } else if (err == PtyError.CONTROL) {
   //             continue;
   //         } else {
   //             return err?;
   //         }
   //     }
   //     switch (c) {
   //         case Key.UP.code:
   //         // todo
   //         default:
   //         cmd_res.append_char(c);
   //     }
   // }
    // logger::printf("%s", cmd_res);
    return pty;
}
