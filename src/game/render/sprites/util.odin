package sprites


Flip :: enum {
	Horizontally,
	Vertically,
	Anti_Diagonally,
}

Flip_Set :: bit_set[Flip]

FLIP_MATRICES := [8][4]f32 {
	/* {}                           */
	{1, 0, 0, 1}, // Identity
	/* {.Horizontally}              */
	{-1, 0, 0, 1}, // H flip
	/* {.Vertically}                */
	{1, 0, 0, -1}, // V flip
	/* {.Horizontally, .Vertically} */
	{-1, 0, 0, -1}, // 180°
	/* {.Anti_Diagonally}           */
	{0, 1, 1, 0}, // Diagonal
	/* {.Anti_Diagonally, .H}       */
	{0, -1, 1, 0}, // 90°
	/* {.Anti_Diagonally, .V}       */
	{0, 1, -1, 0}, // 270°
	/* {.Anti_Diagonally, .H, .V}   */
	{0, -1, -1, 0}, // Anti-diagonal
}
// based on tiled https://discourse.mapeditor.org/t/can-i-rotate-tiles/703/4
get_flip_matrix :: proc(flags: Flip_Set = {}) -> [4]f32 {
	return FLIP_MATRICES[transmute(u8)flags]
}

/*
 * All possible orthogonal transformations (12 total)
ROTATIONS := [12]Flip_Set{
   // Regular rotations
   {},                                         // 0°
   {.Anti_Diagonally, .Horizontally},         // 90°
   {.Horizontally, .Vertically},              // 180°
   {.Anti_Diagonally, .Vertically},           // 270°
   
   // Horizontal flips + rotations
   {.Horizontally},                           // 0° + H flip
   {.Anti_Diagonally},                        // 90° + H flip
   {.Vertically},                             // 180° + H flip
   {.Anti_Diagonally, .Horizontally, .Vertically}, // 270° + H flip
   
   // Vertical flips + rotations
   {.Vertically},                             // 0° + V flip
   {.Anti_Diagonally, .Horizontally, .Vertically}, // 90° + V flip
   {.Horizontally},                           // 180° + V flip
   {.Anti_Diagonally},                        // 270° + V flip
}
*/
