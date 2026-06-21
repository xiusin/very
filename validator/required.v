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
		if field.name == m.field.name {
			$if field.typ is string {
				if m.data.$(field.name).len == 0 {
					return error(message)
				}
			} $else $if field.typ is int {
				if m.data.$(field.name) == 0 {
					return error(message)
				}
			} $else $if field.typ is i64 {
				if m.data.$(field.name) == 0 {
					return error(message)
				}
			} $else $if field.typ is u64 {
				if m.data.$(field.name) == 0 {
					return error(message)
				}
			} $else $if field.typ is f64 {
				if m.data.$(field.name) == 0.0 {
					return error(message)
				}
			} $else $if field.typ is bool {
				// bool is always valid for required
			}
		}
	}
}
