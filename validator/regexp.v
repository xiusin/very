module validator

import regex

pub struct Regexp[T] {
pub mut:
	field   FieldData
	message string
	value   string
	data    &T
}

fn (m Regexp[T]) validate() ! {
	mut message := m.message
	if message.len == 0 {
		message = '${m.field.name} is invalid.'
	}
	mut re := regex.regex_opt(m.value)!
	$for field in T.fields {
		$if field.typ is string {
			if field.name == m.field.name && !re.matches_string(m.data.$(field.name)) {
				return error(message)
			}
		}
	}
}
