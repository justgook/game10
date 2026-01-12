#!/bin/bash
set -e

# Build nuklear/sokol_nuklear and menu libraries for macOS
# Outputs to lib/ folder
# Follows same pattern as sokol/build_clibs_macos.sh

SOKOL_C_DIR="../sokol/c"
C_DIR="c"
LIB_DIR="lib"

mkdir -p $LIB_DIR

# ============ ARM64 Builds ============

build_lib_arm64_metal_release() {
    src=$1
    dst=$2
    echo "Building $dst (arm64 metal release)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -O2 -x objective-c -arch arm64 \
        -DNDEBUG -DIMPL -DSOKOL_METAL \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_arm64_metal_debug() {
    src=$1
    dst=$2
    echo "Building $dst (arm64 metal debug)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -g -x objective-c -arch arm64 \
        -DIMPL -DSOKOL_METAL \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_arm64_gl_release() {
    src=$1
    dst=$2
    echo "Building $dst (arm64 gl release)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -O2 -x objective-c -arch arm64 \
        -DNDEBUG -DIMPL -DSOKOL_GLCORE \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_arm64_gl_debug() {
    src=$1
    dst=$2
    echo "Building $dst (arm64 gl debug)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -g -x objective-c -arch arm64 \
        -DIMPL -DSOKOL_GLCORE \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

# ============ x64 Builds ============

build_lib_x64_metal_release() {
    src=$1
    dst=$2
    echo "Building $dst (x64 metal release)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -O2 -x objective-c -arch x86_64 \
        -DNDEBUG -DIMPL -DSOKOL_METAL \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_x64_metal_debug() {
    src=$1
    dst=$2
    echo "Building $dst (x64 metal debug)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -g -x objective-c -arch x86_64 \
        -DIMPL -DSOKOL_METAL \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_x64_gl_release() {
    src=$1
    dst=$2
    echo "Building $dst (x64 gl release)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -O2 -x objective-c -arch x86_64 \
        -DNDEBUG -DIMPL -DSOKOL_GLCORE \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

build_lib_x64_gl_debug() {
    src=$1
    dst=$2
    echo "Building $dst (x64 gl debug)..."
    MACOSX_DEPLOYMENT_TARGET=10.13 clang -c -g -x objective-c -arch x86_64 \
        -DIMPL -DSOKOL_GLCORE \
        -I$SOKOL_C_DIR -I$C_DIR \
        $C_DIR/$src.c -o $src.o
    ar rcs $LIB_DIR/$dst.a $src.o
    rm $src.o
}

# ============ Build All Variants ============

# ARM64 + Metal
build_lib_arm64_metal_release sokol_nuklear sokol_nuklear_macos_arm64_metal_release
build_lib_arm64_metal_debug   sokol_nuklear sokol_nuklear_macos_arm64_metal_debug
build_lib_arm64_metal_release menu          menu_macos_arm64_metal_release
build_lib_arm64_metal_debug   menu          menu_macos_arm64_metal_debug

# ARM64 + GL
build_lib_arm64_gl_release sokol_nuklear sokol_nuklear_macos_arm64_gl_release
build_lib_arm64_gl_debug   sokol_nuklear sokol_nuklear_macos_arm64_gl_debug
build_lib_arm64_gl_release menu          menu_macos_arm64_gl_release
build_lib_arm64_gl_debug   menu          menu_macos_arm64_gl_debug

# x64 + Metal
build_lib_x64_metal_release sokol_nuklear sokol_nuklear_macos_x64_metal_release
build_lib_x64_metal_debug   sokol_nuklear sokol_nuklear_macos_x64_metal_debug
build_lib_x64_metal_release menu          menu_macos_x64_metal_release
build_lib_x64_metal_debug   menu          menu_macos_x64_metal_debug

# x64 + GL
build_lib_x64_gl_release sokol_nuklear sokol_nuklear_macos_x64_gl_release
build_lib_x64_gl_debug   sokol_nuklear sokol_nuklear_macos_x64_gl_debug
build_lib_x64_gl_release menu          menu_macos_x64_gl_release
build_lib_x64_gl_debug   menu          menu_macos_x64_gl_debug

echo ""
echo "Done! Libraries built in $LIB_DIR/"
ls -la $LIB_DIR/
