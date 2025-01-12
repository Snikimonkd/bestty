module terminal;

import raylib5::rl;

import pty;
import parser;

import std::io;
import std::ascii;

const BUF_SIZE = 32;

const WIDTH = 640;
const HEIGHT = 480;

struct Terminal {
    int w;
    int h;

    pty::Pty pty;
    parser::Parser parser;
    parser::Scrollback scrollback;

    DString cmd;
}

fn Terminal init(pty::Pty pty, parser::Parser parser) {
    return Terminal{ .w = 800, .h = 600, .pty = pty, .parser = parser };
}

fn void! Terminal.run(&self) {
    rl::initWindow(self.w, self.h, "Bestty");
    defer rl::closeWindow();

    rl::Rectangle input = { .x = (float)5, .y = (float)(self.h - 50), .width = (float)(self.w - 5*2), .height = (float)40 };
    rl::Rectangle output = { .x = (float)5, .y = (float)5, .width = (float)(self.w - 5*2), .height = (float)(self.h - 40 - 5*4) };

    rl::setTargetFPS(60);

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
        rl::drawText(self.scrollback.to_print().zstr_view(), (int)output.x+5, (int)output.y+3, 10, rl::WHITE);

        rl::endDrawing();
    }
}

fn void! Terminal.handle_keys(&self) {
    int key = rl::getKeyPressed();
    if (key > 0) {
        // FIXME - handle all?
        if ((key > 32 && key < 125 || key == ' ')) {
            char k = ascii::to_lower((char)key);
            self.cmd.append_char(k);
        }
    }

    if (rl::isKeyPressed(rl::KEY_BACKSPACE)) {
        self.cmd.chop(max(0, self.cmd.len() - 1));
    }

    if (rl::isKeyPressed(rl::KEY_ENTER)) {
        self.cmd.append_char('\n');
        // TODO: here is a \0 at the end that breaks reading in the future
        if (catch err = self.pty.write(self.cmd.zstr_view())) {
            if (err != pty::PtyError.PTY_NOT_READY) {
                return err?;
            }
            if (err == pty::PtyError.PTY_NOT_READY) {
                return;
            }
        }
        self.cmd.chop(0);
    }
}

fn void! Terminal.read_from_pty(&self) {
    DString! tmp = self.pty.read();
    if (catch err = tmp) {
        if (err != pty::PtyError.EMPTY) {
            return err?;
        }
        return;
    }

    // TODO: parser comes into play
    foreach (char c : tmp) {
        parser::PtyAction! action = self.parser.next(c);
        if (catch err = action) {
            return err?;
        }

        self.scrollback.handle(action)!!;
    }
    tmp.free();
}
