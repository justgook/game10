#!/bin/bash
set -e

# Build nuklear/sokol_nuklear and menu libraries for WebAssembly
# Outputs to lib/ folder
# Follows same pattern as sokol/build_clibs_wasm.sh
# Requires emscripten (emcc) to be in PATH

SOKOL_C_DIR="../sokol/c"
C_DIR="c"
LIB_DIR="lib"

mkdir -p $LIB_DIR

# Debug builds
echo "Building sokol_nuklear_wasm_gl_debug..."
emcc -c -g -DIMPL -DSOKOL_GLES3 \
    -I$SOKOL_C_DIR -I$C_DIR \
    $C_DIR/sokol_nuklear.c -o sokol_nuklear.o
emar rcs $LIB_DIR/sokol_nuklear_wasm_gl_debug.a sokol_nuklear.o
rm sokol_nuklear.o

echo "Building menu_wasm_gl_debug..."
emcc -c -g -DIMPL -DSOKOL_GLES3 \
    -I$SOKOL_C_DIR -I$C_DIR \
    $C_DIR/menu.c -o menu.o
emar rcs $LIB_DIR/menu_wasm_gl_debug.a menu.o
rm menu.o

# Release builds
echo "Building sokol_nuklear_wasm_gl_release..."
emcc -c -O2 -DNDEBUG -DIMPL -DSOKOL_GLES3 \
    -I$SOKOL_C_DIR -I$C_DIR \
    $C_DIR/sokol_nuklear.c -o sokol_nuklear.o
emar rcs $LIB_DIR/sokol_nuklear_wasm_gl_release.a sokol_nuklear.o
rm sokol_nuklear.o

echo "Building menu_wasm_gl_release..."
emcc -c -O2 -DNDEBUG -DIMPL -DSOKOL_GLES3 \
    -I$SOKOL_C_DIR -I$C_DIR \
    $C_DIR/menu.c -o menu.o
emar rcs $LIB_DIR/menu_wasm_gl_release.a menu.o
rm menu.o

echo ""
echo "Done! Libraries built in $LIB_DIR/"
ls -la $LIB_DIR/
