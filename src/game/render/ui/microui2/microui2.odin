/*
** Original work: Copyright (c) 2020 rxi
** Modified work: Copyright (c) 2020 oskarnp
** Modified work: Copyright (c) 2021 gingerBill
** Modified work: Copyright (c) 2025 justgook
**
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to
** deal in the Software without restriction, including without limitation the
** rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
** sell copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
**
** The above copyright notice and this permission notice shall be included in
** all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
** FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
** IN THE SOFTWARE.
*/

package microui2

import "core:fmt"
import "core:math"
import "core:sort"
import "core:strings"

COMMAND_LIST_SIZE :: #config(MICROUI_COMMAND_LIST_SIZE, 256 * 1024)
ROOT_LIST_SIZE :: #config(MICROUI_ROOT_LIST_SIZE, 32)
CONTAINER_STACK_SIZE :: #config(MICROUI_CONTAINER_STACK_SIZE, 32)
CLIP_STACK_SIZE :: #config(MICROUI_CLIP_STACK_SIZE, 32)
ID_STACK_SIZE :: #config(MICROUI_ID_STACK_SIZE, 32)
LAYOUT_STACK_SIZE :: #config(MICROUI_LAYOUT_STACK_SIZE, 16)
CONTAINER_POOL_SIZE :: #config(MICROUI_CONTAINER_POOL_SIZE, 48)
TREENODE_POOL_SIZE :: #config(MICROUI_TREENODE_POOL_SIZE, 48)
MAX_WIDTHS :: #config(MICROUI_MAX_WIDTHS, 16)

Clip :: enum u32 {
	NONE,
	PART,
	ALL,
}

Color_Type :: enum u32 {
	TEXT,
	TEXT_HOVER,
	SELECTION_BG,
	BORDER,
	WINDOW_BG,
	TITLE_BG,
	TITLE_TEXT,
	PANEL_BG,
	BUTTON,
	BUTTON_HOVER,
	BUTTON_FOCUS,
	BUTTON_DISABLED,
	BASE,
	BASE_HOVER,
	BASE_FOCUS,
	BASE_DISABLED,
	SCROLL_BASE,
	SCROLL_THUMB,
}

Icon :: enum u32 {
	NONE,
	CLOSE,
	CHECK,
	COLLAPSED,
	EXPANDED,
	RESIZE,
}

Result :: enum u32 {
	ACTIVE,
	SUBMIT,
	CHANGE,
}

Result_Set :: bit_set[Result;u32]

Opt :: enum u32 {
	ALIGN_CENTER,
	ALIGN_RIGHT,
	ALIGN_TOP,
	ALIGN_BOTTOM,
	DISABLED,
	NO_FRAME,
	NO_RESIZE,
	NO_SCROLL,
	NO_CLOSE,
	NO_TITLE,
	HOLD_FOCUS,
	AUTO_SIZE,
	EXPANDED,
	NO_DRAG,
	NO_FOCUS,
}

Options :: distinct bit_set[Opt;u32]

Mouse :: enum u32 {
	LEFT,
	RIGHT,
	MIDDLE,
}

Mouse_Set :: distinct bit_set[Mouse;u32]

UI_Controlls :: enum u32 {}

/*
 *



static const _BuiltinActionDisplayName _builtin_action_display_names[] = {
	/* clang-format off */
	{ "ui_accept",                                     TTRC("Accept") },
	{ "ui_select",                                     TTRC("Select") },
	{ "ui_cancel",                                     TTRC("Cancel") },
	{ "ui_focus_next",                                 TTRC("Focus Next") },
	{ "ui_focus_prev",                                 TTRC("Focus Prev") },
	{ "ui_left",                                       TTRC("Left") },
	{ "ui_right",                                      TTRC("Right") },
	{ "ui_up",                                         TTRC("Up") },
	{ "ui_down",                                       TTRC("Down") },
	{ "ui_page_up",                                    TTRC("Page Up") },
	{ "ui_page_down",                                  TTRC("Page Down") },
	{ "ui_home",                                       TTRC("Home") },
	{ "ui_end",                                        TTRC("End") },
	{ "ui_cut",                                        TTRC("Cut") },
	{ "ui_copy",                                       TTRC("Copy") },
	{ "ui_paste",                                      TTRC("Paste") },
	{ "ui_focus_mode",                                 TTRC("Toggle Tab Focus Mode") },
	{ "ui_undo",                                       TTRC("Undo") },
	{ "ui_redo",                                       TTRC("Redo") },
	{ "ui_text_completion_query",                      TTRC("Completion Query") },
	{ "ui_text_newline",                               TTRC("New Line") },
	{ "ui_text_newline_blank",                         TTRC("New Blank Line") },
	{ "ui_text_newline_above",                         TTRC("New Line Above") },
	{ "ui_text_indent",                                TTRC("Indent") },
	{ "ui_text_dedent",                                TTRC("Dedent") },
	{ "ui_text_backspace",                             TTRC("Backspace") },
	{ "ui_text_backspace_word",                        TTRC("Backspace Word") },
	{ "ui_text_backspace_word.macos",                  TTRC("Backspace Word") },
	{ "ui_text_backspace_all_to_left",                 TTRC("Backspace all to Left") },
	{ "ui_text_backspace_all_to_left.macos",           TTRC("Backspace all to Left") },
	{ "ui_text_delete",                                TTRC("Delete") },
	{ "ui_text_delete_word",                           TTRC("Delete Word") },
	{ "ui_text_delete_word.macos",                     TTRC("Delete Word") },
	{ "ui_text_delete_all_to_right",                   TTRC("Delete all to Right") },
	{ "ui_text_delete_all_to_right.macos",             TTRC("Delete all to Right") },
	{ "ui_text_caret_left",                            TTRC("Caret Left") },
	{ "ui_text_caret_word_left",                       TTRC("Caret Word Left") },
	{ "ui_text_caret_word_left.macos",                 TTRC("Caret Word Left") },
	{ "ui_text_caret_right",                           TTRC("Caret Right") },
	{ "ui_text_caret_word_right",                      TTRC("Caret Word Right") },
	{ "ui_text_caret_word_right.macos",                TTRC("Caret Word Right") },
	{ "ui_text_caret_up",                              TTRC("Caret Up") },
	{ "ui_text_caret_down",                            TTRC("Caret Down") },
	{ "ui_text_caret_line_start",                      TTRC("Caret Line Start") },
	{ "ui_text_caret_line_start.macos",                TTRC("Caret Line Start") },
	{ "ui_text_caret_line_end",                        TTRC("Caret Line End") },
	{ "ui_text_caret_line_end.macos",                  TTRC("Caret Line End") },
	{ "ui_text_caret_page_up",                         TTRC("Caret Page Up") },
	{ "ui_text_caret_page_down",                       TTRC("Caret Page Down") },
	{ "ui_text_caret_document_start",                  TTRC("Caret Document Start") },
	{ "ui_text_caret_document_start.macos",            TTRC("Caret Document Start") },
	{ "ui_text_caret_document_end",                    TTRC("Caret Document End") },
	{ "ui_text_caret_document_end.macos",              TTRC("Caret Document End") },
	{ "ui_text_caret_add_below",                       TTRC("Caret Add Below") },
	{ "ui_text_caret_add_below.macos",                 TTRC("Caret Add Below") },
	{ "ui_text_caret_add_above",                       TTRC("Caret Add Above") },
	{ "ui_text_caret_add_above.macos",                 TTRC("Caret Add Above") },
	{ "ui_text_scroll_up",                             TTRC("Scroll Up") },
	{ "ui_text_scroll_up.macos",                       TTRC("Scroll Up") },
	{ "ui_text_scroll_down",                           TTRC("Scroll Down") },
	{ "ui_text_scroll_down.macos",                     TTRC("Scroll Down") },
	{ "ui_text_select_all",                            TTRC("Select All") },
	{ "ui_text_select_word_under_caret",               TTRC("Select Word Under Caret") },
	{ "ui_text_add_selection_for_next_occurrence",     TTRC("Add Selection for Next Occurrence") },
	{ "ui_text_skip_selection_for_next_occurrence",    TTRC("Skip Selection for Next Occurrence") },
	{ "ui_text_clear_carets_and_selection",            TTRC("Clear Carets and Selection") },
	{ "ui_text_toggle_insert_mode",                    TTRC("Toggle Insert Mode") },
	{ "ui_text_submit",                                TTRC("Submit Text") },
	{ "ui_graph_duplicate",                            TTRC("Duplicate Nodes") },
	{ "ui_graph_delete",                               TTRC("Delete Nodes") },
	{ "ui_graph_follow_left",                          TTRC("Follow Input Port Connection") },
	{ "ui_graph_follow_right",                         TTRC("Follow Output Port Connection") },
	{ "ui_filedialog_up_one_level",                    TTRC("Go Up One Level") },
	{ "ui_filedialog_refresh",                         TTRC("Refresh") },
	{ "ui_filedialog_show_hidden",                     TTRC("Show Hidden") },
	{ "ui_swap_input_direction ",                      TTRC("Swap Input Direction") },
	{ "ui_unicode_start",                              TTRC("Start Unicode Character Input") },
	{ "ui_colorpicker_delete_preset",                  TTRC("ColorPicker: Delete Preset") },
	{ "ui_accessibility_drag_and_drop",                TTRC("Accessibility: Keyboard Drag and Drop") },
	{ "",                                              ""}
	/* clang-format on */
};

 **/
