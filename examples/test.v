module main

import log

struct Test {
	pub mut:
	logger_ log.Logger
}

fn main() {
	mut logger := &log.Log{}
	mut services := map[string]voidptr{}
	services["logger"] =  logger

	mut t := Test{}
	
	$for field in Test.fields {
		$if field.name == 'logger_' {
			println('setting...')
			mut field_ptr := &voidptr(&t.$(field.name))
			unsafe { *field_ptr = services["logger"]  }
			_ = field_ptr
		}
	}
	t.logger_.set_level(log.Level.debug)
	t.logger_.debug('ok!')
}