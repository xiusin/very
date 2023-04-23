module main

import xiusin.very
import xiusin.very.di
import db.sqlite

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

struct DemoController {
pub mut:
	userid  int
	ctx     &very.Context = unsafe { nil }
	counter &int          [inject: 'counter'] = unsafe { 0 }
}

['/demo/success'; get]
pub fn (mut c DemoController) success() {
	if c.userid > 0 {
		c.ctx.text('success: exists')
	} else {
		c.userid = 1
		c.ctx.text('success set user_id = ${c.userid}')
	}
}

['/demo/success1'; get]
pub fn (mut c DemoController) success1() {
	if c.userid > 0 {
		c.ctx.text('success1: exists')
	} else {
		c.userid = 2
		c.ctx.text('success1 set user_id = ${c.userid}')
	}
}

fn main() {
	mut app := very.new(very.default_configuration())
	mut db := sqlite.connect('database.db') or { panic(err) }
	mut counter := 0
	db.synchronization_mode(sqlite.SyncMode.off)
	db.journal_mode(sqlite.JournalMode.memory)
	app.di.set(di.Service{
		name: 'counter'
		instance: &counter
	})
	app.di.set(di.Service{
		name: 'db'
		instance: &db
	})

	sql db {
		create table Article
	}!

	mut api := app.group('/api')

	api.get('/hello', fn (mut ctx very.Context) ! {
		// mut counter := int()
		// println(unsafe { &int(app.di.get('counter')!) })

		// counter = counter + 1
		ctx.text('hello world')
	})

	api.get('/article/list', fn (mut ctx very.Context) ! {
		mut db := ctx.di.get[sqlite.DB]('db')!
		result := sql db {
			select from Article
		}!
		ctx.json(ApiResponse[[]Article]{
			code: 0
			data: result
		})
	})

	api.post('/article/save', fn (mut ctx very.Context) ! {
		ctx.text(ctx.host())
	})

	app.mount(mut DemoController{})
	app.statics('/', 'statics', 'index.html')
	app.run()
}
