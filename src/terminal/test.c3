module terminal;
///
/// import freetype;
/// import std::io;
/// import logger;
///
/// fn int test() {
///     mem::@report_heap_allocs_in_scope() {
///         ft::Library library;
///         defer ft::doneFreeType(library);
///         ft::Face face;
///         defer ft::doneFace(face);
///         CInt err;
///
///         // init freetype lib
///         err = ft::initFreeType(&library);
///         if (err != 0) {
///             io::printfn("init free type err: %s", err);
///             return err;
///         }
///
///         // load face
///         err = ft::newFace(library, "/Library/Fonts/Arial Unicode.ttf", 0, &face);
///         if (err != ft::OK) {
///             io::printfn("can't load font: %s", err);
///             return err;
///         }
///
///         // set font size
///         err = ft::setPixelSizes(face, 80, 0);
///         if (err != ft::OK) {
///             io::printfn("can't set pixel sizes: %s", err);
///             return err;
///         }
///
///         err = ft::loadChar(face, 'A', ft::LOAD_RENDER);
///         if (err != ft::OK) {
///             io::printfn("can't load char: %s", err);
///             return err;
///         }
///
///         logger::printfn("width: %s", face.glyph.bitmap.width);
///         logger::printfn("rows: %s", face.glyph.bitmap.rows);
///
///         char[1024][1024] pixels;
///
///         for (int x = 0; x < face.glyph.bitmap.width; x++) {
///             for (int y = 0; y < face.glyph.bitmap.rows; y++) {
///                 pixels[y][x] |= face.glyph.bitmap.buffer[y * face.glyph.bitmap.width + x];
///             }
///         }
///
///         for (int y = 0; y < face.glyph.bitmap.rows; y++) {
///             for (int x = 0; x < face.glyph.bitmap.width; x++) {
///                 if (pixels[y][x] == 0) {
///                     io::printf(" ");
///                 } else if (pixels[y][x] < 128) {
///                     io::printf("+");
///                 } else {
///                     io::printf("*");
///                 }
///             }
///             io::printf("\n");
///         }
///
///
///     };
///
///     return 0;
/// }
