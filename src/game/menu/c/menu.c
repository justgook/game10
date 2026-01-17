// menu.c - Game menu and HUD implementation in C using Nuklear
//
// This file contains the actual menu/HUD UI code written in C.
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
#include <stdio.h>

// HUD data passed from Odin
typedef struct {
  // Player state
  int player_pos_x;
  int player_pos_y;
  int player_vel_x;
  int player_vel_y;

  // Jump state
  int is_grounded;
  int is_rising;
  int is_facing_right;
  int jump_hold_frames;

  // World info
  int entity_count;
  int paused;

  // Camera
  float camera_x;
  float camera_y;
  float zoom;

  // Performance
  float fps;
  float frame_time_ms;

  // Window size
  int window_width;
  int window_height;
} HudData;

// Menu state
static int show_menu = 0;
static int show_options = 0;
static int show_debug_hud = 1;

// Toggle menu visibility (can be called from Odin)
void menu_toggle(void) { show_menu = !show_menu; }

// Toggle debug HUD visibility
void menu_toggle_debug_hud(void) { show_debug_hud = !show_debug_hud; }

// Set menu visibility directly
void menu_set_visible(int visible) { show_menu = visible; }

// Check if menu is visible
int menu_is_visible(void) { return show_menu; }

// Draw the debug HUD overlay
static void draw_debug_hud(struct nk_context *ctx, const HudData *data) {
  if (!show_debug_hud || !data)
    return;

  // Position HUD in top-right corner
  float hud_width = 220;
  float hud_x = data->window_width - hud_width - 10;

  if (nk_begin(ctx, "Debug HUD", nk_rect(hud_x, 10, hud_width, 280),
               NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE |
                   NK_WINDOW_MINIMIZABLE | NK_WINDOW_TITLE)) {
    char buf[64];

    // Performance section
    nk_layout_row_dynamic(ctx, 18, 1);
    snprintf(buf, sizeof(buf), "FPS: %.1f", data->fps);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    snprintf(buf, sizeof(buf), "Frame: %.2f ms", data->frame_time_ms);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    // World section
    nk_layout_row_dynamic(ctx, 8, 1);
    nk_spacing(ctx, 1);
    nk_layout_row_dynamic(ctx, 18, 1);
    nk_label(ctx, "--- World ---", NK_TEXT_CENTERED);

    snprintf(buf, sizeof(buf), "Entities: %d", data->entity_count);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    snprintf(buf, sizeof(buf), "Paused: %s", data->paused ? "Yes" : "No");
    nk_label(ctx, buf, NK_TEXT_LEFT);

    // Player section
    nk_layout_row_dynamic(ctx, 8, 1);
    nk_spacing(ctx, 1);
    nk_layout_row_dynamic(ctx, 18, 1);
    nk_label(ctx, "--- Player ---", NK_TEXT_CENTERED);

    snprintf(buf, sizeof(buf), "Pos: %d, %d", data->player_pos_x,
             data->player_pos_y);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    snprintf(buf, sizeof(buf), "Vel: %d, %d", data->player_vel_x,
             data->player_vel_y);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    // Jump state with visual indicator
    const char *jump_state = data->is_grounded
                                 ? "Grounded"
                                 : (data->is_rising ? "Rising" : "Falling");
    snprintf(buf, sizeof(buf), "State: %s", jump_state);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    snprintf(buf, sizeof(buf), "Facing: %s",
             data->is_facing_right ? "Right" : "Left");
    nk_label(ctx, buf, NK_TEXT_LEFT);

    // Camera section
    nk_layout_row_dynamic(ctx, 8, 1);
    nk_spacing(ctx, 1);
    nk_layout_row_dynamic(ctx, 18, 1);
    nk_label(ctx, "--- Camera ---", NK_TEXT_CENTERED);

    snprintf(buf, sizeof(buf), "Pos: %.0f, %.0f", data->camera_x,
             data->camera_y);
    nk_label(ctx, buf, NK_TEXT_LEFT);

    snprintf(buf, sizeof(buf), "Zoom: %.2fx", data->zoom);
    nk_label(ctx, buf, NK_TEXT_LEFT);
  }
  nk_end(ctx);
}

// Draw the main game menu
static void draw_main_menu(struct nk_context *ctx, const HudData *data) {
  if (!show_menu)
    return;

  // Center the menu window
  float menu_width = 230;
  float menu_height = 280;
  float menu_x = data ? (data->window_width - menu_width) / 2.0f : 50;
  float menu_y = data ? (data->window_height - menu_height) / 2.0f : 50;

  if (nk_begin(ctx, "Game Menu",
               nk_rect(menu_x, menu_y, menu_width, menu_height),
               NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE |
                   NK_WINDOW_MINIMIZABLE | NK_WINDOW_TITLE)) {
    nk_layout_row_dynamic(ctx, 30, 1);

    if (nk_button_label(ctx, "Resume")) {
      show_menu = 0;
    }

    if (nk_button_label(ctx, "New Game")) {
      // TODO: Signal to start new game
    }

    if (nk_button_label(ctx, "Options")) {
      show_options = !show_options;
    }

    if (nk_button_label(ctx, "Quit")) {
      // TODO: Signal to quit game
    }

    // Debug toggle
    nk_layout_row_dynamic(ctx, 20, 1);
    nk_spacing(ctx, 1);
    nk_checkbox_label(ctx, "Show Debug HUD", &show_debug_hud);
  }
  nk_end(ctx);

  // Options window
  if (show_options) {
    if (nk_begin(ctx, "Options", nk_rect(300, 50, 250, 200),
                 NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE |
                     NK_WINDOW_CLOSABLE | NK_WINDOW_TITLE)) {
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
    if (nk_window_is_hidden(ctx, "Options")) {
      show_options = 0;
      nk_window_show(ctx, "Options", NK_SHOWN);
    }
    nk_end(ctx);
  }
}

// Main drawing function - called from Odin each frame
void menu_draw(struct nk_context *ctx) {
  // Draw with no HUD data (legacy compatibility)
  draw_main_menu(ctx, NULL);
}

// Draw with HUD data - called from Odin each frame
void menu_draw_with_hud(struct nk_context *ctx, const HudData *hud_data) {
  draw_debug_hud(ctx, hud_data);
  draw_main_menu(ctx, hud_data);
}
