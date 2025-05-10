module main

import xiusin.very.database.query.builder

fn main() {
	test_builder()
	// test_table_name()
	return
}

fn test_table_name() {
	dump(builder.TableName('qa_test').to_string())
	dump(builder.table('(select * from qa_test)'))
	dump(builder.table(fn () string {
		return '(select * from qa_test1) AS t'
	}))
	dump(builder.table(fn () string {
		return 'select * from qa_test2'
	}))
	dump(builder.table(fn () string {
		return '(select * from qa_test3)'
	}))
}

fn test_builder() {
	age := 10

	mut map_where := map[string]builder.Arg{}
	map_where['name'] = 'xiusin'
	map_where['height'] = 3000
	// mut arr_where := []builder.Arg{}
	// arr_where << builder.Arg(['name', '=', 'xiusin'])
	// arr_where << builder.Arg(['name', 'xiusin'])
	// arr_where << builder.Arg(['name', '>', 'xiusin'])

	ages := [f64(1), 2.1, 3.3]
	b := builder.query().offset(10).limit(100).table('qa').order_by('id', 'asc')
		.@select('t.name', 't.age', 't.address').add_select('app_t.age')
		.where('name', '=', 'xiusin')
		.where('name', 'xiusin')
		.where('age', ages)
		.where(map_where)
		// .where(arr_where)
		.where('age', builder.new_query_builder().table('user_role').@select('id').as_arg())
		.when(age > 10, fn [age] (mut b builder.Builder) {
			b.where('age', ">", age)
		}, fn [age] (mut b builder.Builder) {
			b.where('age', "<=", age)
		})
		.order_by_desc('name').group_by('id', 'name').distinct().to_sql()

	dump(b)
}
