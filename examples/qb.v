module main

import xiusin.very.database.query.builder

struct Test {
}

fn main() {
	b := builder.new_query_builder()

	age := 10

	b.offset(10).limit(100).table('qa').order_by('id', 'asc')
		.@select('t.name', 't.age', 't.address').add_select('app_t.age')
		.where('name', '=', 'xiusin')
		.where('age', [u64(1), 2, 3])
		.where('age', builder.new_query_builder().@select('id').as_arg())
		.where(fn [age] (mut b builder.Builder) {
			b.where('age  > ?', age)
		})
		.when(age > 10, fn [age] (mut b builder.Builder) {
			b.where('age  > ?', age)
		}, fn [age] (mut b builder.Builder) {
			b.where('age  <= ?', age)
		})
		.order_by_desc('name').group_by('id', 'name').distinct()

	dump(b)
}
