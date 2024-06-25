module validator

import regex

pub struct Number[T] {
pub mut:
	field   FieldData
	message string
	value   string
	data    &T
}

fn (m Number[T]) validate() ! {
	mut message := m.message
	if message.len == 0 {
		message = '${m.field.name} must be a number.'
	}
	mut re := regex.regex_opt('^[0-9]+$')!
	$for field in T.fields {
		$if field.typ is string {
			if field.name == m.field.name && !re.matches_string(m.data.$(field.name)) {
				return error(message)
			}
		}
	}
}
