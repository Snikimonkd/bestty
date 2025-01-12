/* example1.c                                                      */
/*                                                                 */
/* This small program shows how to print a rotated string with the */
/* FreeType 2 library.                                             */

#include <math.h>
#include <stdio.h>
#include <string.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#define WIDTH 640
#define HEIGHT 480

/* origin is the upper left corner */
unsigned char image[HEIGHT][WIDTH];

/* Replace this function with something useful. */

void draw_bitmap(FT_Bitmap *bitmap, FT_Int x, FT_Int y) {
  FT_Int i, j, p, q;
  FT_Int x_max = x + bitmap->width;
  FT_Int y_max = y + bitmap->rows;

  /* for simplicity, we assume that `bitmap->pixel_mode' */
  /* is `FT_PIXEL_MODE_GRAY' (i.e., not a bitmap font)   */

  for (i = x, p = 0; i < x_max; i++, p++) {
    for (j = y, q = 0; j < y_max; j++, q++) {
      if (i < 0 || j < 0 || i >= WIDTH || j >= HEIGHT)
        continue;

      image[j][i] |= bitmap->buffer[q * bitmap->width + p];
    }
  }
}

void show_image(void) {
  int i, j;

  for (i = 0; i < HEIGHT; i++) {
    for (j = 0; j < WIDTH; j++)
      putchar(image[i][j] == 0 ? ' ' : image[i][j] < 128 ? '+' : '*');
    putchar('\n');
  }
}

int main(int argc, char **argv) {
  FT_Library library;
  FT_Face face;

  FT_GlyphSlot slot;
  FT_Error error;

  double angle;
  int target_height;

  char *filename = "/Library/Fonts/Arial Unicode.ttf";
  angle = (25.0 / 360) * 3.14159 * 2; /* use 25 degrees     */
  target_height = HEIGHT;

  error = FT_Init_FreeType(&library); /* initialize library */
  /* error handling omitted */

  error = FT_New_Face(library, filename, 0, &face); /* create face object */
  /* error handling omitted */

  /* use 50pt at 100dpi */
  error = FT_Set_Char_Size(face, 50 * 64, 0, 100, 0); /* set character size */
  /* error handling omitted */

  /* cmap selection omitted;                                        */
  /* for simplicity we assume that the font contains a Unicode cmap */

  slot = face->glyph;

  /* load glyph image into the slot (erase previous one) */
  error = FT_Load_Char(face, '#', FT_LOAD_RENDER);
  if (error) {
    return error;
  }

  fprintf(stderr, "bitmap_left: %d", face->glyph->bitmap_left);
  fprintf(stderr, "bitmap_top: %d", face->glyph->bitmap_top);
  fprintf(stderr, "bitmap.width: %d", face->glyph->bitmap.width);
  fprintf(stderr, "bitmap.rows: %d", face->glyph->bitmap.rows);
  fprintf(stderr, "bitmap.pixel_mode: %d", face->glyph->bitmap.pixel_mode);

  /* now, draw to our target surface (convert position) */
  draw_bitmap(&slot->bitmap, slot->bitmap_left,
              target_height - slot->bitmap_top);

  show_image();

  FT_Done_Face(face);
  FT_Done_FreeType(library);

  return 0;
}

/* EOF */