Key :: enum u32 {
	SHIFT,
	CTRL,
	ALT,
	BACKSPACE,
	DELETE,
	RETURN,
	LEFT,
	RIGHT,
	HOME,
	END,
	A,
	X,
	C,
	V,
}

Key_Set :: distinct bit_set[Key;u32]

Id :: distinct u32
Font :: distinct rawptr
Vec2 :: distinct [2]i32
Rect :: struct {
	x, y, w, h: i32,
}

Color :: struct {
	r, g, b, a: u8,
}

Frame_Index :: distinct i32
Pool_Item :: struct {
	id:          Id,
	last_update: Frame_Index,
}


Command_Variant :: union {
	^Command_Jump,
	^Command_Clip,
	^Command_Rect,
	^Command_Text,
	^Command_Icon,
}

Command :: struct {
	variant:      Command_Variant,
	container_id: Id,
	size:         i32,
}

Command_Jump :: struct {
	using command: Command,
	dst:           rawptr,
}

Command_Clip :: struct {
	using command: Command,
	rect:          Rect,
}

Command_Rect :: struct {
	using command: Command,
	rect:          Rect,
	color:         Color,
}

Command_Text :: struct {
	using command: Command,
	font:          Font,
	pos:           Vec2,
	color:         Color,
	str:           string, /* + string data (VLA) */
}

Command_Icon :: struct {
	using command: Command,
	rect:          Rect,
	id:            Icon,
	color:         Color,
}


Layout_Type :: enum {
	NONE     = 0,
	RELATIVE = 1,
	ABSOLUTE = 2,
}

Layout :: struct {
	body, next:                  Rect,
	position, size, max:         Vec2,
	widths:                      [MAX_WIDTHS]i32,
	items, item_index, next_row: i32,
	next_type:                   Layout_Type,
	indent:                      i32,
}

// https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html
Neighbours :: struct {
	previus, next, up, right, bottom, left: Id,
}

Container :: struct {
	head, tail:   ^Command,
	rect, body:   Rect,
	content_size: Vec2,
	scroll:       Vec2,
	zindex:       i32,
	no_focus:     bool,

	// Use for animations
	created:      Frame_Index,
	// hovered:      Frame_Index,
	// Not implemented
	neighbours:   Neighbours,
}

Style :: struct {
	font:           Font,
	draw_frame:     proc(ctx: ^Context, rect: Rect, colorid: Color_Type, id: Id),
	draw_titlebar:  proc(ctx: ^Context, title: string, opt: Options, id: Id),
	size:           Vec2,
	padding:        i32,
	spacing:        i32,
	indent:         i32,
	title_height:   i32,
	footer_height:  i32,
	scrollbar_size: i32,
	thumb_size:     i32,
	colors:         [Color_Type]Color,
}

Context :: struct {
	/* callbacks */
	text_width:                      proc(font: Font, str: string) -> i32,
	text_height:                     proc(font: Font) -> i32,
	/* core state */
	_style:                          Style,
	style:                           ^Style,
	hover_id, focus_id, last_id:     Id,
	// focus:                           Focus_Next,
	last_rect:                       Rect,
	last_zindex:                     i32,
	updated_focus:                   b32,
	focused:                         Frame_Index,
	hovered:                         Frame_Index,
	frame:                           Frame_Index,
	hover_root, next_hover_root:     ^Container,
	scroll_target:                   ^Container,
	/* stacks */
	command_list:                    Stack(u8, COMMAND_LIST_SIZE),
	root_list:                       Stack(^Container, ROOT_LIST_SIZE),
	container_stack:                 Stack(^Container, CONTAINER_STACK_SIZE),
	clip_stack:                      Stack(Rect, CLIP_STACK_SIZE),
	id_stack:                        Stack(Id, ID_STACK_SIZE),
	layout_stack:                    Stack(Layout, LAYOUT_STACK_SIZE),
	/* retained state pools */
	container_pool:                  [CONTAINER_POOL_SIZE]Pool_Item,
	containers:                      [CONTAINER_POOL_SIZE]Container,
	treenode_pool:                   [TREENODE_POOL_SIZE]Pool_Item,
	/* input state */
	mouse_pos, last_mouse_pos:       Vec2,
	mouse_delta, scroll_delta:       Vec2,
	mouse_down_bits:                 Mouse_Set,
	mouse_pressed_bits:              Mouse_Set,
	mouse_released_bits:             Mouse_Set,
	key_down_bits, key_pressed_bits: Key_Set,
}

