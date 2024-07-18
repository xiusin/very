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

fn (mut o OrderBy) str() string {
	if o.order_type.len == 0 {
		return o.field
	}
	return '${o.field} ${o.order_type}'
}

type OrderBys = []OrderBy

fn (mut o OrderBys) str() string {
	mut items := []string{}
	for _, item in o {
		items << '${item}'
	}
	return items.join(',')
}

pub struct Builder {
mut:
	table       string
	limit       i64
	offset      i64
	distinct    bool
	unions      Unions
	orderby     OrderBys
	orderby_raw string
	fields      []string = ['*']
	groupby     []string
	groupby_raw string
	wheres      []string
}

pub fn (builder &Builder) distinct() &Builder {
	unsafe {
		builder.distinct = true
		return builder
	}
}

pub fn (builder &Builder) model(taber contracts.Tabler) &Builder {
	unsafe {
		builder.table = taber.table_name()
		return builder
	}
}

pub fn (builder &Builder) table(table TableName, alias ...string) &Builder {
	unsafe {
		builder.table = table.to_string(...alias)
		return builder
	}
}

pub fn (builder &Builder) from(table TableName, alias ...string) &Builder {
	unsafe {
		return builder.table(table, ...alias)
	}
}

pub fn (builder &Builder) form_many(tables ...TableName) &Builder {
	unsafe {
		mut ts := []string{}
		for table in tables {
			ts << table.to_string()
		}
		builder.table = ts.join(',')
		return builder
	}
}

pub fn (builder &Builder) @select(columns ...string) &Builder {
	unsafe {
		builder.fields = []
		return builder.add_select(...columns)
	}
}

pub fn (builder &Builder) select_sub(cb Builder, as_ string) &Builder {
	unsafe {
		builder.fields = []
		return builder.add_select('(${cb.to_sql()}) AS ${as_}')
	}
}

pub fn (builder &Builder) add_select(columns ...string) &Builder {
	unsafe {
		if columns.len > 0 {
			builder.fields << columns
		}
		return builder
	}
}

pub fn (builder &Builder) add_select_sub(cb Builder, as_ string) &Builder {
	unsafe {
		return builder.add_select('(${cb.to_sql()}) AS ${as_}')
	}
}

pub fn (builder &Builder) skip(offset i64) &Builder {
	unsafe {
		return builder.offset(offset)
	}
}

pub fn (builder &Builder) take(num i64) &Builder {
	unsafe {
		return builder.limit(num)
	}
}

pub fn (builder &Builder) offset(offset i64) &Builder {
	unsafe {
		builder.offset = offset
		return builder
	}
}

pub fn (builder &Builder) limit(num i64) &Builder {
	unsafe {
		builder.limit = num
		return builder
	}
}

pub fn (builder &Builder) when(condition bool, cb QueryCallBack, else_cb ...QueryCallBack) &Builder {
	unsafe {
		if condition {
			cb(mut builder)
		} else if else_cb.len > 0 {
			else_cb[0](mut builder)
		}
		return builder
	}
}

pub fn (builder &Builder) pagination(size i64, current ...i64) &Builder {
	unsafe {
		builder.limit = size
		if current.len > 0 {
			builder.offset = size * (current[0] - 1)
		}
		return builder
	}
}

pub fn (builder &Builder) as_arg() Arg {
	return Arg(builder)
}

fn (builder &Builder) builder_select() string {
	if builder.distinct {
		return 'DISTINCT ${builder.fields.join(',')}'
	}
	return builder.fields.join(',')
}

pub fn (builder &Builder) to_sql() string {
	mut sql_ := 'SELECT ${builder.builder_select()} FROM ${builder.table}'

	if builder.wheres.len > 0 {
		sql_ += ' WHERE ${builder.wheres.join(' AND ')}'
	}

	sql_ += if builder.groupby.len > 0 {
		' GROUP BY ${builder.groupby.join(',')}'
	} else if builder.groupby_raw.len > 0 {
		' GROUP BY ${builder.groupby_raw}'
	} else {
		''
	}

	sql_ += if builder.orderby.len > 0 {
		' ORDER BY ${builder.orderby}'
	} else if builder.orderby_raw.len > 0 {
		' ORDER BY ${builder.orderby_raw}'
	} else {
		''
	}
	return sql_
}
