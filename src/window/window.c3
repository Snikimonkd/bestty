module window;

import raylib5::rl;

import pty;

import std::io;
import std::ascii;

const BUF_SIZE = 32;

struct Window {
    int w;
    int h;

    pty::Pty pty;

    DString scrollback;
    DString cmd;
}

fn Window init(pty::Pty pty) {
    return Window{ .w = 800, .h = 600, .pty = pty };
}

fn void! Window.run(&self) {
    rl::initWindow(self.w, self.h, "Bestty");
    defer rl::closeWindow();

    rl::Rectangle input = { .x = (float)5, .y = (float)(self.h - 50), .width = (float)(self.w - 5*2), .height = (float)40 };
    rl::Rectangle output = { .x = (float)5, .y = (float)5, .width = (float)(self.w - 5*2), .height = (float)(self.h - 40 - 5*4) };

    rl::setTargetFPS(60);

    defer self.scrollback.free();
    defer self.cmd.free();

    while (!rl::windowShouldClose()) {
        self.handle_keys()!!;
        self.read_from_pty()!!;

        rl::beginDrawing();
        rl::clearBackground(rl::GRAY);

        // print cmd
        rl::drawRectangleRec(input, rl::LIGHTGRAY);
        rl::drawText(self.cmd.zstr_view(), (int)input.x+5, (int)input.y+3, 40, rl::DARKGREEN);

        // print results
        rl::drawRectangleRec(output, rl::BLACK);
        rl::drawText(self.scrollback.zstr_view(), (int)output.x+5, (int)output.y+3, 10, rl::WHITE);

        rl::endDrawing();
    }
}

fn void! Window.handle_keys(&self) {
    int key = rl::getKeyPressed();
    if (key > 0) {
        // FIXME - handle all?
        if ((key > 32 && key < 125 || key == ' ')) {
            char k = ascii::to_lower((char)key);
            self.cmd.append_char(k);
        }
    }

    if (rl::isKeyPressed(rl::KEY_BACKSPACE)) {
        self.cmd.chop(self.cmd.len() - 1);
    }

    if (rl::isKeyPressed(rl::KEY_ENTER)) {
        self.cmd.append_char('\n');
        self.pty.write(self.cmd.zstr_view())!!;
        self.cmd.chop(0);
    }
}

fn void! Window.read_from_pty(&self) {
    char! c = self.pty.read_char();
    if (catch err = c) {
        if (err != pty::PtyError.EMPTY) {
            return err?;
        }
    } else {
        self.scrollback.append_char(c);
    }
}