Stack :: struct($T: typeid, $N: int) {
	idx:   i32,
	items: [N]T,
}

push :: #force_inline proc(stk: ^$T/Stack($V, $N), val: V) {
	assert(stk.idx < len(stk.items))
	stk.items[stk.idx] = val
	stk.idx += 1
}

pop :: #force_inline proc(stk: ^$T/Stack($V, $N)) {
	assert(stk.idx > 0)
	stk.idx -= 1
}

unclipped_rect := Rect{0, 0, 0x1000000, 0x1000000}


add_padding :: proc(rect: Rect, n: i32) -> Rect {
	return Rect{rect.x - n, rect.y - n, rect.w + n * 2, rect.h + n * 2}
}

intersect_rects :: proc(r1, r2: Rect) -> Rect {
	x1 := max(r1.x, r2.x)
	y1 := max(r1.y, r2.y)
	x2 := min(r1.x + r1.w, r2.x + r2.w)
	y2 := min(r1.y + r1.h, r2.y + r2.h)
	if x2 < x1 {x2 = x1}
	if y2 < y1 {y2 = y1}
	return Rect{x1, y1, x2 - x1, y2 - y1}
}

rect_overlaps_vec2 :: proc(r: Rect, p: Vec2) -> bool {
	return p.x >= r.x && p.x < r.x + r.w && p.y >= r.y && p.y < r.y + r.h
}


init :: proc(ctx: ^Context, style := default_style) {
	ctx^ = {} // zero memory
	ctx._style = style
	ctx.style = &ctx._style
}

begin :: proc(ctx: ^Context) {
	assert(ctx.text_width != nil, "ctx.text_width is not set")
	assert(ctx.text_height != nil, "ctx.text_height is not set")
	ctx.command_list.idx = 0
	ctx.root_list.idx = 0
	ctx.scroll_target = nil
	ctx.hover_root = ctx.next_hover_root
	ctx.next_hover_root = nil
	ctx.mouse_delta.x = ctx.mouse_pos.x - ctx.last_mouse_pos.x
	ctx.mouse_delta.y = ctx.mouse_pos.y - ctx.last_mouse_pos.y
	ctx.frame += 1
}

end :: proc(ctx: ^Context) {
	/* check stacks */
	assert(ctx.container_stack.idx == 0)
	assert(ctx.clip_stack.idx == 0)
	assert(ctx.id_stack.idx == 0)
	assert(ctx.layout_stack.idx == 0)

	/* handle scroll input */
	if ctx.scroll_target != nil {
		ctx.scroll_target.scroll.x += ctx.scroll_delta.x
		ctx.scroll_target.scroll.y += ctx.scroll_delta.y
	}

	/* unset focus if focus id was not touched this frame */
	if !ctx.updated_focus {
		ctx.focus_id = 0
	}
	ctx.updated_focus = false

	/* bring hover root to front if mouse was pressed */
	if mouse_pressed(ctx) &&
	   ctx.next_hover_root != nil &&
	   !ctx.next_hover_root.no_focus &&
	   ctx.next_hover_root.zindex < ctx.last_zindex &&
	   ctx.next_hover_root.zindex >= 0 {
		bring_to_front(ctx, ctx.next_hover_root)
	}

	/* reset input state */
	ctx.key_pressed_bits = {} // clear
	ctx.mouse_pressed_bits = {} // clear
	ctx.mouse_released_bits = {} // clear
	ctx.scroll_delta = Vec2{0, 0}
	ctx.last_mouse_pos = ctx.mouse_pos

	/* sort root containers by zindex */
	n := ctx.root_list.idx
	sort.quick_sort_proc(ctx.root_list.items[:n], proc(a, b: ^Container) -> int {
		return int(a.zindex) - int(b.zindex)
	})

	/* set root container jump commands */
	for i: i32 = 0; i < n; i += 1 {
		cnt := ctx.root_list.items[i]
		/* if this is the first container then make the first command jump to it.
		** otherwise set the previous container's tail to jump to this one */
		if i == 0 {
			cmd := (^Command_Jump)(&ctx.command_list.items[0])
			cmd.dst = rawptr(uintptr(cnt.head) + size_of(Command_Jump))
		} else {
			prev := ctx.root_list.items[i - 1]
			prev.tail.variant.(^Command_Jump).dst = rawptr(
				uintptr(cnt.head) + size_of(Command_Jump),
			)
		}
		/* make the last container's tail jump to the end of command list */
		if i == n - 1 {
			cnt.tail.variant.(^Command_Jump).dst = rawptr(
				&ctx.command_list.items[ctx.command_list.idx],
			)
		}
	}
}

set_focus :: proc(ctx: ^Context, id: Id) {
	ctx.focus_id = id
	ctx.updated_focus = true
	ctx.focused = id > 0 ? ctx.frame : 0
}

set_hover :: proc(ctx: ^Context, id: Id) {
	if id != ctx.hover_id {
		ctx.hovered = id > 0 ? ctx.frame : 0
	}

	ctx.hover_id = id
}

get_id :: proc {
	get_id_string,
	get_id_bytes,
	get_id_rawptr,
	get_id_uintptr,
}

get_id_string :: #force_inline proc(ctx: ^Context, str: string) -> Id {return get_id_bytes(
		ctx,
		transmute([]byte)str,
	)}

get_id_rawptr :: #force_inline proc(
	ctx: ^Context,
	data: rawptr,
	size: int,
) -> Id {return get_id_bytes(ctx, ([^]u8)(data)[:size])}

get_id_uintptr :: #force_inline proc(ctx: ^Context, ptr: uintptr) -> Id {
	ptr := ptr
	return get_id_bytes(ctx, ([^]u8)(&ptr)[:size_of(ptr)])
}

get_id_bytes :: proc(ctx: ^Context, bytes: []byte) -> Id {
	/* 32bit fnv-1a hash */
	HASH_INITIAL :: 2166136261
	hash :: proc(hash: ^Id, data: []byte) {
		size := len(data)
		cptr := ([^]u8)(raw_data(data))
		for ; size > 0; size -= 1 {
			hash^ = Id(u32(hash^) ~ u32(cptr[0])) * 16777619
			cptr = cptr[1:]
		}
	}

	idx := ctx.id_stack.idx
	res := ctx.id_stack.items[idx - 1] if idx > 0 else HASH_INITIAL
	hash(&res, bytes)
	ctx.last_id = res
	return res
}

push_id :: proc {
	push_id_string,
	push_id_bytes,
	push_id_rawptr,
	push_id_uintptr,
}

