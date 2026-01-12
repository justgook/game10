#!/bin/bash
set -e

# Build nuklear/sokol_nuklear and menu libraries for Linux
# Outputs to lib/ folder
# Follows same pattern as sokol/build_clibs_linux.sh

SOKOL_C_DIR="../sokol/c"
C_DIR="c"
LIB_DIR="lib"

mkdir -p $LIB_DIR

build_lib_x64_release() {
    src=$1
    dst=$2
    echo "Building $dst (x64 gl release)..."
    cc -pthread -c -O2 -DNDEBUG -DIMPL -DSOKOL_GLCORE \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_x64_debug() {
    src=$1
    dst=$2
    echo "Building $dst (x64 gl debug)..."
    cc -pthread -c -g -DIMPL -DSOKOL_GLCORE \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

# x64 + GL + Release
build_lib_x64_release sokol_nuklear sokol_nuklear_linux_x64_gl_release
build_lib_x64_release menu          menu_linux_x64_gl_release

# x64 + GL + Debug
build_lib_x64_debug sokol_nuklear sokol_nuklear_linux_x64_gl_debug
build_lib_x64_debug menu          menu_linux_x64_gl_debug

echo ""
echo "Done! Libraries built in $LIB_DIR/"
ls -la $LIB_DIR/
