module main

import xiusin.very
import xiusin.very.middleware
import log
import rand

@[group: '/app']
pub struct App {
	very.Context
pub mut:
	logger_ log.Logger @[inject: 'logger']
	hello &string @[inject: 'string']
	xbn &string @[inject: 'string']
	i_int &int @[inject: 'int']
}

@['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

@['/inject'; get]
pub fn (mut app App) app_inject() ! {
	println('${app.xbn}')
	unsafe {
		*app.xbn = 'modity ${rand.intn(1000)}'
	}
	unsafe {
		*app.i_int = *app.i_int + 1
	}
	if *app.i_int == 101 {
		println('set log level')
		app.logger_.set_level(log.Level.debug)
	}
	app.logger_.debug('logger_ xxx ${*app.i_int} - ${ptr_str(app.logger_)} - ${ptr_str(app.i_int)}')
	app.text('app inject ${*app.i_int}')
}

@['/html'; get]
pub fn (mut app App) app_html() ! {
	message := 'hello app html'
	app.logger_.info('logger_ ${message}')
	app.html($tmpl('example.html'))
}

@['/'; get]
pub fn (mut app App) index() {
	app.html('<h1>Hello, World!</h1>')
}

fn main() {
	mut app := very.new()

	app.register_on_interrupt(fn()! {
		println('\nweb server closed!')
	})


	{
		a := 'hello world'
		i := 100
		app.inject_on(&a, 'string')
		app.inject_on(&i, 'int')
	}

	// /hello/ => hello,
	// /hello/xiusin => hello, xiusin
	app.get('/hello/*name', fn (mut ctx very.Context) ! {
		ctx.html('<h1>Hello, ${ctx.param('name')}!</h1>')
	})

// , middleware.favicon(
// 		data: $embed_file('favicon.ico', .zlib).to_bytes()
// 	)
	app.use(middleware.compress, middleware.logger, middleware.cors()) // use middleware
	// mut asset := byte_file_data()
	// app.embed_statics('/dist', mut asset)
	// app.statics("/", "dist", "index.html") or {}
	app.mount[App]()
	app.run()
}
