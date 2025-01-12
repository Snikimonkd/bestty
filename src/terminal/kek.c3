module terminal;

import freetype;
import std::io;
import logger;

char[WIDTH][HEIGHT] image;

fn void draw_bitmap(ft::Bitmap* bitmap, int x, int y) {
    int  i, j, p, q;
    int  x_max = x + bitmap.width;
    int  y_max = y + bitmap.rows;

    for FOO: (i = x, p = 0; i < x_max; i++, p++) {
        for (j = y, q = 0; j < y_max; j++, q++) {
            if (i >= WIDTH) {
                continue FOO;
            }
            if (j >= HEIGHT) {
                continue FOO;
            }
            logger::printfn("i: %s, j: %s", i, j);
            image[j][i] |= bitmap.buffer[q * bitmap.width + p];
        }
    }
}

fn void show_image() {
    int  i, j;

    for ( i = 0; i < HEIGHT; i++ ) {
        for ( j = 0; j < WIDTH; j++ ) {
            if (image[i][j] == 0) {
                logger::printf(" ");
            } else if (image[i][j] < 128) {
                logger::printf("+");
            } else {
                logger::printf("*");
            }
        }
        logger::printf("\n");
    }
}


fn int test_fonts() {
    ft::Library library;
    defer ft::doneFreeType(library);

    ft::Face       face;
    defer ft::doneFace(face);

    ft::Error err;

    int           target_height = HEIGHT;
    int           n, num_chars;

    err = ft::initFreeType(&library);
    if (err != 0) {
        logger::printfn("init free type err: %s", err);
        return -1;
    }

    err = ft::newFace(library, "/Library/Fonts/Arial Unicode.ttf", 0, &face);
    if (err != 0) {
        logger::printfn("can't load font: %s", err);
        return -1;
    }

    err = ft::setCharSize(face, 50 * 64, 0, 100, 0);
    if (err != 0) {
        logger::printfn("can't set pixel sizes: %x", err);
        return -1;
    }

    err = ft::loadChar(face, '#', ft::LOAD_RENDER);
    if (err != 0) {
        logger::printfn("can't load char: %s", err);
        return -1;
    }

    logger::printfn("start drawing bitmap");
    logger::printfn("OK: %s", face.glyph);
    logger::printfn("bitmap_left: %s", face.glyph.bitmap_left);
    logger::printfn("bitmap_top: %s", face.glyph.bitmap_top);
    logger::printfn("bitmap.width: %s", face.glyph.bitmap.width);
    logger::printfn("bitmap.rows: %s", face.glyph.bitmap.rows);
    logger::printfn("bitmap.pixel_mode: %s", face.glyph.bitmap.pixel_mode);
    logger::printfn("bitmap.buffer: %s", face.glyph.bitmap.buffer);
    return -1;


    draw_bitmap(&face.glyph.bitmap, face.glyph.bitmap_left, target_height - face.glyph.bitmap_top);

    logger::printfn("show image");

    show_image();

    logger::printfn("end");


    return 0;
}
