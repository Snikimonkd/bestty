module pty;

import logger;

import std::io;
import std::os;
import std::net::os;
import libc;
import std::time;
import std::thread;
import std::os::env;

fault PtyError {
    FORK_ERROR,
    WRITE_ERROR,
    EXEC_SHELL_ERROR,
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
extern fn int ioctl(CInt socket, int cmd, ...);
extern fn int fcntl(CInt socket, int cmd, ...);

const int F_GETFD = 1;
const int F_SETFD = 2;
const int F_GETFL = 3;
const int F_SETFL = 4;

fn void! open() {
    Allocator allocator = allocator::heap();

    Fd master;
    Winsize ws = Winsize{};

    int pid = forkpty(&master, null, null, &ws);
    if (pid == -1) {
        logger::printfn("can't fork pty");
        io::printfn("error");
        return;
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

        return;
    }
    thread::sleep(2*time::SEC);

    int flags = fcntl(master, F_GETFL, 0);
    if (flags == -1) {
        io::printfn("err, %d", (int)libc::errno());
        return;
    }

    int a = fcntl(master, F_SETFL, flags | os::O_NONBLOCK);
    if (a == -1) {
        logger::printfn("can't set flags: %s", libc::errno());
        return;
    }

    const usz TMP_SIZE = 10000;
    char* buf = allocator::malloc_try(allocator::heap(), TMP_SIZE+1)!;

    isz res = libc::read(master, buf, TMP_SIZE);
    if (res == -1) {
        logger::printfn("errno: %s", libc::errno());
        return;
    } else {
        logger::printfn("shel init: %s", ((ZString)buf).str_view());
    }

    logger::printfn("first read");
    res = libc::read(master, buf, TMP_SIZE);
    if (res == -1) {
        logger::printfn("first read errno: %s", libc::errno());
    } else {
        logger::printfn("first read: %s",  ((ZString)buf).str_view());
    }

    String cmd = "git config\n";
    res = libc::write(master, cmd, cmd.len);
    if (res != cmd.len) {
        logger::printfn("errno: %s", libc::errno());
        return;
    }

    thread::sleep(6*time::SEC);
    logger::printfn("second read");
    for (int i = 0; i < 10; i++) {
        res = libc::read(master, buf, TMP_SIZE);
        if (res != -1) {
            logger::printfn("second read: %s",  ((ZString)buf).str_view());
            continue;
        }

        if (libc::errno() == errno::EAGAIN) {
            logger::printfn("eagain, i: %s", i);
            thread::sleep(time::SEC);
            continue;
        }

        logger::printfn("errno: %s", libc::errno());
        return;
    }
}
