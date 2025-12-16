package ui
import "core:fmt"
import mu "microui2"

game9_draw_frame :: proc(ctx: ^mu.Context, rect: mu.Rect, colorid: mu.Color_Type, id: mu.Id) {
	rect := rect
	color := ctx.style.colors[colorid]
	anim_offset: i32 = 100
	alfa := 1

	#partial switch colorid {
	// case .TITLE_BG:
	// 	color = mu.Color{250, 250, 250, 255}
	// rect.y -= 100
	case .WINDOW_BG:
		delta := min(i32(ctx.frame - mu.get_container(ctx, id).created), anim_offset)
		rect.x = rect.x - anim_offset + i32(delta)
	case .BUTTON:
		return
	case .BUTTON_HOVER:
		anim_length: i32 = 18
		delta := min(i32(ctx.frame - ctx.hovered), anim_length)
		delta2 := f64(delta) / f64(anim_length)
		if delta2 < .25 {
			color = mu.Color{250, 250, 250, 255}
			new_h: i32 = 2
			rect.y += (rect.h - new_h) / 2
			rect.h = new_h
			rect.x -= 8
			rect.w += 16
		} else if delta2 < .50 {
			color = mu.Color{250, 250, 250, 255}
			new_h: i32 = rect.h - 8
			rect.y += (rect.h - new_h) / 2
			rect.h = new_h
			rect.x += 4
			rect.w -= 8
		} else if delta2 < .75 {
			color = mu.Color{172, 250, 250, 255}
			new_h: i32 = rect.h + 8
			rect.y += (rect.h - new_h) / 2
			rect.h = new_h
			rect.x -= 4
			rect.w += 8
		}

		mu.draw_rect(ctx, rect, color)
		return

	// rect.x = rect.x - anim_offset + i32(delta)
	case .BUTTON_FOCUS:
		delta := min(i32(ctx.frame - ctx.focused), anim_offset)
		rect.y = rect.y - anim_offset + i32(delta)
	case .BUTTON_DISABLED:

	}

	mu.draw_rect(ctx, rect, color)
	if colorid == .SCROLL_BASE || colorid == .SCROLL_THUMB || colorid == .TITLE_BG {
		return
	}
	// if ctx.style.colors[.BORDER].a != 0 { /* draw border */
	mu.draw_box(ctx, mu.add_padding(rect, 1), ctx.style.colors[.BORDER], size = 1)
	// }
}

game9_draw_titlebar :: proc(ctx: ^mu.Context, title: string, opt: mu.Options, id: mu.Id) {
	cnt := mu.get_container_id(ctx, id, opt)
	tr := cnt.rect
	tr.x += ctx.style.padding
	tr.h = ctx.style.title_height
	tr.y -= ctx.style.title_height //- ctx.style.padding
	tr.w = ctx.text_width(ctx.style.font, title) + ctx.style.padding * 2

	ctx.style.draw_frame(ctx, tr, .TITLE_BG, id)

	/* do title text */
	if .NO_TITLE not_in opt {
		// tid := mu.get_id(ctx, "!title")
		// mu.update_control(ctx, tid, tr, opt)
		font := ctx.style.font
		mu.draw_text(
			ctx,
			font,
			title,
			mu.Vec2{tr.x + ctx.style.padding, tr.y},
			ctx.style.colors[.TITLE_TEXT],
		)
	}
}

game9_style := mu.Style {
	draw_frame = game9_draw_frame,
	draw_titlebar = game9_draw_titlebar,
	font = nil,
	size = {68, 10},
	padding = 5,
	spacing = 4,
	indent = 24,
	title_height = 12,
	footer_height = 20,
	scrollbar_size = 12,
	thumb_size = 8,
	colors = {
		.TEXT            = {250, 250, 250, 255},
		.TEXT_HOVER      = {10, 10, 10, 255},
		.SELECTION_BG    = {90, 90, 90, 255},
		.BORDER          = {27, 213, 250, 255},
		.WINDOW_BG       = {10, 10, 10, 255},
		.TITLE_BG        = {10, 10, 10, 255},
		.TITLE_TEXT      = {27, 213, 250, 255},
		.PANEL_BG        = {0, 0, 0, 0},
		.BUTTON          = {75, 75, 75, 255},
		.BUTTON_HOVER    = {27, 213, 250, 255},
		.BUTTON_FOCUS    = {115, 0, 115, 255},
		.BUTTON_DISABLED = {255, 0, 0, 255},
		.BASE            = {30, 30, 30, 255},
		// .BASE_HOVER      = {35, 35, 35, 255},
		.BASE_HOVER      = {35, 0, 0, 255},
		.BASE_FOCUS      = {40, 40, 40, 255},
		.BASE_DISABLED   = {30, 30, 30, 255},
		.SCROLL_BASE     = {43, 43, 43, 255},
		.SCROLL_THUMB    = {30, 30, 30, 255},
	},
}
