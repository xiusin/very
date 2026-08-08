module main

import xiusin.very
import xiusin.very.middleware
import xiusin.very.event
import log
import rand

@[group: '/app']
pub struct App {
	very.Context
pub mut:
	logger_ log.Logger @[inject: 'logger']
	hello   &string    @[inject: 'string']
	xbn     &string    @[inject: 'string']
	i_int   &int       @[inject: 'int']
}

@['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

@['/inject'; get]
pub fn (mut app App) app_inject() ! {
	unsafe {
		*app.xbn = 'modity ${rand.intn(1000) or { 0 }}'
	}
	unsafe {
		*app.i_int = *app.i_int + 1
	}
	println('${ptr_str(app.logger_)}')
	app.logger_.set_level(log.Level.debug)
	app.logger_.info('logger_ xxx ${*app.i_int} - ${ptr_str(app.logger_)} - ${ptr_str(app.i_int)}')
	app.text('app inject ${*app.i_int}')!
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

	app.register_on_interrupt(fn () ! {
		println('\nweb server closed!')
	})

	// Register singleton services in the DI container
	{
		a := 'hello world'
		i := 100
		app.inject_on(&a, 'string')
		app.inject_on(&i, 'int')
	}

	// Event listeners for server lifecycle
	app.on('ServerStart', fn (e event.Event) ! {
		println('Server started!')
	})
	app.on('RequestStart', fn (e event.Event) ! {
		println('Incoming request')
	})

	// /hello/ => hello,
	// /hello/xiusin => hello, xiusin
	app.get('/hello/*name', fn (mut ctx very.Context) ! {
		ctx.html('<h1>Hello, ${ctx.param('name')}!</h1>')
	})

	app.use(middleware.compress, middleware.cors())
	app.mount[App]()
	app.run()
}
