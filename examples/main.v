module main

import xiusin.very

[group: '/app']
pub struct App {
	very.Context // 自动注入
}

['/index'; get]
pub fn (mut app App) app_index() ! {
	return error('hello world!')
}

['/none'; get]
pub fn (mut app App) app_none() {
	println('none action')
	app.text('none action')
}

fn main() {
	mut app := very.new(very.default_configuration())
	app.mount[App]()
	app.run()
}