push_id_string :: #force_inline proc(ctx: ^Context, str: string) {push(
		&ctx.id_stack,
		get_id(ctx, str),
	)}

push_id_rawptr :: #force_inline proc(ctx: ^Context, data: rawptr, size: int) {push(
		&ctx.id_stack,
		get_id(ctx, data, size),
	)}

push_id_uintptr :: #force_inline proc(ctx: ^Context, ptr: uintptr) {push(
		&ctx.id_stack,
		get_id(ctx, ptr),
	)}

push_id_bytes :: #force_inline proc(ctx: ^Context, bytes: []byte) {push(
		&ctx.id_stack,
		get_id(ctx, bytes),
	)}

pop_id :: proc(ctx: ^Context) {
	pop(&ctx.id_stack)
}

push_clip_rect :: proc(ctx: ^Context, rect: Rect) {
	last := get_clip_rect(ctx)
	push(&ctx.clip_stack, intersect_rects(rect, last))
}

pop_clip_rect :: proc(ctx: ^Context) {
	pop(&ctx.clip_stack)
}

get_clip_rect :: proc(ctx: ^Context) -> Rect {
	assert(ctx.clip_stack.idx > 0)
	return ctx.clip_stack.items[ctx.clip_stack.idx - 1]
}

check_clip :: proc(ctx: ^Context, r: Rect) -> Clip {
	cr := get_clip_rect(ctx)
	if r.x > cr.x + cr.w || r.x + r.w < cr.x || r.y > cr.y + cr.h || r.y + r.h < cr.y {
		return .ALL
	}
	if r.x >= cr.x && r.x + r.w <= cr.x + cr.w && r.y >= cr.y && r.y + r.h <= cr.y + cr.h {
		return .NONE
	}
	return .PART
}

get_layout :: proc(ctx: ^Context) -> ^Layout {
	return &ctx.layout_stack.items[ctx.layout_stack.idx - 1]
}

@(private)
push_layout :: proc(ctx: ^Context, body: Rect, scroll: Vec2) {
	layout: Layout
	layout.body = Rect{body.x - scroll.x, body.y - scroll.y, body.w, body.h}
	layout.max = Vec2{-0x1000000, -0x1000000}
	push(&ctx.layout_stack, layout)
	layout_row(ctx, {0})
}

@(private)
pop_container :: proc(ctx: ^Context) {
	cnt := get_current_container(ctx)
	layout := get_layout(ctx)
	cnt.content_size.x = layout.max.x - layout.body.x
	cnt.content_size.y = layout.max.y - layout.body.y
	/* pop container, layout and id */
	pop(&ctx.container_stack)
	pop(&ctx.layout_stack)
	pop_id(ctx)
}

get_current_container :: proc(ctx: ^Context) -> ^Container {
	assert(ctx.container_stack.idx > 0)
	return ctx.container_stack.items[ctx.container_stack.idx - 1]
}

get_container_id :: proc(ctx: ^Context, id: Id, opt := Options{}) -> ^Container {
	/* try to get existing container from pool */
	idx, ok := pool_get(ctx, ctx.container_pool[:], id)
	if ok {
		// if ctx.containers[idx].open || .CLOSED not_in opt {
		pool_update(ctx, &ctx.container_pool[idx])
		// }
		return &ctx.containers[idx]
	}
	// if .CLOSED in opt {return nil}
	/* container not found in pool: init new container */
	idx = pool_init(ctx, ctx.container_pool[:], id)
	cnt := &ctx.containers[idx]
	cnt^ = {} // clear memory
	cnt.created = ctx.frame

	bring_to_front(ctx, cnt)
	return cnt
}

get_container_title :: proc(ctx: ^Context, id: string, opt := Options{}) -> ^Container {
	id := get_id(ctx, id)
	return get_container_id(ctx, id, opt)
}

get_container :: proc {
	get_container_title,
	get_container_id,
}


bring_to_front :: proc(ctx: ^Context, cnt: ^Container) {
	ctx.last_zindex += 1
	cnt.zindex = ctx.last_zindex
}

/*============================================================================
** pool
**============================================================================*/

pool_init :: proc(ctx: ^Context, items: []Pool_Item, id: Id) -> int {
	f := ctx.frame
	n := -1
	for _, i in items {
		if items[i].last_update < f {
			f = items[i].last_update
			n = i
		}
	}
	assert(n > -1)
	items[n].id = id
	pool_update(ctx, &items[n])
	return n
}

pool_get :: proc(ctx: ^Context, items: []Pool_Item, id: Id) -> (int, bool) {
	for _, i in items {
		if items[i].id == id {
			return i, true
		}
	}
	return -1, false
}

pool_update :: proc(ctx: ^Context, item: ^Pool_Item) {
	item.last_update = ctx.frame
}

/*============================================================================
** input handlers
**============================================================================*/

input_mouse_move :: proc(ctx: ^Context, x, y: i32) {
	ctx.mouse_pos = Vec2{x, y}
}

input_mouse_down :: proc(ctx: ^Context, x, y: i32, btn: Mouse) {
	input_mouse_move(ctx, x, y)
	ctx.mouse_down_bits += {btn}
	ctx.mouse_pressed_bits += {btn}
}

input_mouse_up :: proc(ctx: ^Context, x, y: i32, btn: Mouse) {
	input_mouse_move(ctx, x, y)
	ctx.mouse_down_bits -= {btn}
	ctx.mouse_released_bits += {btn}
}

input_scroll :: proc(ctx: ^Context, x, y: i32) {
	ctx.scroll_delta.x += x
	ctx.scroll_delta.y += y
}

input_key_down :: proc(ctx: ^Context, key: Key) {
	ctx.key_pressed_bits += {key}
	ctx.key_down_bits += {key}
}

input_key_up :: proc(ctx: ^Context, key: Key) {
	ctx.key_down_bits -= {key}
}


/*============================================================================
** commandlist
**============================================================================*/

push_command :: proc(ctx: ^Context, $Type: typeid, extra_size := 0, id: Id = 0) -> ^Type {
	size := i32(size_of(Type) + extra_size)
	cmd := transmute(^Type)&ctx.command_list.items[ctx.command_list.idx]
	assert(ctx.command_list.idx + size < COMMAND_LIST_SIZE)
	ctx.command_list.idx += size
	cmd.variant = cmd
	cmd.size = size
	return cmd
}

next_command :: proc "contextless" (ctx: ^Context, pcmd: ^^Command) -> bool {
	cmd := pcmd^
	defer pcmd^ = cmd
	if cmd != nil {
		cmd = (^Command)(uintptr(cmd) + uintptr(cmd.size))
	} else {
		cmd = (^Command)(&ctx.command_list.items[0])
	}

	invalid_command :: #force_inline proc "contextless" (ctx: ^Context) -> ^Command {
		return (^Command)(&ctx.command_list.items[ctx.command_list.idx])
	}

	for cmd != invalid_command(ctx) {
		if jmp, ok := cmd.variant.(^Command_Jump); ok {
			cmd = (^Command)(jmp.dst)
			continue
		}
		return true
	}

	return false
}

