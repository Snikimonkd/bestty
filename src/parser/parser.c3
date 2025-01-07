module parser;

import logger;

fault ParserError {
    UNIMPLEMENTED_PARSER_ACTION,
    UNIMPLEMENTED_PARSER_STATE,
}

struct Parser {
    State state;

    char[4] intermediates;
    int intermediates_idx;

    ushort param;
    ushort[16] params;
    int params_idx;
}

struct EscDispatch {
    char[] intermediates;
}

struct CsiDispatch {
    char[] intermediates;
    ushort[] params;
    char final;
}

union ActionPayload {
    char print;
    char execute;
    EscDispatch esc_dispatch;
    CsiDispatch csi_dispatch;
}

struct PtyAction {
    Action type;
    ActionPayload payload;
}

fn PtyAction! Parser.next(&self, char c) {
    Transition transition = t[c][self.state.ordinal];
    logger::printfn("from: %s with char: %d to: %s, with action: %s", self.state, c, transition.state, transition.action);

    // exit old state and entry new state
    if (self.state != transition.state) {
        // handle exit
        self.exit_old_state()!!;
        // handle entry
        self.entry_new_state(transition.state)!!;
        self.state = transition.state;
    }

    // handle action
    return self.handle_action(transition.action, c);
}

fn void! Parser.exit_old_state(&self) {
    switch (self.state) {
        case GROUND:
            return;
        case ESCAPE:
            return;
        case CSI_ENTRY:
            return;
        case CSI_PARAM:
            return;
        default:
            logger::printfn("can't exit parser state: %s", self.state);
            return ParserError.UNIMPLEMENTED_PARSER_STATE?;
    }
}

fn void! Parser.entry_new_state(&self, State new_state) {
    switch (new_state) {
        case GROUND:
            return;
        case ESCAPE:
            self.intermediates_idx = 0;
            return;
        case CSI_ENTRY:
            self.intermediates_idx = 0;
            self.param = 0;
            self.params_idx = 0;
            return;
        case CSI_PARAM:
            return;
        default:
            logger::printfn("can't entry parser state: %s", new_state);
            return ParserError.UNIMPLEMENTED_PARSER_STATE?;
    }
}

fn PtyAction! Parser.handle_action(&self, Action action, char c) {
    switch (action) {
        case PRINT:
            return { .type = PRINT, .payload = { .print = c } };
        case NONE:
            return { .type = NONE };
        case COLLECT:
            // just in case check the len
            if (self.intermediates_idx >= 4) {
                logger::printfn("intermediates_idx is too high");
                return { .type = NONE};
            }
            self.intermediates[self.intermediates_idx] = c;
            self.intermediates_idx += 1;
            return { .type = NONE };
        case PARAM:
            // if we meet separator -> we need to store param and move to the next
            if (c == ';' || c == ':') {
                // just in case check the len
                if (self.params_idx >= 16) {
                    logger::printfn("params_idx is too high");
                    return { .type = NONE};
                };

                // save param
                self.params[self.params_idx] = self.param;
                self.params_idx += 1;
                // reset param acc
                self.param = 0;
                return { .type = NONE };
            }

            self.param *= 10;
            self.param += c - '0';
            return { .type = NONE };
        case CSI_DISPATCH:
            // if we have any param in progress - store it
            if (self.param != 0) {
                self.params[self.params_idx] = self.param;
            }
            return {
                .type = CSI_DISPATCH,
                    .payload = {
                        .csi_dispatch = {
                            .intermediates = self.intermediates[0..self.intermediates_idx],
                            .params = self.params[0..self.params_idx],
                            .final = c,
                        }
                    }
            };
        case EXECUTE:
            return { .type = EXECUTE, .payload = { .execute = c } };
        default:
            logger::printfn("unknown parser action: %s", action);
            return ParserError.UNIMPLEMENTED_PARSER_ACTION?;
    }
}
