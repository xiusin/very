module builder

pub fn (builder &Builder) or_where(param WhereParam, args ...Arg) &Builder {
	unsafe {
		return builder
	}
}

pub fn (builder &Builder) where(param WhereParam, args ...Arg) &Builder {
	unsafe {
		match param {
			QueryCallBack {
				param(mut builder)
			}
			map[string]Arg {
				for field, arg in param {
					builder.parse_where(field, arg)
				}
			}
			Arg {
				param.build_where(builder)
			}
			[]Arg {
				for _, arg in param {
					builder.where(arg)
				}
			}
			string {
				builder.parse_where(param, ...args)
			}
		}
		return builder
	}
}

fn (builder &Builder) where_raw() &Builder {
	unsafe {
		return builder
	}
}

fn (builder &Builder) parse_where(param string, args ...Arg) {
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
		builder.wheres << '${param} ${condition} ${arg}'
	}
}
