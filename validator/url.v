module validator

import net.urllib

pub struct Url[T] {
pub mut:
	field   FieldData
	message string
	value   string
	data    &T
}

fn (m Url[T]) validate() ! {
	mut message := m.message
	if message.len == 0 {
		message = '${m.field.name} is not a valid URL.'
	}
	$for field in T.fields {
		$if field.typ is string {
			if field.name == m.field.name {
				urllib.parse(m.data.$(field.name)) or {
					$if debug {
						eprintln(err)
					}
					return error(message)
				}
			}
		}
	}
}
