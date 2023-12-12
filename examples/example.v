module main

import xiusin.very
import xiusin.very.di
import log
import rand

@[group: '/app']
pub struct App {
	very.Context
pub mut:
	logger_ log.Logger @[inject: 'logger']

	hello &string @[inject: 'string']

	xbn &string @[inject: 'string']
	//
	i_int &int @[inject: 'int']
}

@['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

@['/inject'; get]
pub fn (mut app App) app_inject() ! {
	dump(app.xbn);
	unsafe {
		*app.xbn = 'modity ${rand.intn(1000)}'
	}
	println(app.i_int)
	unsafe {
		*app.i_int = rand.intn(19999) or { 0 }
	}
	app.logger_.set_level(log.Level.debug)
	app.logger_.info('logger_ xxx')
}

@['/app_html'; get]
pub fn (mut app App) app_html() ! {
	message := 'hello app html'
	app.html($tmpl('example.html'))
}

@['/none'; get]
pub fn (mut app App) app_none() {
	app.text('<h1>Hello, World! _ none</h1>')
}

@['/'; get]
pub fn (mut app App) index() {
	app.html('<h1>Hello, World!</h1>')
}

fn main() {
	mut app := very.new(very.default_configuration())
	a := 'hello world'
	i := 100
	di.inject_on(&a, 'string')
	di.inject_on(&i, 'int')

	// app.use(middleware.compress, middleware.favicon(
	// 	data: $embed_file('favicon.ico', .zlib).to_bytes()
	// ))

	// /hello/ => hello,
	// /hello/xiusin => hello, xiusin
	app.get('/hello/*name', fn (mut ctx very.Context) ! {
		ctx.html('<h1>Hello, ${ctx.param('name')}!</h1>')
	})

	// app.use(middleware.logger, middleware.cors()) // use middleware
	// mut asset := byte_file_data()
	// app.embed_statics('/dist', mut asset)
	// app.statics("/", "dist", "index.html") or {}
	app.mount[App]() // mount controller
	app.run()
}
