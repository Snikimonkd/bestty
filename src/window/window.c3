module window;

import raylib5::rl;
import logger;
import pty;

import std::io;

import std::ascii;
import std::time;

const BUF_SIZE = 32;
const WIDTH = 800;
const HEIGHT = 600;

fn void! run(pty::Pty pty) {
    rl::initWindow(WIDTH, HEIGHT, "Bestty");
    defer rl::closeWindow();

    ZString cmd = (ZString)&&char[128]{};
    cmd[0] = '\0';
    int letterCount = 0;

    rl::Rectangle input = {5, HEIGHT - 50, WIDTH-5*2, 40};
    rl::Rectangle output = {5, 5, WIDTH-5*2, HEIGHT-40-5*4};

    bool mouseOnText = false;
    int framesCounter = 0;

    rl::setTargetFPS(60);
    DString res;
    defer res.free();

    while (!rl::windowShouldClose()) {
        int key = rl::getKeyPressed();
        while (key > 0) {
            // FIXME - handle all?
            if ((key > 32 && key < 125 || key == ' ') && letterCount < BUF_SIZE) {
                cmd[letterCount] = ascii::to_lower((char)key);
                cmd[letterCount+1] = '\0';
                letterCount++;
            }
            key = rl::getKeyPressed();
        }

        if (rl::isKeyPressed(rl::KEY_BACKSPACE)) {
            letterCount = max(0, letterCount-1);
            cmd[letterCount] = '\0';
        }

        if (rl::isKeyPressed(rl::KEY_ENTER)) {
            cmd[letterCount] = '\n';
            cmd[letterCount+1] = '\0';
            letterCount++;

            pty.write(cmd)!!;
            letterCount = 0;
            cmd[letterCount] = '\0';

        }

        DString! tmp = pty.read();
        if (catch err = tmp) {
            return err?;
        }

        res.append_string(tmp);
        tmp.free();

        rl::beginDrawing();
        rl::clearBackground(rl::GRAY);


        // print cmd
        rl::drawRectangleRec(input, rl::LIGHTGRAY);
        rl::drawText(cmd, (int)input.x+5, (int)input.y+3, 40, rl::DARKGREEN);

        // print results
        rl::drawRectangleRec(output, rl::BLACK);
        rl::drawText(res.zstr_view(), (int)output.x+5, (int)output.y+3, 10, rl::WHITE);
        logger::printfn("output: %s", res);

        rl::endDrawing();
    }
}
