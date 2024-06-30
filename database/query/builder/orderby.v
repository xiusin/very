module builder

pub fn (b &Builder) order_by(field string, order_type ...string) &Builder {
	unsafe {
		b.orderby << OrderBy{
			field: field
			order_type: if order_type.len == 0 { order_type[0] } else { 'ASC' }
		}
		return b
	}
}

pub fn (b &Builder) order_by_desc(field string) &Builder {
	unsafe {
		b.orderby << OrderBy{
			field: field
			order_type: 'DESC'
		}
		return b
	}
}

pub fn (b &Builder) order_by_raw(raw string) &Builder {
	unsafe {
		b.orderby = []
		b.orderby_raw = raw
		return b
	}
}
