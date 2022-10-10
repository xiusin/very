module main

import xiusin.veb

fn main() {
	mut app := veb.new_app(veb.default_configuration())

	app.use(fn(mut ctx veb.Context) {
		ctx.next()
	})

	app.use(fn (mut ctx veb.Context) {
		mut token := ctx.header(.authorization)
		token = token.after('Bearer ')
		ctx.next()
	})

	app.use(fn (mut ctx veb.Context) {
		ctx.set("user_id", 1)
		ctx.next()
	})

	app.get("/hello/:name", fn(mut ctx veb.Context) {
		user_id := ctx.value("user_id") as int
		ctx.json("hello ${ctx.param('name')} ${user_id} ip ${ctx.ip()}")
	})

	mut router := app.group("/:version")

	router.get("/user", fn(mut ctx veb.Context) {
		ctx.text("${ctx.path()} -- ${ctx.param('version')}")
	})

	app.statics("/statics", ".")

	app.run()
}

