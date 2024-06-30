module builder

fn (builder &Builder) where_is_null(field string) {
	builder.where(field, 'is', 'NULL')
}

fn (builder &Builder) where_is_not_null(field string) {
	builder.where(field, 'is not', 'NULL')
}

fn (builder &Builder) or_where_is_null(field string) {
	builder.or_where(field, 'is', 'NULL')
}

fn (builder &Builder) or_where_is_not_null(field string) {
	builder.or_where(field, 'is not', 'NULL')
}
