module main

import xiusin.very
import xiusin.very.di
import xiusin.very.middleware
import log

[group: '/app']
pub struct App {
	very.Context
pub mut:
	logger_ log.Logger [inject: 'logger']

	hello &string [inject: 'string']
	// no_inject &string [inject: '_string']
	xbn &string [inject: 'string']
	//
	i_int &int [inject: 'int']
}

['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

['/inject'; get]
pub fn (mut app App) app_inject() ! {
	println(app.xbn)
	println(app.hello)
	println(app.i_int)
	unsafe { app.i_int++ }
	app.logger.debug('xxx')
	app.logger_.debug('xxx')
	// return error('${ptr_str(app.hello)} - ${ptr_str(app.xbn)} - ${ptr_str(app.i_int)} - ${app.i_int}')
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

fn main() {
	mut app := very.new(very.default_configuration())
	a := 'hello world'
	i := 100
	di.inject_on(&a, 'string')
	di.inject_on(&i, 'int')

	app.use(middleware.compress, middleware.favicon(
		data: $embed_file('favicon.ico', .zlib).to_bytes()
	))

	// app.use(middleware.logger, middleware.cors()) // use middleware

	mut asset := byte_file_data()
	app.embed_statics('/dist', mut asset)

	app.mount[App]() // mount controller
	app.run()
}
