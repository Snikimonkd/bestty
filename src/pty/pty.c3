module pty;

import std::io;
import std::os;
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

fn void! open() {
    Allocator allocator = allocator::heap();

    Fd master;
    Winsize ws = Winsize{};

    int pid = forkpty(&master, null, null, &ws);
    if (pid == -1) {
        io::printfn("error");
        return;
    }

    // child
    if (pid == 0) {
        String sh = env::get_var("SHELL", allocator)!;
        defer (void)free(sh);

        ZString*[] args = {&&((ZString)sh), null};

        CInt res = execvp((ZString)sh, args);
        if (res == -1) {
            return PtyError.EXEC_SHELL_ERROR?;
        }

        thread::sleep(5*time::SEC);
        return;
    }

    thread::sleep(5*time::SEC);

    const usz TMP_SIZE = 1000;
    char* buf = allocator::malloc_try(allocator::heap(), TMP_SIZE+1)!;

    isz res = libc::read(master, buf, TMP_SIZE);
    io::printfn("read: res: %d", res);
    io::printfn("read: buf: %s", (ZString)buf);

    res = libc::write(master, "pwd\n", 4);
    io::printfn("write: res: %d", res);

    res = libc::read(master, buf, TMP_SIZE);
    io::printfn("read: res: %d", res);
    io::printfn("read: buf: %s", (ZString)buf);
}
