module builder

fn (builder &Builder) where_between(field string, begin Arg, end Arg) {
	builder.where('${field} BETWEEN ? AND ?', begin, end)
}

fn (builder &Builder) where_not_between(field string, begin Arg, end Arg) {
	builder.where('${field} NOT BETWEEN ? AND ?', begin, end)
}

//
// func (builder *Builder) OrWhereBetween(field string, args interface{}) contracts.QueryBuilder {
// 	return builder.OrWhere(field, "between", args)
// }
//
// func (builder *Builder) WhereNotBetween(field string, args interface{}, whereType ...contracts.WhereJoinType) contracts.QueryBuilder {
// 	if len(whereType) > 0 {
// 		return builder.Where(field, "not between", args, whereType[0])
// 	}
//
// 	return builder.Where(field, "not between", args)
// }
//
// func (builder *Builder) OrWhereNotBetween(field string, args interface{}) contracts.QueryBuilder {
// 	return builder.OrWhere(field, "not between", args)
// }
