module builder

pub fn (builder &Builder) group_by(columns ...string) &Builder {
	unsafe {
		builder.groupby << columns
		return builder
	}
}

pub fn (builder &Builder) group_by_raw(raw string) &Builder {
	unsafe {
		builder.groupby = []
		builder.groupby_raw = raw
		return builder
	}
}

pub fn (builder &Builder) having(field string, args ...voidptr) &Builder {
	// switch args.len {
	// 	case 1:
	// }

	return unsafe { builder }
}

pub fn (builder &Builder) or_having(field string, args ...voidptr) &Builder {
	// switch args.len {
	// 	case 1:
	// }

	return unsafe { builder }
}
