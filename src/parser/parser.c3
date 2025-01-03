module parser;

import std::io;

fault ParserError {
    UNIMPLEMENTED_PARSER_ACTION,
    UNIMPLEMENTED_PARSER_STATE,
}

struct Parser {
    State state;

    char[4] intermediates;
    int intermediates_idx;
}

struct EscDispatch {
    char[] intermediates;
}

union ActionPayload {
    // none
    char print;
    char execute;
    EscDispatch esc_dispatch;
}

struct PtyAction {
    Action type;
    ActionPayload payload;
}

fn PtyAction! Parser.next(&self, char c) {
    Transition transition = t[c][self.state.ordinal];

    // exit old state and entry new state
    if (self.state != transition.state) {
        self.exit_old_state()!!;
        self.entry_new_state(transition.state)!!;
    }

    self.state = transition.state;

    // handle action
    switch (transition.action) {
        case PRINT:
            return { .type = PRINT, .payload = { .print = c } };
        default:
            return ParserError.UNIMPLEMENTED_PARSER_ACTION?;
    }
}

fn void! Parser.exit_old_state(&self) {
    switch (self.state) {
        default:
            return ParserError.UNIMPLEMENTED_PARSER_STATE?;
    }
}

fn void! Parser.entry_new_state(&self, State new_state) {
    switch (new_state) {
        default:
            return ParserError.UNIMPLEMENTED_PARSER_STATE?;
    }
}
