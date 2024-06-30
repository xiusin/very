module builder

pub fn (b &Builder) or_where(param WhereParam, args ...Arg) &Builder {
	unsafe {
		return b
	}
}

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
			Arg {
				param.build_where(b)
			}
			[]Arg {
				for _, arg in param {
					b.where(arg)
				}
			}
			string {
				b.parse_where(param, ...args)
			}
		}
		return b
	}
}

fn (b &Builder) where_raw() &Builder {
	unsafe {
		return b
	}
}

fn (b &Builder) parse_where(param string, args ...Arg) {
	mut condition := '='
	mut arg := Arg('')
	match args.len {
		1 {
			arg = args[0]
			typename := arg.type_name()
			if typename.starts_with('[]') || typename.ends_with('builder.Builder') {
				condition = 'IN'
			}
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