next_command_iterator :: proc "contextless" (
	ctx: ^Context,
	pcm: ^^Command,
) -> (
	Command_Variant,
	bool,
) {
	if next_command(ctx, pcm) {
		return pcm^.variant, true
	}
	return nil, false
}

@(private)
push_jump :: proc(ctx: ^Context, dst: ^Command) -> ^Command {
	cmd := push_command(ctx, Command_Jump)
	cmd.dst = dst
	return cmd
}

set_clip :: proc(ctx: ^Context, rect: Rect) {
	cmd := push_command(ctx, Command_Clip)
	cmd.rect = rect
}

draw_rect :: proc(ctx: ^Context, rect: Rect, color: Color, id: Id = 0) {
	rect := rect
	rect = intersect_rects(rect, get_clip_rect(ctx))
	if rect.w > 0 && rect.h > 0 {
		cmd := push_command(ctx, Command_Rect, id = id)
		cmd.rect = rect
		cmd.color = color
	}
}

draw_box :: proc(ctx: ^Context, rect: Rect, color: Color, id: Id = 0, size: i32 = 1) {
	draw_rect(ctx, Rect{rect.x + size, rect.y, rect.w - 2 * size, size}, color, id)
	draw_rect(ctx, Rect{rect.x + size, rect.y + rect.h - size, rect.w - 2 * size, size}, color, id)
	draw_rect(ctx, Rect{rect.x, rect.y, size, rect.h}, color)
	draw_rect(ctx, Rect{rect.x + rect.w - size, rect.y, size, rect.h}, color, id)
}

draw_text :: proc(ctx: ^Context, font: Font, str: string, pos: Vec2, color: Color, id: Id = 0) {
	rect := Rect{pos.x, pos.y, ctx.text_width(font, str), ctx.text_height(font)}
	clipped := check_clip(ctx, rect)
	switch clipped {
	case .NONE: // okay
	case .ALL:
		return
	case .PART:
		set_clip(ctx, get_clip_rect(ctx))
	}
	/* add command */
	text_cmd := push_command(ctx, Command_Text, len(str), id)
	text_cmd.pos = pos
	text_cmd.color = color
	text_cmd.font = font
	/* copy string */
	dst_str := ([^]byte)(text_cmd)[size_of(Command_Text):][:len(str)]
	copy(dst_str, str)
	text_cmd.str = string(dst_str)
	/* reset clipping if it was set */
	if clipped != .NONE {
		set_clip(ctx, unclipped_rect)
	}
}

draw_icon :: proc(ctx: ^Context, icon_id: Icon, rect: Rect, color: Color, id: Id) {
	/* do clip command if the rect isn't fully contained within the cliprect */
	clipped := check_clip(ctx, rect)
	switch clipped {
	case .NONE: // okay
	case .ALL:
		return
	case .PART:
		set_clip(ctx, get_clip_rect(ctx))
	}
	/* do icon command */
	cmd := push_command(ctx, Command_Icon, id = id)
	cmd.id = icon_id
	cmd.rect = rect
	cmd.color = color
	/* reset clipping if it was set */
	if clipped != .NONE {
		set_clip(ctx, unclipped_rect)
	}
}

/*============================================================================
** layout
**============================================================================*/

layout_begin_column :: proc(ctx: ^Context) {
	push_layout(ctx, layout_next(ctx), Vec2{0, 0})
}

layout_end_column :: proc(ctx: ^Context) {
	b := get_layout(ctx)
	pop(&ctx.layout_stack)
	/* inherit position/next_row/max from child layout if they are greater */
	a := get_layout(ctx)
	a.position.x = max(a.position.x, b.position.x + b.body.x - a.body.x)
	a.next_row = max(a.next_row, b.next_row + b.body.y - a.body.y)
	a.max.x = max(a.max.x, b.max.x)
	a.max.y = max(a.max.y, b.max.y)
}

@(deferred_in = layout_end_column)
layout_column :: proc(ctx: ^Context) -> bool {
	layout_begin_column(ctx)
	return true
}

layout_row :: proc(ctx: ^Context, widths: []i32, height: i32 = 0) {
	layout := get_layout(ctx)
	items := len(widths)
	if len(widths) > 0 {
		items = copy(layout.widths[:], widths[:])
	}
	layout.items = i32(items)
	layout.position = Vec2{layout.indent, layout.next_row}
	layout.size.y = height
	layout.item_index = 0
}

layout_row_items :: proc(ctx: ^Context, items: i32, height: i32 = 0) {
	layout := get_layout(ctx)
	layout.items = items
	layout.position = Vec2{layout.indent, layout.next_row}
	layout.size.y = height
	layout.item_index = 0
}


layout_width :: proc(ctx: ^Context, width: i32) {
	get_layout(ctx).size.x = width
}

layout_height :: proc(ctx: ^Context, height: i32) {
	get_layout(ctx).size.y = height
}

layout_set_next :: proc(ctx: ^Context, r: Rect, relative: bool) {
	layout := get_layout(ctx)
	layout.next = r
	layout.next_type = .RELATIVE if relative else .ABSOLUTE
}

layout_next :: proc(ctx: ^Context) -> (res: Rect) {
	layout := get_layout(ctx)
	style := ctx.style
	defer ctx.last_rect = res

	if layout.next_type != .NONE {
		/* handle rect set by `layout_set_next` */
		type := layout.next_type
		layout.next_type = .NONE
		res = layout.next
		if type == .ABSOLUTE {
			return
		}
	} else {
		/* handle next row */
		if layout.item_index == layout.items {
			layout_row_items(ctx, layout.items, layout.size.y)
		}

		/* position */
		res.x = layout.position.x
		res.y = layout.position.y

		/* size */
		res.w = layout.items > 0 ? layout.widths[layout.item_index] : layout.size.x
		res.h = layout.size.y
		if res.w == 0 {res.w = style.size.x + style.padding * 2}
		if res.h == 0 {res.h = style.size.y + style.padding * 2}
		if res.w < 0 {res.w += layout.body.w - res.x + 1}
		if res.h < 0 {res.h += layout.body.h - res.y + 1}

		layout.item_index += 1
	}

	/* update position */
	layout.position.x += res.w + style.spacing
	layout.next_row = max(layout.next_row, res.y + res.h + style.spacing)

	/* apply body offset */
	res.x += layout.body.x
	res.y += layout.body.y

	/* update max position */
	layout.max.x = max(layout.max.x, res.x + res.w)
	layout.max.y = max(layout.max.y, res.y + res.h)
	return
}

/*============================================================================
** controls
**============================================================================*/

