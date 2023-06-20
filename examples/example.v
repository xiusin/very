module main

import xiusin.very
import vweb
import xiusin.very.di

[group: '/app']
pub struct App {
	very.Context
pub mut:
	hello &string [inject: 'string']
	// no_inject &string [inject: '_string']
	xbn int [inject: 'string']
}

['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

['/inject'; get]
pub fn (mut app App) app_inject() ! {
	return error('${ptr_str(app.hello)} - ${ptr_str(app.xbn)} - ${app.xbn}')
}

['/app_html'; get]
pub fn (mut app App) app_html() ! {
	message := 'hello app html'
	app.html($tmpl('example.html'))
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
	a := 'hello world'
	i := 100
	di.set('string', &a)
	di.set('int', &i)
	app.mount[App]()
	app.run()
}
