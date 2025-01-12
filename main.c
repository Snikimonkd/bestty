#include <math.h>
#include <stdio.h>
#include <string.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#define WIDTH 640
#define HEIGHT 480

unsigned char image[HEIGHT][WIDTH];

void draw_bitmap(FT_Bitmap *bitmap, FT_Int x, FT_Int y) {
  FT_Int i, j, p, q;
  FT_Int x_max = x + bitmap->width;
  FT_Int y_max = y + bitmap->rows;

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
  FT_Error err;
  int target_height = HEIGHT;

  err = FT_Init_FreeType(&library);
  if (err != 0) {
    return err;
  }

  err = FT_New_Face(library, "/Library/Fonts/Arial Unicode.ttf", 0, &face);
  if (err != 0) {
    return err;
  }

  err = FT_Set_Char_Size(face, 50 * 64, 0, 100, 0);
  if (err != 0) {
    return err;
  }

  err = FT_Load_Char(face, '#', FT_LOAD_RENDER);
  if (err != 0) {
    return err;
  }

  fprintf(stderr, "num_charmaps: %d\n", face->num_charmaps);
  fprintf(stderr, "platform_id: %d\n", face->charmaps[0]->platform_id);
  fprintf(stderr, "encoding_id: %d\n", face->charmaps[0]->encoding_id);
  fprintf(stderr, "BBox.xMin: %ld\n", face->bbox.xMin);
  fprintf(stderr, "BBox.xMax: %ld\n", face->bbox.xMax);
  fprintf(stderr, "units_per_EM: %d\n", face->units_per_EM);
  fprintf(stderr, "underline_thickness: %d\n", face->underline_thickness);
  fprintf(stderr, "glyph_index: %d\n", face->glyph->glyph_index);
  fprintf(stderr, "metrics.width: %ld\n", face->glyph->metrics.width);
  fprintf(stderr, "metrics.width: %ld\n", face->glyph->metrics.height);
  fprintf(stderr, "metrics.horiBearingX: %ld\n",
          face->glyph->metrics.horiBearingX);
  fprintf(stderr, "metrics.width: %u\n", face->glyph->format);
  fprintf(stderr, "bitmap.width: %u\n", face->glyph->bitmap.width);
  fprintf(stderr, "bitmap.rows: %u\n", face->glyph->bitmap.rows);
  fprintf(stderr, "pixel_mode: %d\n", face->glyph->bitmap.pixel_mode);
  fprintf(stderr, "palette_mode: %d\n", face->glyph->bitmap.palette_mode);
  fprintf(stderr, "bitmap_left: %d\n", face->glyph->bitmap_left);
  fprintf(stderr, "bitmap_top: %d\n", face->glyph->bitmap_top);
  fprintf(stderr, "bitmap.pixel_mode: %d\n", face->glyph->bitmap.pixel_mode);

  fprintf(stderr, "----------------\n");
  fprintf(stderr, "control_len: %ld\n", face->glyph->control_len);
  fprintf(stderr, "----------------\n");

  return 0;

  draw_bitmap(&face->glyph->bitmap, face->glyph->bitmap_left,
              target_height - face->glyph->bitmap_top);

  show_image();

  FT_Done_Face(face);
  FT_Done_FreeType(library);

  return 0;
}
