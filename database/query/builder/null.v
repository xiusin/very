module builder

pub fn (builder &Builder) where_is_null(field string) &Builder {
	builder.where(field, 'IS', 'NULL')
	unsafe {
		return builder
	}
}

pub fn (builder &Builder) where_is_not_null(field string) &Builder {
	builder.where(field, 'IS NOT', 'NULL')
	unsafe {
		return builder
	}
}

pub fn (builder &Builder) or_where_is_null(field string) &Builder {
	builder.or_where(field, 'IS', 'NULL')
	unsafe {
		return builder
	}
}

pub fn (builder &Builder) or_where_is_not_null(field string) &Builder {
	builder.or_where(field, 'IS NOT', 'NULL')
	unsafe {
		return builder
	}
}
