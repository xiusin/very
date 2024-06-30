module builder

import very.contracts

pub type QueryCallBack = fn (mut b Builder)

pub type Expr = string

pub type WhereParam = Arg | QueryCallBack | []Arg | map[string]Arg | string

pub type Args = []Arg

fn (m Args) to_strings() []string {
	mut r := []string{}
	for _, arg in m {
		r << arg.str()
	}
	return r
}

const err_not_found_record = error('not found record')

struct OrderBy {
	field      string
	order_type string
}

pub struct Builder {
mut:
	table       string
	limit       i64
	offset      i64
	distinct    bool
	unions      Unions
	orderby     []OrderBy
	orderby_raw string
	fields      []string = ['*']
	groupby     []string
	groupby_raw string
	wheres      []string
}

pub fn (b &Builder) distinct() &Builder {
	unsafe {
		b.distinct = true
		return b
	}
}

pub fn (b &Builder) model(taber contracts.Tabler) &Builder {
	unsafe {
		b.table = taber.table_name()
		return b
	}
}

pub fn (b &Builder) table(table TableName, alias ...string) &Builder {
	unsafe {
		b.table = table.to_string(...alias)
		return b
	}
}

pub fn (b &Builder) from(table TableName, alias ...string) &Builder {
	unsafe {
		b.table(table, ...alias)
		return b
	}
}

pub fn (b &Builder) form_many(tables ...TableName) &Builder {
	unsafe {
		mut ts := []string{}
		for table in tables {
			ts << table.to_string()
		}
		b.table = ts.join(',')
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

pub fn (b &Builder) when(condition bool, cb QueryCallBack, else_cb ...QueryCallBack) &Builder {
	unsafe {
		if condition {
			cb(mut b)
		} else if else_cb.len > 0 {
			else_cb[0](mut b)
		}
		return b
	}
}

pub fn (b &Builder) pagination(size i64, current ...i64) &Builder {
	unsafe {
		b.limit = size
		if current.len > 0 {
			b.offset = size * (current[0] - 1)
		}
		return b
	}
}

pub fn (b &Builder) as_arg() Arg {
	return Arg(b)
}

pub fn (b &Builder) to_sql() string {
	return b.wheres.join(' AND ')
}
