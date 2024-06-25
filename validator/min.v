module validator

pub struct Min[T] {
pub mut:
	field   FieldData
	message string
	value   string
	data    &T
}

fn (m Min[T]) validate() ! {
	check_value := m.value.f64()
	mut message := m.message
	if message.len == 0 {
		message = '${m.field.name} must be no less than {min}.'
	}
	mut block := false
	$for field in T.fields {
		if field.name == m.field.name {
			$if field.typ is string {
				block = m.data.$(field.name).len < check_value
			} $else $if field.typ is int {
				block = m.data.$(field.name) < check_value
			} $else $if field.typ is i8 {
				block = m.data.$(field.name) < check_value
			} $else $if field.typ is i16 {
				block = m.data.$(field.name).i16() < check_value
			} $else $if field.typ is i32 {
				block = m.data.$(field.name).int() < check_value
			} $else $if field.typ is i64 {
				block = m.data.$(field.name).i64() < check_value
			} $else $if field.typ is u8 {
				block = m.data.$(field.name).u8() < check_value
			} $else $if field.typ is u16 {
				block = m.data.$(field.name).u16() < check_value
			} $else $if field.typ is u32 {
				block = m.data.$(field.name).u32() < check_value
			} $else $if field.typ is u64 {
				block = m.data.$(field.name).u64() < check_value
			} $else {
				return error('min no support ${field.typ}')
			}
		}
	}
	if block {
		return error(message.replace_once('{min}', '${m.value}'))
	}
}
