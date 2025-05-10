module builder

pub fn (b &Builder) where(param WhereParam, args ...Arg) &Builder {
	unsafe {
		match param {
			QueryCallBack {
				param(mut b)
			}
			map[string]Arg {
				if param.len > 0 {
					mut wheres := []string{}
					for field, arg in param {
						wheres << b.parse_where(field, arg)
					}
					b.wheres << '(${wheres.join(' AND ')})'
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
				b.wheres << b.parse_where(param, ...args)
			}
			else {}
		}
		return b
	}
}

fn (b &Builder) parse_where(param string, args ...Arg) string {
	mut condition := '='
	mut arg := Arg('')
	match args.len {
		1 {
			arg = '${args[0]}'
		}
		2 {
			condition = args[0] as string
			arg = '${args[1]}'
		}
		else {}
	}

	if '${arg}'.trim_space().starts_with('(') {
		condition = 'IN'
	}

	return '${param} ${condition} ${arg}'
}
