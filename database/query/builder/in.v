module builder

fn (builder &Builder) where_in(field string, args ...Arg) &Builder {
	unsafe {
		builder.where(field, 'IN', args)
		return builder
	}
}

fn (builder &Builder) or_where_in(field string, args ...Arg) &Builder {
	unsafe {
		builder.or_where(field, 'IN', args)
		return builder
	}
}

fn (builder &Builder) where_not_in(field string, args ...Arg) &Builder {
	unsafe {
		builder.where(field, 'NOT IN', args)
		return builder
	}
}

fn (builder &Builder) or_where_not_in(field string, args ...Arg) &Builder {
	unsafe {
		builder.or_where(field, 'NOT IN', args)
		return builder
	}
}
