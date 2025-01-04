module parser;

enum State : int {
    // default value for unhandled escape sequences
    UNDEFINED,

    GROUND,
    ESCAPE,
    ESCAPE_INTERMEDIATE,
    CSI_ENTRY,
    CSI_INTERMEDIATE,
    CSI_PARAM,
    CSI_IGNORE,
    DCS_ENTRY,
    DCS_PARAM,
    DCS_INTERMEDIATE,
    DCS_PASSTHROUGH,
    DCS_IGNORE,
    OSC_STRING,
    SOS_PM_APC_STRING,
}

enum Action : int {
    NONE,
    IGNORE,
    PRINT,
    EXECUTE,
    COLLECT,
    PARAM,
    ESC_DISPATCH,
    CSI_DISPATCH,
    PUT,
    OSC_PUT,
    APC_PUT,
}

struct Transition {
    State state;
    Action action;
}

def StatesTransitions = Transition[State.elements];
def CharsStatesTransitions = StatesTransitions[char.max];
distinct TransitionTable = CharsStatesTransitions;

fn void TransitionTable.set_one(&self, char c, State prev, State next, Action action) {
    (*self)[(int)c][(int)prev.ordinal] = { .state = next, .action = action };
}

fn void TransitionTable.set_many(&self, char from, char to, State prev, State next, Action action) {
    for (char c = from; c <= to; c++) {
        (*self)[(int)c][(int)prev.ordinal] = { .state = next, .action = action };
    }
}

TransitionTable t;

