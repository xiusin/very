module validator

pub struct Max[T] {
pub mut:
	field   FieldData
	message string
	value   string
	data    &T
}

fn (m Max[T]) validate() ! {
	check_value := m.value.int()
	mut message := m.message
	if message.len == 0 {
		message = '${m.field.name} must be no greater than {max}.'
	}
	mut block := false
	$for field in T.fields {
		if field.name == m.field.name {
			$if field.typ is string {
				block = m.data.$(field.name).len > check_value
			} $else $if field.typ is int {
				block = m.data.$(field.name) > check_value
			} $else $if field.typ is i8 {
				block = m.data.$(field.name) > check_value
			} $else $if field.typ is i16 {
				block = m.data.$(field.name).i16() > check_value
			} $else $if field.typ is i32 {
				block = m.data.$(field.name).int() > check_value
			} $else $if field.typ is i64 {
				block = m.data.$(field.name).i64() > check_value
			} $else $if field.typ is u8 {
				block = m.data.$(field.name).u8() > check_value
			} $else $if field.typ is u16 {
				block = m.data.$(field.name).u16() > check_value
			} $else $if field.typ is u32 {
				block = m.data.$(field.name).u32() > check_value
			} $else $if field.typ is u64 {
				block = m.data.$(field.name).u64() > check_value
			} $else {
				return error('max no support ${field.name}:${field.typ}')
			}
		}
	}
	if block {
		return error(message.replace_once('{max}', '${m.value}'))
	}
}
