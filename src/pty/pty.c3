module pty;

import logger;

import std::os::env;
import std::net::os;
import std::net;
import std::time;
import std::thread;
import std::collections::list;
import libc;

const usz BUF_SIZE = 1024;

fault PtyError {
    EXEC_SHELL_ERROR,
    FORK_ERROR,
    WRITE_ERROR,
    PTY_NOT_READY,
    READ_ERROR,
    GET_FLAGS_ERROR,
    SET_FLAGS_ERROR,

    EMPTY,
}

def Fd = CInt;

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

extern fn CInt forkpty(CInt *amaster, char *name, Termios *termp, Winsize *winp);
extern fn CInt execvp(ZString path, ZString*[] argv);
extern fn int fcntl(CInt socket, int cmd, ...);

const int F_GETFD = 1;
const int F_SETFD = 2;
const int F_GETFL = 3;
const int F_SETFL = 4;

struct Pty {
    Fd master;
}

fn Pty! init() {
    Fd master;
    Winsize ws = Winsize{};
    // TODO: termios

    int pid = forkpty(&master, null, null, &ws);
    if (pid == -1) {
        logger::printfn("can't fork pty");
        return PtyError.FORK_ERROR?;
    }

    // child
    if (pid == 0) {
//        String sh = env::get_var("SHELL", allocator)!;
//        defer free(sh);
//        ZString*[] tmp = {&&((ZString)sh), null};
        env::set_var("BASH_SILENCE_DEPRECATION_WARNING", "1", true);
        env::set_var("PS1", "$ ", true);
        ZString*[] tmp = {&&((ZString)"bash"), null};
        CInt res = execvp(*tmp[0], tmp);
        if (res == -1) {
            logger::printfn("[SLAVE] can't exec shell");
            return PtyError.EXEC_SHELL_ERROR?;
        }

        thread::sleep(time::SEC);
        logger::printfn("[SLAVE] i can't be here");
    }

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

    return { .master = master };
}

fn DString! Pty.read(&self) {
    DString res;

    Poll[] polls = {
        {
            .socket = (NativeSocket)self.master,
            .events = net::SUBSCRIBE_READ,
        },
    };

    ulong n = net::poll(polls, 0)!!;
    if (n != 1 || polls[0].revents != net::POLL_EVENT_READ) {
//        logger::printfn("read poll res n: %s, revents: %s", n, polls[0].revents);
        return PtyError.EMPTY?;
    }

    char[BUF_SIZE] buf;
    isz s = libc::read(self.master, &buf, BUF_SIZE);
    if (s == -1 && libc::errno() != errno::EAGAIN) {
        logger::printfn("error while reading errno: %s", libc::errno());
        return PtyError.READ_ERROR?;
    }
    if (s == 0) {
        return PtyError.EMPTY?;
    }

    res.append_chars((String)buf[0..s-1]);
    return res;
}

fn void! Pty.write(&self, ZString cmd) {
    Poll[] polls = {
        {
            .socket = (NativeSocket)self.master,
            .events = net::SUBSCRIBE_WRITE,
        },
    };

    ulong n = net::poll(polls, 0)!!;
    if (n != 1 || polls[0].revents != net::POLL_EVENT_WRITE) {
        logger::printfn("write poll res n: %s, revents: %s", n, polls[0].revents);
        return PtyError.PTY_NOT_READY?;
    }


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

