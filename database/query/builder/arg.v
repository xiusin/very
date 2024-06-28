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
	| f32
	| f64
	| int
	| map[string]Arg
	| string
	| u32
	| u64

fn (a Arg) str() string {
	return match a {
		bool {
			if a {
				'1'
			} else {
				'0'
			}
		}
		int, u32, u64, f32, f64 {
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
		[]i8, []int, []i16, []i32, []i64, []u8, []u16, []u32, []u64, []f32, []f64 {
			mut items := []string{}
			for _, item in a {
				items << '${item}'
			}
			return items.join(', ')
		}
		else {
			return '${''}'
		}
	}
}
