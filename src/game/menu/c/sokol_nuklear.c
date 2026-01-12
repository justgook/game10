// sokol_nuklear.c - Compiles sokol_nuklear implementation
//
// This file compiles the sokol_nuklear implementation with all required
// nuklear defines. It references sokol headers from the official sokol/c folder.

#if defined(IMPL)
#define SOKOL_NUKLEAR_IMPL
#endif

// Nuklear configuration - must be defined before including nuklear.h
#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_INCLUDE_STANDARD_VARARGS

// Include nuklear implementation
#define NK_IMPLEMENTATION
#include "nuklear.h"

// Include sokol headers from the official sokol/c folder
#include "../../sokol/c/sokol_defines.h"
#include "../../sokol/c/sokol_app.h"
#include "../../sokol/c/sokol_gfx.h"

// Include sokol_nuklear header (implementation enabled via SOKOL_NUKLEAR_IMPL)
#include "sokol_nuklear.h"
