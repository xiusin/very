module builder

pub type Arg = Builder
	| []Arg
	| []f32
	| []f64
	| []i16
	| []i32
	| []i64
	| []i8
	| []int
	| []string
	| []u16
	| []u32
	| []u64
	| []u8
	| bool
	| int
	| map[string]Arg
	| string

fn convert_number_to_string[T](arr []T) string {
	mut items := []string{}
	for _, item in arr {
		items << '${item}'
	}
	return '(${items.join(', ')})'
}

// 挪到where构建里去
fn (a Arg) build_where(builder &Builder) {
	match a {
		[]Arg {
			match a.len {
				1 {
					builder.where(a[0] as string)
				}
				2 {
					builder.where(a[0] as string, a[1])
				}
				3 {
					builder.where(a[0] as string, a[1] as string, a[2])
				}
				else {}
			}
		}
		else {
			panic(error('query param `${a}` not support!'))
		}
	}
}

fn (a Arg) str() string {
	return match a {
		bool {
			if a {
				'1'
			} else {
				'0'
			}
		}
		int {
			a.str()
		}
		string {
			if a.len == 4 && a.to_upper() == 'NULL' {
				a
			} else {
				"'${a as string}'"
			}
		}
		[]string {
			mut items := []string{}
			for _, item in a {
				items << "'${item}'"
			}
			return '(${items.join(', ')})'
		}
		[]Arg {
			mut items := []string{}
			for _, arg in a {
				items << '${arg}'
			}
			return '(${items.join(', ')})'
		}
		[]i8 {
			convert_number_to_string(a)
		}
		[]i16 {
			convert_number_to_string(a)
		}
		[]i32 {
			convert_number_to_string(a)
		}
		[]int {
			convert_number_to_string(a)
		}
		[]i64 {
			convert_number_to_string(a)
		}
		[]u8 {
			convert_number_to_string(a)
		}
		[]u16 {
			convert_number_to_string(a)
		}
		[]u32 {
			convert_number_to_string(a)
		}
		[]u64 {
			convert_number_to_string(a)
		}
		[]f32 {
			convert_number_to_string(a)
		}
		[]f64 {
			convert_number_to_string(a)
		}
		Builder {
			return '(SELECT id FROM user)'
		}
		else {
			return typeof(a)
		}
	}
}
