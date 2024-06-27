module main

import xiusin.very.database.query.builder

struct Test {
}

fn main() {
	b := builder.new_query_builder()

	b.offset(10).limit(100).table('qa').order_by('id', 'asc').@select('t.name', 't.age',
		't.address').add_select('app_t.age').order_by_desc('name').group_by('id', 'name').distinct()
	dump(b)
}
