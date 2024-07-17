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
	return result.trim_left(' ')
}

pub fn (builder &Builder) @union(union_builder &Builder) &Builder {
	unsafe {
		builder.unions[UnionType.@union] << union_builder
		return builder
	}
}

pub fn (builder &Builder) union_all(union_builder &Builder) &Builder {
	unsafe {
		builder.unions[UnionType.union_all] << union_builder
		return builder
	}
}