fn void build_table() @init {
    // from anywhere
    foreach (State from : State.values) {
        // anywhere to GROUND
        t.set_one(0x18, from, GROUND, EXECUTE);
        t.set_one(0x1A, from, GROUND, EXECUTE);
        t.set_many(0x80, 0x8F, from, GROUND, EXECUTE);
        t.set_many(0x91, 0x97, from, GROUND, EXECUTE);
        t.set_one(0x99, from, GROUND, EXECUTE);
        t.set_one(0x9A, from, GROUND, EXECUTE);
        t.set_one(0x9C, from, GROUND, NONE);

        // anywhere to ESCAPE
        t.set_one(0x1B, from, ESCAPE, NONE);

//        // anywhere to SOS_PM_APC_STRING
//        t.set_one(0x98, from, SOS_PM_APC_STRING, NONE);
//        t.set_one(0x9E, from, SOS_PM_APC_STRING, NONE);
//        t.set_one(0x9F, from, SOS_PM_APC_STRING, NONE);

        // anywhere to CSI_ENTRY
        t.set_one(0x9B, from, CSI_ENTRY, NONE);

//        // anywhere to DCS_ENTRY
//        t.set_one(0x90, from, DCS_ENTRY, NONE);
//
//        // anywhere to OSC_STRING
//        t.set_one(0x9D, from, OSC_STRING, NONE);
    }

    // from GROUND
    {
        // to GROUND
        t.set_many(0x00, 0x17, GROUND, GROUND, EXECUTE);
        t.set_one(0x19, GROUND, GROUND, EXECUTE);
        t.set_many(0x1C, 0x1F, GROUND, GROUND, EXECUTE);
        t.set_many(0x20, 0x7F, GROUND, GROUND, PRINT);
    }

    // from ESCAPE_INTERMEDIATE
    {
        // to ESCAPE_INTERMEDIATE
        t.set_one(0x19, ESCAPE_INTERMEDIATE, ESCAPE_INTERMEDIATE, EXECUTE);
        t.set_many(0x00, 0x17, ESCAPE_INTERMEDIATE, ESCAPE_INTERMEDIATE, EXECUTE);
        t.set_many(0x1C, 0x1F, ESCAPE_INTERMEDIATE, ESCAPE_INTERMEDIATE, EXECUTE);
        t.set_many(0x20, 0x2F, ESCAPE_INTERMEDIATE, ESCAPE_INTERMEDIATE, COLLECT);
        t.set_one(0x7F, ESCAPE_INTERMEDIATE, ESCAPE_INTERMEDIATE, IGNORE);

        // to GROUND
        t.set_many(0x30, 0x7E, ESCAPE_INTERMEDIATE, GROUND, ESC_DISPATCH);
    }

//    // from SOS_PM_APC_STRING
//    {
//        // to APC_PUT
//        t.set_one(0x19, SOS_PM_APC_STRING, SOS_PM_APC_STRING, APC_PUT);
//        t.set_many(0x00, 0x17, SOS_PM_APC_STRING, SOS_PM_APC_STRING, APC_PUT);
//        t.set_many(0x1C, 0x1F, SOS_PM_APC_STRING, SOS_PM_APC_STRING, APC_PUT);
//        t.set_many(0x20, 0x7F, SOS_PM_APC_STRING, SOS_PM_APC_STRING, APC_PUT);
//    }
//
    // from ESCAPE
    {
        // to ESCAPE
        t.set_one(0x19, ESCAPE, ESCAPE, EXECUTE);
        t.set_many(0, 0x17, ESCAPE, ESCAPE, EXECUTE);
        t.set_many(0x1C, 0x1F, ESCAPE, ESCAPE, EXECUTE);
        t.set_one(0x7F, ESCAPE, ESCAPE, IGNORE);

        // to GROUND
        t.set_many(0x30, 0x4F, ESCAPE, GROUND, ESC_DISPATCH);
        t.set_many(0x51, 0x57, ESCAPE, GROUND, ESC_DISPATCH);
        t.set_many(0x60, 0x7E, ESCAPE, GROUND, ESC_DISPATCH);
        t.set_one(0x59, ESCAPE, GROUND, ESC_DISPATCH);
        t.set_one(0x5A, ESCAPE, GROUND, ESC_DISPATCH);
        t.set_one(0x5C, ESCAPE, GROUND, ESC_DISPATCH);

        // to ESCAPE_INTERMEDIATE
        t.set_many(0x20, 0x2F, ESCAPE, ESCAPE_INTERMEDIATE, COLLECT);

        // to CSI_ENTRY
        t.set_one(0x5B, ESCAPE, CSI_ENTRY, NONE);

//        // to sos_pm_apc_strING
//        t.set_one(0x58, ESCAPE, SOS_PM_APC_STRING, NONE);
//        t.set_one(0x5E, ESCAPE, SOS_PM_APC_STRING, NONE);
//        t.set_one(0x5F, ESCAPE, SOS_PM_APC_STRING, NONE);
//
//        // to dcs_entry
//        t.set_one(0x50, ESCAPE, DCS_ENTRY, NONE);

//        // to osc_string
//        t.set_one(0x5D, ESCAPE, OSC_STRING, NONE);
    }

    // from CSI_PARAM
    {
        // to CSI_PARAM
        t.set_one(0x19, CSI_PARAM, CSI_PARAM, EXECUTE);
        t.set_many(0, 0x17, CSI_PARAM, CSI_PARAM, EXECUTE);
        t.set_many(0x1C, 0x1F, CSI_PARAM, CSI_PARAM, EXECUTE);
        t.set_many(0x30, 0x39, CSI_PARAM, CSI_PARAM, PARAM);
        t.set_one(0x3A, CSI_PARAM, CSI_PARAM, PARAM);
        t.set_one(0x3B, CSI_PARAM, CSI_PARAM, PARAM);
        t.set_one(0x7F, CSI_PARAM, CSI_PARAM, IGNORE);

        // to GROUND
        t.set_many(0x40, 0x7E, CSI_PARAM, GROUND, CSI_DISPATCH);

        // to CSI_IGNORE
        t.set_many(0x3C, 0x3F, CSI_PARAM, CSI_IGNORE, NONE);

        // to CSI_INTERMEDIATE
        t.set_many(0x20, 0x2F, CSI_PARAM, CSI_INTERMEDIATE, COLLECT);
    }

    // from CSI_IGNORE
    {
        // to CSI_IGNORE
        t.set_one(0X19, CSI_IGNORE, CSI_IGNORE, EXECUTE);
        t.set_many(0, 0X17, CSI_IGNORE, CSI_IGNORE, EXECUTE);
        t.set_many(0X1C, 0X1F, CSI_IGNORE, CSI_IGNORE, EXECUTE);
        t.set_many(0X20, 0X3F, CSI_IGNORE, CSI_IGNORE, IGNORE);
        t.set_one(0X7F, CSI_IGNORE, CSI_IGNORE, IGNORE);

        // to GROUND
        t.set_many(0X40, 0X7E, CSI_IGNORE, GROUND, NONE);
    }

    // from CSI_INTERMEDIATE
    {
        // to CSI_INTERMEDIATE
        t.set_one(0x19, CSI_INTERMEDIATE, CSI_INTERMEDIATE, EXECUTE);
        t.set_many(0, 0x17, CSI_INTERMEDIATE, CSI_INTERMEDIATE, EXECUTE);
        t.set_many(0x1C, 0x1F, CSI_INTERMEDIATE, CSI_INTERMEDIATE, EXECUTE);
        t.set_many(0x20, 0x2F, CSI_INTERMEDIATE, CSI_INTERMEDIATE, COLLECT);
        t.set_one(0x7F, CSI_INTERMEDIATE, CSI_INTERMEDIATE, IGNORE);

        // to GROUND
        t.set_many(0x40, 0x7E, CSI_INTERMEDIATE, GROUND, CSI_DISPATCH);

        // to CSI_IGNORE
        t.set_many(0x30, 0x3F, CSI_INTERMEDIATE, CSI_IGNORE, NONE);
    }

    // from CSI_ENTRY
    {
        // to CSI_ENTRY
        t.set_one(0x19, CSI_ENTRY, CSI_ENTRY, EXECUTE);
        t.set_many(0, 0x17, CSI_ENTRY, CSI_ENTRY, EXECUTE);
        t.set_many(0x1C, 0x1F, CSI_ENTRY, CSI_ENTRY, EXECUTE);
        t.set_one(0x7F, CSI_ENTRY, CSI_ENTRY, IGNORE);

        // to GROUND
        t.set_many(0x40, 0x7E, CSI_ENTRY, GROUND, CSI_DISPATCH);

        // to CSI_IGNORE
        t.set_one(0x3A, CSI_ENTRY, CSI_IGNORE, NONE);

        // to CSI_INTERMEDIATE
        t.set_many(0x20, 0x2F, CSI_ENTRY, CSI_INTERMEDIATE, COLLECT);

        // to CSI_PARAM
        t.set_many(0x30, 0x39, CSI_ENTRY, CSI_PARAM, PARAM);
        t.set_one(0x3B, CSI_ENTRY, CSI_PARAM, PARAM);
        t.set_many(0x3C, 0x3F, CSI_ENTRY, CSI_PARAM, COLLECT);
    }
}

