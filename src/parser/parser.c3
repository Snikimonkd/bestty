module parser;

import std::io;

// https://vt100.net/emu/dec_ansi_parser

fault ParserError {
    UNIMPLEMENTED_STATE,
    UNIMPLEMENTED_ACTION,
}

struct Esc {
    int i;
}

enum State {
    GROUND,
    ESC,
}

struct Parser {
    State state;

    Esc esc;
}

fn Parser Parser.init(&self) {
    *self = { .state = GROUND };
    return *self;
}

enum ActionType {
    NONE,
    PRINT,
    ESC,
}

union ActionData {
    // none
    char print;
    Esc esc;
}

struct Action {
    ActionType type;
    ActionData data;
}

fn Action! Parser.next(&self, char c) {
    switch (self.state) {
        case GROUND:
            return self.next_from_ground(c);
        case ESC:
            return self.next_from_esc(c);
        default:
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

fn Action! Parser.next_from_ground(&self, char c) {
    switch (true) {
        case (c >= 0x20 && c <= 0x7f):
            return Action{ .type = ActionType.PRINT, .data = { .print = c } };
        case (c == 0x1b):
            // TODO: clean esc buffers
            self.state = ESC;
            return Action{ .type = ActionType.NONE };
        default:
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

fn Action! Parser.next_from_esc(&self, char c) {
    switch (true) {
//        case (c <= 0x17 || c == 0x19 || (c >= 0x1c && c <= 0x1f)):
//            io::printfn("todo execute escape seq");
//            return ParserError.UNIMPLEMENTED?;
        case (c == 0x7f):
            self.state = GROUND;
            return Action{ .type = ActionType.NONE };
//        case (c == 0x5b):
//            io::printfn("move to csi entry", c);
//            return Action{ .type = ActionType.PRINT, .data = { .print = { .c = c } } };
//            return Action{.action = ActionU{ .clear = ClearAction{}}, .new_state = &csi_entry_state};
        default:
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