@(private)
in_hover_root :: proc(ctx: ^Context) -> bool {
	for i := ctx.container_stack.idx - 1; i >= 0; i -= 1 {
		if ctx.container_stack.items[i] == ctx.hover_root {
			return true
		}
		/* only root containers have their `head` field set; stop searching if we've
		** reached the current root container */
		if ctx.container_stack.items[i].head != nil {
			break
		}
	}
	return false
}

draw_control_frame :: proc(
	ctx: ^Context,
	rect: Rect,
	colorid: Color_Type,
	opt := Options{},
	id: Id,
) {
	if .NO_FRAME in opt {
		return
	}
	assert(colorid == .BUTTON || colorid == .BASE)
	colorid := colorid
	colorid = Color_Type(
		int(colorid) +
		int((.DISABLED in opt) ? 3 : (ctx.focus_id == id) ? 2 : (ctx.hover_id == id) ? 1 : 0),
	)


	ctx.style.draw_frame(ctx, rect, colorid, id)
}

draw_control_text :: proc(
	ctx: ^Context,
	str: string,
	rect: Rect,
	colorid: Color_Type,
	opt := Options{},
	id: Id,
) {
	pos: Vec2
	font := ctx.style.font
	tw := ctx.text_width(font, str)
	push_clip_rect(ctx, rect)
	pos.y = rect.y + (rect.h - ctx.text_height(font)) / 2
	if .ALIGN_CENTER in opt {
		pos.x = rect.x + (rect.w - tw) / 2
	} else if .ALIGN_RIGHT in opt {
		pos.x = rect.x + rect.w - tw - ctx.style.padding
	} else {
		pos.x = rect.x + ctx.style.padding
	}

	if .ALIGN_TOP in opt {
		pos.y = rect.y + ctx.style.padding
	} else if .ALIGN_BOTTOM in opt {
		pos.y = rect.y + rect.h - ctx.text_height(font) - ctx.style.padding
	}

	draw_text(ctx, font, str, pos, ctx.style.colors[colorid])
	pop_clip_rect(ctx)
}

mouse_over :: proc(ctx: ^Context, rect: Rect) -> bool {
	return(
		rect_overlaps_vec2(rect, ctx.mouse_pos) &&
		rect_overlaps_vec2(get_clip_rect(ctx), ctx.mouse_pos) &&
		in_hover_root(ctx) \
	)
}

update_control :: proc(ctx: ^Context, id: Id, rect: Rect, opt := Options{}) {
	if .DISABLED in opt {
		return
	}

	if ctx.focus_id == id {
		ctx.updated_focus = true
	}

	mouseover := mouse_over(ctx, rect)
	if mouseover && !mouse_down(ctx) {
		set_hover(ctx, id)
	}

	if ctx.focus_id == id {
		if mouse_pressed(ctx) && !mouseover {
			set_focus(ctx, 0)
		} else if !mouse_down(ctx) && .HOLD_FOCUS not_in opt {
			set_focus(ctx, 0)
		}
	}

	if ctx.hover_id == id {
		if mouse_pressed(ctx) {
			set_focus(ctx, id)
		} else if !mouseover {
			set_hover(ctx, 0)
		}
	}
}

text :: proc(ctx: ^Context, text: string) {
	text := text
	font := ctx.style.font
	color := ctx.style.colors[.TEXT]
	layout_begin_column(ctx)
	layout_row(ctx, {-1}, ctx.text_height(font))
	for len(text) > 0 {
		w: i32
		start: int
		end: int = len(text)
		r := layout_next(ctx)
		for ch, i in text {
			if ch == ' ' || ch == '\n' {
				word := text[start:i]
				w += ctx.text_width(font, word)
				if w > r.w && start != 0 {
					end = start
					break
				}
				w += ctx.text_width(font, text[i:i + 1])
				if ch == '\n' {
					end = i + 1
					break
				}
				start = i + 1
			}
		}
		draw_text(ctx, font, text[:end], Vec2{r.x, r.y}, color)
		text = text[end:]
	}
	layout_end_column(ctx)
}

label :: proc(ctx: ^Context, text: string, id: Id = 0) {
	draw_control_text(ctx, text, layout_next(ctx), .TEXT, id = id)
}

button :: proc(
	ctx: ^Context,
	label: string,
	icon: Icon = .NONE,
	opt: Options = {.ALIGN_CENTER},
) -> (
	res: Result_Set,
) {
	id := len(label) > 0 ? get_id(ctx, label) : get_id(ctx, uintptr(icon))
	r := layout_next(ctx)
	update_control(ctx, id, r, opt)
	/* handle click */
	if ctx.mouse_pressed_bits == {.LEFT} && ctx.focus_id == id {
		res += {.SUBMIT}
	}
	/* draw */
	draw_control_frame(ctx, r, .BUTTON, opt, id)
	if len(label) > 0 {
		draw_control_text(ctx, label, r, (ctx.hover_id == id) ? .TEXT_HOVER : .TEXT, opt, id)
	}
	if icon != .NONE {
		draw_icon(ctx, icon, r, ctx.style.colors[.TEXT], id)
	}

	return
}

SLIDER_FMT :: #config(MICROUI_SLIDER_FMT, "%.2f")
MAX_FMT :: #config(MICROUI_MAX_FMT, 127)
Real :: f32

slider :: proc(
	ctx: ^Context,
	value: ^Real,
	low, high: Real,
	step: Real = 0.0,
	fmt_string: string = SLIDER_FMT,
	opt: Options = {.ALIGN_CENTER},
) -> (
	res: Result_Set,
) {
	last := value^
	v := last
	id := get_id(ctx, uintptr(value))
	base := layout_next(ctx)


	/* handle normal mode */
	update_control(ctx, id, base, opt)

	/* handle input */
	if ctx.focus_id == id && ctx.mouse_down_bits == {.LEFT} {
		v = low + Real(ctx.mouse_pos.x - base.x) * (high - low) / Real(base.w)
		if step != 0.0 {
			v = math.floor((v + step / 2) / step) * step
		}
	}
	/* clamp and store value, update res */
	v = clamp(v, low, high)
	value^ = v
	if last != v {
		res += {.CHANGE}
	}

	/* draw base */
	draw_control_frame(ctx, base, .BASE, opt, id)
	/* draw thumb */
	w := ctx.style.thumb_size
	x := i32((v - low) * Real(base.w - w) / (high - low))
	thumb := Rect{base.x + x, base.y, w, base.h}
	draw_control_frame(ctx, thumb, .BUTTON, opt, id)
	/* draw text  */
	text_buf: [4096]byte
	draw_control_text(ctx, fmt.bprintf(text_buf[:], fmt_string, v), base, .TEXT, opt, id)

	return
}

