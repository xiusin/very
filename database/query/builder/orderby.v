module builder

pub fn (builder &Builder) order_by(field string, order_type ...string) &Builder {
	unsafe {
		builder.orderby << OrderBy{
			field: field
			order_type: if order_type.len == 0 { order_type[0] } else { 'ASC' }
		}
		return builder
	}
}

pub fn (builder &Builder) order_by_desc(field string) &Builder {
	unsafe {
		builder.orderby << OrderBy{
			field: field
			order_type: 'DESC'
		}
		return builder
	}
}

pub fn (builder &Builder) order_by_raw(raw string) &Builder {
	unsafe {
		builder.orderby = []
		builder.orderby_raw = raw
		return builder
	}
}
