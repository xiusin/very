module builder

enum UnionType {
	@union
	union_all
}

type Unions = map[UnionType][]Builder

fn (u Unions) string() string {
	mut result := ''
	if u.len == 0 {
		return result
	}
	for union_type, builders in u {
		if builders.len == 0 {
			continue
		}

		typ := if union_type == .@union { 'UNION' } else { 'UNION ALL' }
		for _, builder in builders {
			result = '${result} ${typ} (${builder.to_sql()})'
		}
	}
	return result
}

pub fn (b &Builder) @union(union_builder &Builder) &Builder {
	unsafe {
		b.unions[UnionType.@union] << union_builder
		return b
	}
}

pub fn (b &Builder) union_all(union_builder &Builder) &Builder {
	unsafe {
		b.unions[UnionType.union_all] << union_builder
		return b
	}
}
