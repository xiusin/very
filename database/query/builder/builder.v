module builder

pub type QueryCallBack = fn (mut b Builder)

pub type WhereParam = Builder | QueryCallBack | string

pub type Arg = []Arg
	| []i16
	| []i32
	| []int
	| []string
	| []u16
	| []u32
	| []u64
	| []u8
	| bool
	| int
	| map[string]Arg
	| string

struct OrderBy {
	field      string
	order_type string
}

struct Builder {
mut:
	table       string
	limit       i64
	offset      i64
	distinct    bool
	orderby     []OrderBy
	orderby_raw string
	fields      []string
	groupby     []string
	groupby_raw string
}

pub fn new_query_builder() &Builder {
	return &Builder{}
}

pub fn (b &Builder) distinct() &Builder {
	unsafe {
		b.distinct = true
		return b
	}
}

pub fn (b &Builder) model[T]() &Builder {
	unsafe {
		// model := T {}

		return b
	}
}

pub fn (b &Builder) table(table string) &Builder {
	unsafe {
		b.table = table
		return b
	}
}

pub fn (b &Builder) from(table string) &Builder {
	unsafe {
		b.table(table)
		return b
	}
}

pub fn (b &Builder) @select(columns ...string) &Builder {
	unsafe {
		b.fields = []
		b.add_select(...columns)
		return b
	}
}

pub fn (b &Builder) add_select(columns ...string) &Builder {
	unsafe {
		if columns.len > 0 {
			b.fields << columns
		}
		return b
	}
}

pub fn (b &Builder) skip(offset i64) &Builder {
	unsafe {
		return b.offset(offset)
	}
}

pub fn (b &Builder) take(num i64) &Builder {
	unsafe {
		return b.limit(num)
	}
}

pub fn (b &Builder) offset(offset i64) &Builder {
	unsafe {
		b.offset = offset
		return b
	}
}

pub fn (b &Builder) limit(num i64) &Builder {
	unsafe {
		b.limit = num
		return b
	}
}

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

pub fn (b &Builder) when(condition bool, cb QueryCallBack, else_cb ...QueryCallBack) &Builder {
	unsafe {
		if condition {
			cb(mut b)
		} else if else_cb.len > 0 {
			cbe := else_cb[0]
			cbe(mut b)
		}
		return b
	}
}

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

pub fn (b &Builder) pagination(size i64, current ...i64) &Builder {
	unsafe {
		mut ins := b
		ins.limit = size
		if current.len > 0 {
			ins.offset = size * (current[0] - 1)
		}
		return b
	}
}

// 生成sql
pub fn (b &Builder) string() string {
	return ''
}

// 转换为sql
pub fn (b &Builder) to_sql() string {
	return 'full sql'
}
