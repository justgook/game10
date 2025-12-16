package game

// https://pkg.odin-lang.org/core/text/i18n/#Translation 

import "core:fmt"
import "core:text/i18n"

T :: i18n.get
Tn :: #force_inline proc(singular, plural: string, n: int) -> string {
	return i18n.get_n(singular, n)
}

i18n_init :: proc() {

}
