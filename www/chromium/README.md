# Known issues

## Hack used to reference MacPorts Clang

Because of a `verify_order` issue, Xcode Clang is avoided but `use_xcode yes` is still required to
get past the early detection of toolchain. This should be patched and `use_xcode yes` should be
removed.

[Related issue](https://bugs.chromium.org/p/chromium/issues/detail?id=653337)

## System libraries

### Missing ports

- libwebp
- openh264

### freetype and harfbuzz

`use_system_freetype=true` and `use_system_harfbuzz=true` do not work.

Both need patches to fix the include or a way to get the `-I` flag passed with the correct include
paths.

### libopus

Passing `opus` within `gn_system_libraries` does not work.

### icu

`icu_use_data_file=false` does not work.

### Non-working gn_system_libraries arguments

Fixes are necessary to ensure linker flags are given properly for these:

- ffmpeg
- libpng
- libvpx
- libxml
- libxslt

ffmpeg, libvpx, and libxslt fail to link with the system version in the final linking command.

libpng failure (truncated):

```plain
[20159/40046] TOOL_VERSION=1587505790
  ../../build/toolchain/mac/linker_driver.py \
  -Wcrl,strippath,/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip \
  ../../third_party/llvm-build/Release+Asserts/bin/clang++ -B \
  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ \
  -stdlib=libc++ -arch x86_64 -Wl,-dead_strip \
  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
  -mmacosx-version-min=10.10.0 -Wl,-ObjC -weak_framework MediaPlayer -o "./app_mode_loader" \
  -Wl,-filelist,"./app_mode_loader.rsp"  -framework AppKit -framework CoreFoundation \
  -framework Foundation -framework ApplicationServices -lbsm -framework IOKit \
  -framework OpenDirectory -lpmenergy -lpmsample -framework Security -framework Accelerate \
  -framework QuartzCore -framework AudioUnit -framework Carbon -framework CoreVideo \
  -framework CFNetwork -framework CoreServices -framework SystemConfiguration -lresolv -lz \
  -framework CoreGraphics -framework CoreText -framework Metal -ljpeg -framework IOSurface
FAILED: app_mode_loader
Undefined symbols for architecture x86_64:
  "_png_get_user_chunk_ptr", referenced from:
      sk_read_user_chunk(png_struct_def*, png_unknown_chunk_t*) in libskia.a(SkPngCodec.o)
  "_png_get_progressive_ptr", referenced from:
      SkPngNormalDecoder::AllRowsCallback(png_struct_def*, unsigned char*, unsigned int, int)
      in libskia.a(SkPngCodec.o)
...
```
