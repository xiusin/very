# very #

Express inspired web framework written in V with `net.http.server` module.

>  [Experimental]


## example:

``` v
module main

import xiusin.very
import sqlite
import entities

struct Contrller {
mut:
	userid int
	ctx &very.Context
}

pub fn (mut c Contrller) success() {
	if c.userid > 0 {
		c.ctx.text("success: exists")
	} else {
		c.userid = 1
		c.ctx.text("success set user_id = ${c.userid}")
	}
}
pub fn (mut c Contrller) success1() {
	if c.userid > 0 {
		c.ctx.text("success1: exists")
	} else {
		c.userid = 2
		c.ctx.text("success1 set user_id = ${c.userid}")
	}
}
fn main() {
	mut app := very.new_app(very.default_configuration())

	mut db := sqlite.connect('database.db') or { panic(err) }
	db.synchronization_mode(sqlite.SyncMode.off)
	db.journal_mode(sqlite.JournalMode.memory)

	sql db {
		create table entities.User
	}

	app.use_db(mut db)
	// app.use_inner_db(mut db)
	app.use(fn(mut ctx very.Context) {
		ctx.next()
	})

	app.use(fn (mut ctx very.Context) {
		mut token := ctx.header(.authorization)
		token = token.after('Bearer ')
		ctx.next()
	})

	app.use(fn (mut ctx very.Context) {
		ctx.set("user_id", 1)
		ctx.next()
	})

	app.get("/hello/:name", fn(mut ctx very.Context) {
		user := entities.User{
			username: "xiusin"
			password: "123456"
			active: true
		}

		mut db := ctx.db as sqlite.DB
		sql db {
			insert user into entities.User
		}

		user_id := ctx.value("user_id") as int
		ctx.json("hello ${ctx.param('name')} ${user_id} ip ${ctx.client_ip()}")
	})

	mut router := app.group("/:version")

	router.get("/user", fn(mut ctx very.Context) {
		ctx.text("${ctx.path()} -- ${ctx.param('version')}")
	})

	app.statics("/statics", ".")

	app.controller(mut Controller{})

	app.run()
}
```