toggle :: proc(
	ctx: ^Context,
	label: string,
	icon: Icon = .NONE,
	opt: Options = {.ALIGN_CENTER},
) -> (
	res: Result_Set,
) {
	id := len(label) > 0 ? get_id(ctx, label) : get_id(ctx, uintptr(icon))
	idx, active := pool_get(ctx, ctx.treenode_pool[:], id)
	expanded := .EXPANDED in opt ? !active : active

	r := layout_next(ctx)
	update_control(ctx, id, r, opt)

	/* handle click */
	if ctx.mouse_pressed_bits == {.LEFT} && ctx.focus_id == id {
		res += {.SUBMIT}
		active = !active
	}

	/* update pool ref */
	if idx >= 0 {
		if active {
			pool_update(ctx, &ctx.treenode_pool[idx])
		} else {
			ctx.treenode_pool[idx] = {}
		}
	} else if active {
		pool_init(ctx, ctx.treenode_pool[:], id)
	}

	/* draw */
	draw_control_frame(ctx, r, .BUTTON, opt, id)
	if len(label) > 0 {
		draw_control_text(ctx, label, r, (ctx.hover_id == id) ? .TEXT_HOVER : .TEXT, opt, id)
	}
	if icon != .NONE {
		draw_icon(ctx, icon, r, ctx.style.colors[.TEXT], id)
	}

	if expanded {
		res += {.ACTIVE}
	}

	return
}

checkbox :: proc(ctx: ^Context, label: string, state: ^bool) -> (res: Result_Set) {
	id := get_id(ctx, uintptr(state))
	r := layout_next(ctx)
	box := Rect{r.x, r.y, r.h, r.h}
	update_control(ctx, id, r, {})
	/* handle click */
	if .LEFT in ctx.mouse_released_bits && ctx.hover_id == id {
		res += {.CHANGE}
		state^ = !state^
	}
	/* draw */
	draw_control_frame(ctx, box, .BASE, id = id)
	if state^ {
		draw_icon(ctx, .CHECK, box, ctx.style.colors[.TEXT], id)
	}
	r = Rect{r.x + box.w, r.y, r.w - box.w, r.h}
	draw_control_text(ctx, label, r, .TEXT, id = id)

	return
}


@(private)
_header :: proc(ctx: ^Context, label: string, is_treenode: bool, opt := Options{}) -> Result_Set {
	id := get_id(ctx, label)
	idx, active := pool_get(ctx, ctx.treenode_pool[:], id)
	expanded := .EXPANDED in opt ? !active : active
	layout_row(ctx, {-1})
	r := layout_next(ctx)
	update_control(ctx, id, r, {})
	/* handle click */
	if ctx.mouse_pressed_bits == {.LEFT} && ctx.focus_id == id {
		active = !active
	}
	/* update pool ref */
	if idx >= 0 {
		if active {
			pool_update(ctx, &ctx.treenode_pool[idx])
		} else {
			ctx.treenode_pool[idx] = {}
		}
	} else if active {
		pool_init(ctx, ctx.treenode_pool[:], id)
	}
	/* draw */
	if is_treenode {
		if ctx.hover_id == id {
			ctx.style.draw_frame(ctx, r, .BUTTON_HOVER, id)
		}
	} else {
		draw_control_frame(ctx, r, .BUTTON, id = id)
	}

	draw_icon(
		ctx,
		expanded ? .EXPANDED : .COLLAPSED,
		Rect{r.x, r.y, r.h, r.h},
		ctx.style.colors[.TEXT],
		id = id,
	)
	r.x += r.h - ctx.style.padding
	r.w -= r.h - ctx.style.padding
	draw_control_text(ctx, label, r, .TEXT, id = id)
	return expanded ? {.ACTIVE} : {}
}

header :: proc(ctx: ^Context, label: string, opt := Options{}) -> Result_Set {
	return _header(ctx, label, false, opt)
}

begin_treenode :: proc(ctx: ^Context, label: string, opt := Options{}) -> Result_Set {
	res := _header(ctx, label, true, opt)
	if .ACTIVE in res {
		get_layout(ctx).indent += ctx.style.indent
		push(&ctx.id_stack, ctx.last_id)
	}
	return res
}

end_treenode :: proc(ctx: ^Context) {
	get_layout(ctx).indent -= ctx.style.indent
	pop_id(ctx)
}


scoped_end_treenode :: proc(ctx: ^Context, _: string, _: Options, result_set: Result_Set) {
	if result_set != nil {
		end_treenode(ctx)
	}
}

/* This is scoped and is intended to be use in the condition of a if-statement */
@(deferred_in_out = scoped_end_treenode)
treenode :: proc(ctx: ^Context, label: string, opt := Options{}) -> Result_Set {
	return begin_treenode(ctx, label, opt)
}


@(private)
scrollbar :: proc(ctx: ^Context, cnt: ^Container, _b: ^Rect, cs: Vec2, id_string: string, i: int) {
	b := (^struct {
			pos, size: [2]i32,
		})(_b)
	#assert(size_of(b^) == size_of(_b^))

	/* only add scrollbar if content size is larger than body */
	maxscroll := cs[i] - b.size[i]
	contentsize := b.size[i]
	if maxscroll > 0 && contentsize > 0 {
		id := get_id(ctx, id_string)

		/* get sizing / positioning */
		base := b^
		base.pos[1 - i] = b.pos[1 - i] + b.size[1 - i]
		base.size[1 - i] = ctx.style.scrollbar_size

		/* handle input */
		update_control(ctx, id, transmute(Rect)base)
		if ctx.focus_id == id && .LEFT in ctx.mouse_down_bits {
			cnt.scroll[i] += ctx.mouse_delta[i] * cs[i] / base.size[i]
		}
		/* clamp scroll to limits */
		cnt.scroll[i] = clamp(cnt.scroll[i], 0, maxscroll)

		/* draw base and thumb */
		ctx.style.draw_frame(ctx, transmute(Rect)base, .SCROLL_BASE, id)
		thumb := base
		thumb.size[i] = max(ctx.style.thumb_size, base.size[i] * b.size[i] / cs[i])
		thumb.pos[i] += cnt.scroll[i] * (base.size[i] - thumb.size[i]) / maxscroll
		ctx.style.draw_frame(ctx, transmute(Rect)thumb, .SCROLL_THUMB, id)

		/* set this as the scroll_target (will get scrolled on mousewheel) */
		/* if the mouse is over it */
		if mouse_over(ctx, transmute(Rect)b^) {
			ctx.scroll_target = cnt
		}
	} else {
		cnt.scroll[i] = 0
	}
}

