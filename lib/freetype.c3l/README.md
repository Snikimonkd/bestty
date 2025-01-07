# FreeType bindings

It is tested only on arm macos.

To make it work on other systems you need to add your platform to `manifest.json`, something like this:

```json
"macos-aarch64": {
  // Extra flags to the linker for this target:
  "link-args": [
    "-I/opt/homebrew/opt/freetype/include/freetype2",
    "-L/opt/homebrew/opt/freetype/lib"
  ],
  // C3 libraries this target depends on:
  "dependencies": [],
  // The external libraries to link for this target:
  "linked-libraries": [
    "freetype"
  ]
}
```

`link-args` and `linked-libraries` can be found with this commands.

```bash
$ freetype-config --libs
-L/opt/homebrew/opt/freetype/lib -lfreetype
$ freetype-config --cflags
-I/opt/homebrew/opt/freetype/include/freetype2
```

Note that `-L/opt/homebrew/opt/freetype/lib` goes to `link-args` and not to `linked-libraries`.
