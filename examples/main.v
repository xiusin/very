module main

import xiusin.very
import xiusin.very.di
import db.sqlite

// 必须得定义在这?
[table: 'users']
pub struct User {
pub mut:
	id         int    [primary; sql: serial]
	username   string [required; sql_type: 'TEXT']
	password   string [required; sql_type: 'TEXT']
	created_at string [default: 'CURRENT_TIMESTAMP']
	updated_at string [default: 'CURRENT_TIMESTAMP']
	active     bool
}

[table: 'articles']
pub struct Article {
pub mut:
	id      int    [primary; sql: serial]
	title   string
	content string
	time    string
	tags    string
	star    bool
}

pub struct ApiResponse[T] {
	code int
	msg  string
	data T
}

fn main() {
	mut app := very.new(very.default_configuration())

	mut db := sqlite.connect('database.db') or { panic(err) }
	db.synchronization_mode(sqlite.SyncMode.off)
	db.journal_mode(sqlite.JournalMode.memory)
	app.di.set(di.Service{
		name: 'db'
		instance: &db
	})

	sql db {
		create table Article
	}

	mut api := app.group('/api')
	api.get('/article/list', fn (mut ctx very.Context) ! {
		mut db := ctx.di.get[sqlite.DB]('db')!
		dump(db)
		// result := sql db {
		// 	select from Article
		// } or { []Article{} }

		ctx.json(ApiResponse[[]Article]{
			code: 0
			data: []Article{}
		})
	})

	api.post('/article/save', fn (mut ctx very.Context) ! {
		ctx.text(ctx.host())
	})

	app.statics('/', 'statics', 'index.html')

	app.run()
}
