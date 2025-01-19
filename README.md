# BesTTY

My attempt to implement a terminal emulator in [c3](https://c3-lang.org).

![out.gif](/showcase/out.gif)

### State of the project

- [x] can run commands and see results in log file
- [x] minimal ui implemetation using raylib
- [ ] respect control sequences
- - [ ] implement control sequences parser (https://vt100.net/emu/dec_ansi_parser)
- - [ ] handle control sequences in the output
- - [ ] handle control sequences from the keyboard
- [ ] tabs/splits
- - [x] use opengl to render window
- - [ ] use freetype for font rendering
- - - [x] create freetype bindings (https://github.com/c3lang/vendor/pull/45)
- - - [ ] render text with freetype

