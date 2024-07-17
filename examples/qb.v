module main

import xiusin.very.database.query.builder
import json
import time

pub type DbValueInt = i64

pub type DbValueUint = u64

pub type BaseType = DbValueInt | DbValueUint | []BaseType | bool | f64 | string

pub struct Info {
mut:
	name string
	age  int
	arr  []BaseType
}

pub struct Test {
mut:
	id         int
	name       string
	images     []string
	info       ?Info
	t_none     ?string
	created_at time.Time
}

fn (mut t Test) decode(field string, value string) ! {
	match field {
		'info' {
			t.info = json.decode(Info, value)!
		}
		'created_at' {
			if value.len > 0 {
				parsed := time.parse(value) or { time.unix(0) }
				t.created_at = parsed
			}
		}
		else {}
	}
}

fn main() {
	test_builder()
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
	// dump(builder.insert('insert into test(name) values(?)', 'xiusin') or { panic(err) })
	// dump(builder.update('update test set name = ? where id = ?', 'zhangan', 1) or { panic(err) })
	// mut result := builder.select_as_maps('select * from test where id = 1', 1) or { panic(err) }
	// mut result := builder.@select[Test]('select * from test') or { panic(err) }
	// println(json.encode(result))
	//
	mut map_where := map[string]builder.Arg{}
	map_where['height'] = 3000

	mut arr_where := []builder.Arg{}
	arr_where << builder.Arg(['name', 'very'])
	arr_where << builder.Arg(['age', 'IN', ['a', 'b', 'c']])

	b := builder.query().offset(10).limit(100).table('qa').order_by('id', 'asc')
		.@select('t.name', 't.age', 't.address').add_select('app_t.age')
		.where('name', '<>', 'very')
		.where('age', [f64(1), 2.1, 3.3])
		.where('name', 'like', '%xiu%')
		.where_is_null('name')
		.where_is_not_null('age')
		.where(map_where)
		.where(arr_where)
		.where('age', builder.new_query_builder().@select('id').as_arg())
		.order_by_desc('name').group_by('id', 'name').distinct()

	println(b.to_sql())

	// println(b)
}
