module parser;

import logger;

fault ScrollbackError {
    UNIMPLEMENTED_ACTION,
}

struct Scrollback {
    // TODO for now dstring is ok, need to change to something more efficient like linkedlist of dstrings maybe?
    DString buf;
}

fn void! Scrollback.handle(&self, PtyAction action) {
    switch (action.type) {
        case PRINT:
            // todo skip for now because raylib stops printing after \0 in string
            if (action.payload.print == '\0') {
                return;
            }
            self.buf.append_char(action.payload.print);
            return;
        case NONE:
            return;
        default:
            // TODO for now just ignore evrething
            logger::printfn("unknown scrollback action: %s", action.type);
            return;
    }
}

// returns the printable scrollback
// todo:  maybe handle the size of window here?
fn DString Scrollback.to_print(&self) {
    return self.buf;
}
