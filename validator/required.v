module validator

pub struct Required[T] {
pub mut:
	field   FieldData
	message string
	value   string
	data    &T
}

fn (m Required[T]) validate() ! {
	mut message := m.message
	if message.len == 0 {
		message = '${m.field.name} cannot be blank.'
	}

	$for field in T.fields {
		$if field.typ is string {
			if field.name == m.field.name {
				if m.data.$(field.name).len == 0 {
					return error(message)
				}
			}
		}
	}
}
