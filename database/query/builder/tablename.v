module builder

pub type TableNameCallBack = fn () string

pub type TableName = Builder | TableNameCallBack | string

pub fn (t TableName) to_string(alias ...string) string {
	mut name := match t {
		string { t }
		TableNameCallBack { t() }
		Builder { t.to_sql() }
	}

	name = name.trim(' \r\n\t')
	if name.starts_with('(') && name.ends_with(')') {
		name = name.trim('()')
	}

	if name.contains(' ') {
		alias_name := if alias.len > 0 {
			alias[0]
		} else if name.starts_with('(') && !name.ends_with(')') {
			return name
		} else {
			'__t'
		}
		return '(${name}) AS ${alias_name}'
	} else if alias.len > 0 {
		if name.trim('\r\n\t').contains(' ') {
			return '(${name}) AS ${alias[0]}'
		}
	}
	return name
}
