module main

import xiusin.very

[group: '/app']
pub struct App {
	very.Context // 自动注入
}

['/index'; get]
pub fn (mut app App) app_index() !&very.Response {
	println('app index')
	err := error('hello world!')
	dump(err)
	return err
}

fn main() {
	mut app := very.new(very.default_configuration())
	app.mount[App]()
	app.run()
}
