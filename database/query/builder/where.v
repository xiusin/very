module builder

pub fn (b &Builder) where(param WhereParam, args ...voidptr) &Builder {
	unsafe {
		return b
	}
}
