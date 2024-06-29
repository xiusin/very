module builder

pub fn (b &Builder) where(param WhereParam, args ...Arg) &Builder {
	unsafe {
		match param {
			QueryCallBack {
				param(mut b)
			}
			map[string]Arg {
				for field, arg in param {
					b.parse_where(field, arg)
				}
			}
			[]Arg {
				match param.len {
					1 { b.where(param[0]) }
					2 { b.where(param[0], param[1]) }
					3 { b.where(param[0], param[1], param[2]) }
					else {}
				}
			}
			string {
				b.parse_where(param, ...args)
			}
			else {}
		}
		return b
	}
}

fn (b &Builder) parse_where(param string, args ...Arg) {
	mut condition := '='
	mut arg := Arg('')
	match args.len {
		1 {
			arg = args[0]
		}
		2 {
			condition = args[0] as string
			arg = args[1]
		}
		else {}
	}

	unsafe {
		b.wheres << '${param} ${condition} ${arg}'
	}
}
