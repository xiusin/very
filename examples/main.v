module main

import xiusin.very
import sqlite
import entities

pub struct ApiResponse<T> {
	code int
	msg  string
	data T
}

fn main() {
	mut app := very.new(very.default_configuration())
	mut db := sqlite.connect('database.db') or { panic(err) }
	db.synchronization_mode(sqlite.SyncMode.off)
	db.journal_mode(sqlite.JournalMode.memory)
	app.use_db(mut db)

	sql db {
		create table entities.Article
	}

	mut api := app.group("/api")
	api.get("/article/list", fn (mut ctx very.Context) {
		mut db := ctx.db as sqlite.DB
		result := sql db {
			select from entities.Article
		} or {
			[]entities.Article{}
		}

		ctx.json(ApiResponse <[]entities.Article> {
			code: 0
			data: result
		})
	})

	api.post("/article/save", fn(mut ctx very.Context) {
		ctx.text(ctx.host())
	})

	app.statics("/", "statics", "index.html")

	app.run()
}

