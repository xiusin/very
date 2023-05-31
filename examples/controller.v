module main

import xiusin.very
import vweb
import xiusin.very.di

[group: '/app']
pub struct App {
	very.Context
}

['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

['/inject'; get]
pub fn (mut app App) app_inject(db string) ! {
	return error('hello world!')
}

['/none'; get]
pub fn (mut app App) app_none() {
	app.text('hello world!')
}

struct VApp {
	vweb.Context
}

pub fn (mut app VApp) hello_api() vweb.Result {
	return app.text('hello world')
}

fn main() {
	mut app := very.new(very.default_configuration())

	str := ''
	di.set('string', str)
	dump(di.get_voidptr('string')!)
	app.register_on_interrupt(fn () ! {
		println('exit one')
	})
	app.register_on_interrupt(fn () ! {
		println('exit two')
	})

	app.mount[App]()

	// spawn fn () {
	// 	vweb.run(&VApp{}, 8081)
	// }()
	app.run()
}
