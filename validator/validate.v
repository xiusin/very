module validator

pub interface IValidator {
	field   FieldData
	message string
	value   string
	validate() !
}

const validators_ = new_validators()

fn default_validator() &Validators {
	return validator.validators_
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
	mut validators := []IValidator{}

	$for field in T.fields {
		rule_attr := field.attrs.filter(it.contains('validate'))
		mut message_map := map[string]string{}
		if rule_attr.len > 0 {
			mut rules := rule_attr.first().trim_string_left('validate: ').split(',')
			message_attrs := field.attrs.filter(it.contains('message'))
			if message_attrs.len > 0 {
				messages := message_attrs.first().trim_string_left('message: ').split(',')
				for message in messages {
					key, value := message.trim_space().split_once('=')?
					message_map[key] = value
				}
			}

			for mut rule in rules {
				rule = rule.trim_space()
				mut validator_rule := rule
				mut pattern := ''
				if rule.contains('=') {
					validator_rule, pattern = rule.split_once('=') or { rule, '' }
				}
				match validator_rule {
					'min' {
						validators << IValidator(&Min[T]{
							field: field
							message: message_map[validator_rule]
							value: pattern
							data: unsafe { data }
						})
					}
					'max' {
						validators << IValidator(&Max[T]{
							field: field
							message: message_map[validator_rule]
							value: pattern
							data: unsafe { data }
						})
					}
					'required' {
						validators << IValidator(&Required[T]{
							field: field
							message: message_map[validator_rule]
							data: unsafe { data }
						})
					}
					'regexp' {
						validators << IValidator(&Regexp[T]{
							field: field
							message: message_map[validator_rule]
							value: pattern
							data: unsafe { data }
						})
					}
					'number' {
						validators << IValidator(&Number[T]{
							field: field
							message: message_map[validator_rule]
							data: unsafe { data }
						})
					}
					'url' {
						validators << IValidator(&Url[T]{
							field: field
							message: message_map[validator_rule]
							data: unsafe { data }
						})
					}
					else {
						return [error('no validator ${validator_rule}')] // auto find
					}
				}
			}
		}
	}
	for mut validator in validators {
		validator.validate() or { errs << err }
	}

	return errs
}
