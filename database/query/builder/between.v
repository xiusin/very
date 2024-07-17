module builder

fn (builder &Builder) where_between(field string, begin Arg, end Arg) {
	builder.where('${field} BETWEEN ? AND ?', begin, end)
}

fn (builder &Builder) where_not_between(field string, begin Arg, end Arg) {
	builder.where('${field} NOT BETWEEN ? AND ?', begin, end)
}
