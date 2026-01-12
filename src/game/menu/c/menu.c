// menu.c - Game menu implementation in C using Nuklear
//
// This file contains the actual menu UI code written in C.
// It's called from Odin each frame with the nuklear context.

// Nuklear configuration - must match sokol_nuklear.c
#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_INCLUDE_STANDARD_VARARGS
#include "nuklear.h"

// Menu state (can be expanded as needed)
static int show_options = 0;

// Main menu drawing function - called from Odin each frame
void menu_draw(struct nk_context* ctx) {
    // Main game menu window
    if (nk_begin(ctx, "Game Menu", nk_rect(50, 50, 230, 280),
        NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE |
        NK_WINDOW_MINIMIZABLE | NK_WINDOW_TITLE))
    {
        nk_layout_row_dynamic(ctx, 30, 1);

        if (nk_button_label(ctx, "New Game")) {
            // TODO: Signal to start new game
        }

        if (nk_button_label(ctx, "Continue")) {
            // TODO: Signal to continue game
        }

        if (nk_button_label(ctx, "Options")) {
            show_options = !show_options;
        }

        if (nk_button_label(ctx, "Quit")) {
            // TODO: Signal to quit game
        }

        // Some example widgets
        nk_layout_row_dynamic(ctx, 20, 1);
        nk_label(ctx, "Example Widgets:", NK_TEXT_LEFT);

        // Slider example
        static float slider_value = 0.5f;
        nk_layout_row_dynamic(ctx, 25, 1);
        nk_slider_float(ctx, 0.0f, &slider_value, 1.0f, 0.01f);

        // Checkbox example
        static int checkbox_value = 0;
        nk_layout_row_dynamic(ctx, 25, 1);
        nk_checkbox_label(ctx, "Enable Feature", &checkbox_value);
    }
    nk_end(ctx);

    // Options window (shown when Options button is clicked)
    if (show_options) {
        if (nk_begin(ctx, "Options", nk_rect(300, 50, 250, 200),
            NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE |
            NK_WINDOW_CLOSABLE | NK_WINDOW_TITLE))
        {
            nk_layout_row_dynamic(ctx, 25, 1);
            nk_label(ctx, "Audio:", NK_TEXT_LEFT);

            static float music_volume = 0.8f;
            nk_layout_row_dynamic(ctx, 25, 1);
            nk_property_float(ctx, "Music:", 0.0f, &music_volume, 1.0f, 0.1f, 0.01f);

            static float sfx_volume = 1.0f;
            nk_layout_row_dynamic(ctx, 25, 1);
            nk_property_float(ctx, "SFX:", 0.0f, &sfx_volume, 1.0f, 0.1f, 0.01f);

            nk_layout_row_dynamic(ctx, 25, 1);
            nk_label(ctx, "Graphics:", NK_TEXT_LEFT);

            static int fullscreen = 0;
            nk_layout_row_dynamic(ctx, 25, 1);
            nk_checkbox_label(ctx, "Fullscreen", &fullscreen);
        }
        // Check if window was closed
        if (nk_window_is_hidden(ctx, "Options")) {
            show_options = 0;
            nk_window_show(ctx, "Options", NK_SHOWN); // Reset for next time
        }
        nk_end(ctx);
    }
}
