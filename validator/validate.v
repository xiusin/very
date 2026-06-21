module validator

pub interface IValidator {
	field   FieldData
	message string
	value   string
	validate() !
}

const validators_ = new_validators()

fn default_validator() &Validators {
	return validators_
}

@[head]
pub struct Validators {
mut:
	validators map[string]IValidator
}

fn (mut v Validators) register(name string, iv IValidator) {
	v.validators[name] = iv
}

fn new_validators() &Validators {
	return &Validators{}
}

// register validator
pub fn register_validator(name string, v IValidator) {
	mut dv := default_validator()
	dv.register(name, v)
}

// validate data
pub fn validate[T](data &T) ?[]IError {
	mut errs := []IError{}

	$for field in T.fields {
		rule_attr := field.attrs.filter(it.contains('validate'))
		mut message_map := map[string]string{}
		if rule_attr.len > 0 {
			mut rules := rule_attr.first().trim_string_left('validate: ').trim("'").split(',')
			message_attrs := field.attrs.filter(it.contains('message'))
			if message_attrs.len > 0 {
				messages := message_attrs.first().trim_string_left('message: ').trim("'").split(',')
				for message in messages {
					key, value := message.trim_space().split_once('=')?
					message_map[key] = value
				}
			}

			for rule in rules {
				trimmed := rule.trim_space()
				mut validator_rule := trimmed
				mut pattern := ''
				if trimmed.contains('=') {
					validator_rule, pattern = trimmed.split_once('=') or { trimmed, '' }
				}
				match validator_rule {
					'min' {
						v := Min[T]{
							field:   field
							message: message_map[validator_rule]
							value:   pattern
							data:    unsafe { data }
						}
						v.validate() or { errs << err }
					}
					'max' {
						v := Max[T]{
							field:   field
							message: message_map[validator_rule]
							value:   pattern
							data:    unsafe { data }
						}
						v.validate() or { errs << err }
					}
					'required' {
						v := Required[T]{
							field:   field
							message: message_map[validator_rule]
							data:    unsafe { data }
						}
						v.validate() or { errs << err }
					}
					'regexp' {
						v := Regexp[T]{
							field:   field
							message: message_map[validator_rule]
							value:   pattern
							data:    unsafe { data }
						}
						v.validate() or { errs << err }
					}
					'number' {
						v := Number[T]{
							field:   field
							message: message_map[validator_rule]
							data:    unsafe { data }
						}
						v.validate() or { errs << err }
					}
					'url' {
						v := Url[T]{
							field:   field
							message: message_map[validator_rule]
							data:    unsafe { data }
						}
						v.validate() or { errs << err }
					}
					else {
						return [error('no validator ${validator_rule}')] // auto find
					}
				}
			}
		}
	}
	return errs
}