@(private)
scrollbars :: proc(ctx: ^Context, cnt: ^Container, body: ^Rect) {
	sz := ctx.style.scrollbar_size
	cs := cnt.content_size
	cs.x += ctx.style.padding * 2
	cs.y += ctx.style.padding * 2
	push_clip_rect(ctx, body^)
	/* resize body to make room for scrollbars */
	if cs.y > cnt.body.h {body.w -= sz}
	if cs.x > cnt.body.w {body.h -= sz}
	/* to create a horizontal or vertical scrollbar almost-identical code is
	** used; only the references to `x|y` `w|h` need to be switched */
	scrollbar(ctx, cnt, body, cs, "!scrollbarv", 1) // 1 = y,h
	scrollbar(ctx, cnt, body, cs, "!scrollbarh", 0) // 0 = x,w
	pop_clip_rect(ctx)
}

@(private)
push_container_body :: proc(ctx: ^Context, cnt: ^Container, body: Rect, opt := Options{}) {
	body := body
	if .NO_SCROLL not_in opt {
		scrollbars(ctx, cnt, &body)
	}
	push_layout(ctx, add_padding(body, -ctx.style.padding), cnt.scroll)
	cnt.body = body
}

@(private)
begin_root_container :: proc(ctx: ^Context, cnt: ^Container, opt: Options) {
	push(&ctx.container_stack, cnt)
	/* push container to roots list and push head command */
	push(&ctx.root_list, cnt)
	cnt.head = push_jump(ctx, nil)
	/* set as hover root if the mouse is overlapping this container and it has a
	** higher zindex than the current hover root */
	if .DISABLED not_in opt &&
	   rect_overlaps_vec2(cnt.rect, ctx.mouse_pos) &&
	   (ctx.next_hover_root == nil || cnt.zindex > ctx.next_hover_root.zindex) {
		ctx.next_hover_root = cnt
	}

	/* clipping is reset here in case a root-container is made within
	** another root-containers's begin/end block; this prevents the inner
	** root-container being clipped to the outer */
	push(&ctx.clip_stack, unclipped_rect)
}

@(private)
end_root_container :: proc(ctx: ^Context) {
	/* push tail 'goto' jump command and set head 'skip' command. the final steps
	** on initing these are done in end() */
	cnt := get_current_container(ctx)
	cnt.tail = push_jump(ctx, nil)
	cnt.head.variant.(^Command_Jump).dst = &ctx.command_list.items[ctx.command_list.idx]
	/* pop base clip rect and container */
	pop_clip_rect(ctx)
	pop_container(ctx)
}

begin_window :: proc(ctx: ^Context, title: string, rect: Rect, opt := Options{}) {
	assert(title != "", "missing window title")
	id := get_id(ctx, title)
	cnt := get_container_id(ctx, id, opt)

	push(&ctx.id_stack, id)

	if cnt.rect.w == 0 {
		cnt.rect = rect
	}

	begin_root_container(ctx, cnt, opt)

	cnt.body = cnt.rect
	cnt.no_focus = .NO_FOCUS in opt

	/* draw frame */
	if .NO_FRAME not_in opt {
		ctx.style.draw_frame(ctx, cnt.rect, .WINDOW_BG, id)
	}

	/* do title bar */
	if .NO_TITLE not_in opt {
		ctx.style.draw_titlebar(ctx, title, opt, id)
	}

	/* do `resize` handle */
	if .NO_RESIZE not_in opt {
		sz := ctx.style.footer_height
		rid := get_id(ctx, "!resize")
		r := Rect{cnt.rect.x + cnt.rect.w - sz, cnt.rect.y + cnt.rect.h - sz, sz, sz}
		draw_icon(ctx, .RESIZE, r, ctx.style.colors[.TEXT], id)
		update_control(ctx, rid, r, opt)
		if rid == ctx.focus_id && .LEFT in ctx.mouse_down_bits {
			cnt.rect.w = max(96, cnt.rect.w + ctx.mouse_delta.x)
			cnt.rect.h = max(64, cnt.rect.h + ctx.mouse_delta.y)
		}
		cnt.body.h -= sz
	}

	push_container_body(ctx, cnt, cnt.body, opt)

	/* resize to content size */
	if .AUTO_SIZE in opt {
		r := get_layout(ctx).body
		cnt.rect.w = cnt.content_size.x + (cnt.rect.w - r.w)
		cnt.rect.h = cnt.content_size.y + (cnt.rect.h - r.h)
	}

	push_clip_rect(ctx, cnt.body)
}

end_window :: proc(ctx: ^Context) {
	pop_clip_rect(ctx)
	end_root_container(ctx)
}


/* This is scoped and is intended to be use in the condition of a if-statement */
@(deferred_in_out = scoped_end_window)
window :: proc(ctx: ^Context, title: string, rect: Rect, opt := Options{}) {
	begin_window(ctx, title, rect, opt)
}

scoped_end_window :: proc(ctx: ^Context, _: string, _: Rect, _: Options) {
	end_window(ctx)
}

open_popup :: proc(ctx: ^Context, name: string) {
	cnt := get_container(ctx, name)
	/* set as hover root so popup isn't closed in begin_window()  */
	ctx.hover_root = cnt
	ctx.next_hover_root = cnt
	/* position at mouse cursor, open and bring-to-front */
	cnt.rect = Rect{ctx.mouse_pos.x, ctx.mouse_pos.y, 1, 1}
	// cnt.open = true
	bring_to_front(ctx, cnt)
}

begin_popup :: proc(ctx: ^Context, name: string) {
	opt := Options{.AUTO_SIZE, .NO_RESIZE, .NO_SCROLL, .NO_TITLE}
	begin_window(ctx, name, Rect{}, opt)
}

end_popup :: proc(ctx: ^Context) {
	end_window(ctx)
}


/* This is scoped and is intended to be use in the condition of a if-statement */
@(deferred_in_out = scoped_end_popup)
popup :: proc(ctx: ^Context, name: string) {
	begin_popup(ctx, name)
}

scoped_end_popup :: proc(ctx: ^Context, _: string) {
	end_popup(ctx)
}

begin_panel :: proc(ctx: ^Context, name: string, opt := Options{}) {
	assert(name != "", "missing panel name")
	push_id(ctx, name)
	id := ctx.last_id
	cnt := get_container_id(ctx, ctx.last_id, opt)
	cnt.rect = layout_next(ctx)
	if .NO_FRAME not_in opt {
		ctx.style.draw_frame(ctx, cnt.rect, .PANEL_BG, id)
	}
	push(&ctx.container_stack, cnt)
	push_container_body(ctx, cnt, cnt.rect, opt)
	push_clip_rect(ctx, cnt.body)
}

end_panel :: proc(ctx: ^Context) {
	pop_clip_rect(ctx)
	pop_container(ctx)
}

@(private)
mouse_released :: #force_inline proc(ctx: ^Context) -> bool {return ctx.mouse_released_bits != nil}
@(private)
mouse_pressed :: #force_inline proc(ctx: ^Context) -> bool {return ctx.mouse_pressed_bits != nil}
@(private)
mouse_down :: #force_inline proc(ctx: ^Context) -> bool {return ctx.mouse_down_bits != nil}
