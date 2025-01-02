module parser;

import std::io;

// https://vt100.net/emu/dec_ansi_parser

fault ParserError {
    UNIMPLEMENTED_STATE,
    UNIMPLEMENTED_PARSER_ACTION,
}

enum State {
    GROUND,
    ESCAPE,
    ESCAPE_INTERMEDIATE,
    CSI_ENTRY,
    SOS_PM_APC,
}

struct Parser {
    State state;

    char[4] collector;
    int collector_len;
    char final;
}

fn Parser Parser.init(&self) {
    *self = { .state = GROUND };
    return *self;
}

enum ActionType {
    NONE,
    PRINT,
    COLLECT,
    ESC_DISPATCH,
    EXECUTE,
}

struct EscDispatch {
    char[] intermediates;

    char final;
}

union ActionData {
    // none
    char print;
    EscDispatch esc_dispatch;
    char execute;
}

struct Action {
    ActionType type;
    ActionData data;
}

fn Action! Parser.next(&self, char c) {
    ActionType! action;
    switch (self.state) {
        case GROUND:
            action = self.next_from_ground(c);
        case ESCAPE:
            action = self.next_from_escape(c);
        case ESCAPE_INTERMEDIATE:
            action = self.next_from_escape_intermediate(c);
        case CSI_ENTRY:
            action = self.next_from_csi_entry(c);
        case SOS_PM_APC:
            action = self.next_from_sos_pm_apc(c);
        default:
            action = ParserError.UNIMPLEMENTED_STATE?;
    }

    if (catch err = action) {
        return err?;
    }

    switch (action) {
        case COLLECT:
            self.collector[self.collector_len] = c;
            self.collector_len+=1;
            return Action{ .type = NONE };
        case PRINT:
            return Action{ .type = PRINT, .data = { .print = c } };
        case NONE:
            return Action{ .type = NONE };
        case EXECUTE:
            return Action{ .type = EXECUTE, .data = { .execute = c } };
        case ESC_DISPATCH:
            self.final = c;
            return Action{
                .type = ESC_DISPATCH,
                .data = {
                    .esc_dispatch = {
                        .intermediates = self.collector[0..self.collector_len],
                        .final = self.final,
                    }
                }
            };
        default:
            return ParserError.UNIMPLEMENTED_PARSER_ACTION?;
    }
}

fn ActionType! Parser.next_from_ground(&self, char c) {
    switch (true) {
        case (c >= 0x20 && c <= 0x7f):
            return PRINT;
        case (c == 0x1b):
            // TODO: clean collectors
            self.state = ESCAPE;
            return NONE;
        case (/* c >= 0x0 && */ c <= 0x17 || c == 0x19 || c >= 0x1c || c <= 0x1f):
            return EXECUTE;
        default:
            io::printfn("ground unexpected char: %c", c);
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

fn ActionType! Parser.next_from_escape(&self, char c) {
    switch (true) {
        case (/* c >= 0x0 && */ c <= 0x17 || c == 0x19 || c >= 0x1c || c <= 0x1f):
            return EXECUTE;
        case (c == 0x7f):
            return NONE;
        case (c >= 0x30 && c <= 0x4f || c >= 0x51 && c <= 0x57 || c == 0x5a || c == 0x5c || c >= 0x60 && c <= 0x7e):
            return ESC_DISPATCH;
        case (c >= 0x20 && c <= 0x2f):
            self.state = ESCAPE_INTERMEDIATE;
            return COLLECT;
        case (c == 0x58 || c == 0x5e || c == 0x5f):
            self.state = SOS_PM_APC;
            return NONE;
        case (c == 0x5b):
            self.state = CSI_ENTRY;
            return NONE;
            // 50, 5d
        default:
            io::printfn("escape unexpected char: %c", c);
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

fn ActionType! Parser.next_from_escape_intermediate(&self, char c) {
    switch (true) {
        case (/* c >= 0x0 && */ c <= 0x17 || c == 0x19 || c >= 0x1c || c <= 0x1f):
            return EXECUTE;
        case (c >= 0x20 && c <= 0x2f):
            return COLLECT;
        case (c == 0x7f):
            return NONE;
        case (c >= 0x30 && c <= 0x7e):
            self.state = GROUND;
            return ESC_DISPATCH;
        default:
            io::printfn("escape intermediate unexpected char: %c", c);
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

fn ActionType! Parser.next_from_csi_entry(&self, char c) {
    switch (true) {
        default:
            io::printfn("csi entry unexpected char: %c", c);
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

fn ActionType! Parser.next_from_sos_pm_apc(&self, char c) {
    switch (true) {
        default:
            io::printfn("sos/pm/apc unexpected char: %c", c);
            return ParserError.UNIMPLEMENTED_STATE?;
    }
}

