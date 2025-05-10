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
			a
		}
		[]string {
			mut items := []string{}
			for _, item in a {
				items << "'${item}'"
			}
			return items.join(', ')
		}
		[]Arg {
			mut items := []string{}
			for _, arg in a {
				items << '${arg}'
			}
			return items.join(', ')
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
			return '(${a.to_sql()})'
		}
		else {
			typename := typeof(a)
			dump(typename)
			// if typename.starts_with('map') {
			// 	return json.encode(a)
			// }
			return typename
		}
	}
}
