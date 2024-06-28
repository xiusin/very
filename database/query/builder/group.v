module builder

pub fn (b &Builder) group_by(columns ...string) &Builder {
	unsafe {
		b.groupby << columns
		return b
	}
}

pub fn (b &Builder) group_by_raw(raw string) &Builder {
	unsafe {
		b.groupby = []
		b.groupby_raw = raw
		return b
	}
}

pub fn (b &Builder) having(field string, args ...voidptr) &Builder {
	// switch args.len {
	// 	case 1:
	// }

	return unsafe { b }
}

pub fn (b &Builder) or_having(field string, args ...voidptr) &Builder {
	// switch args.len {
	// 	case 1:
	// }

	return unsafe { b }
}
