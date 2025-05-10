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

// pub fn (mut builder Builder) having(field string, args ...any) contracts.QueryBuilder {
// 	mut arg := args[0]
// 	mut condition := "="
// 	mut where_type := contracts.And
// 	match args.len {
// 		1 { arg = args[0] }
// 		2 {
// 			condition = args[0].str()
// 			arg = args[1]
// 		}
// 		3 {
// 			condition = args[0].str()
// 			arg = args[1]
// 			where_type = args[2] as contracts.WhereJoinType
// 		}
// 		else {}
// 	}
//
// 	raw, bindings := builder.prepare_args(condition, arg)
//
// 	builder.having.wheres[where_type] << &Where{
// 		field: field
// 		condition: condition
// 		arg: raw
// 	}
//
// 	return builder.add_binding(havingBinding, ...bindings)
// }
//
// pub fn (mut builder Builder) or_having(field string, args ...any) contracts.QueryBuilder {
// 	mut arg := args[0]
// 	mut condition := "="
// 	match args.len {
// 		1 { arg = args[0] }
// 		2 {
// 			condition = args[0].str()
// 			arg = args[1]
// 		}
// 		else {
// 			condition = args[0].str()
// 			arg = args[1]
// 		}
// 	}
// 	raw, bindings := builder.prepare_args(condition, arg)
//
// 	builder.having.wheres[contracts.Or] << &Where{
// 		field: field
// 		condition: condition
// 		arg: raw
// 	}
// 	return builder.add_binding(havingBinding, ...bindings)
// }