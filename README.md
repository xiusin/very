# very #

Express inspired web framework written in V with `net.http.server` module.

>  [Experimental]

## example:

```vlang
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

[group: '/demo']
struct DemoController {
    very.Context
pub mut:
	userid int
	db     &sqlite.DB  [inject: 'db'] = unsafe { nil }
}

['/success'; get]
pub fn (mut c DemoController) success() ! {
	if c.userid > 0 {
		c.ctx.text('success: exists')
	} else {
		c.userid = 1
		c.ctx.text('success set user_id = ${c.userid}')
	}
}

['/success1'; get]
pub fn (mut c DemoController) success1() ! {
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

	mut counter := 0

	api.get('/hello', fn [mut counter] (mut ctx very.Context) ! {
		ctx.text('hello world: ${counter}')
	})

	api.get('/article/list', fn (mut ctx very.Context) ! {
		mut db := ctx.di.get[sqlite.DB]('db')!
		result := sql db {
			select from Article
		}!
		ctx.json(ApiResponse[[]Article]{
			code: 0
			data: []Article{}
		})
	})

	api.post('/article/save', fn (mut ctx very.Context) ! {
		ctx.text(ctx.host())
	})

	app.controller[Contrller]()
	app.statics('/', 'statics', 'index.html')
	app.run()
}


V panic: `go net__http__Server_parse_and_respond()`: Resource temporarily unavailable
v hash: bc88183
0   controller                          0x000000010d94184d panic_error_number + 77
1   controller                          0x000000010d9c07a8 net__http__Server_listen_and_serve + 1336
2   controller                          0x000000010d9c9827 xiusin__very__Application_run + 871
3   controller                          0x000000010d9cd02a main__main + 346
4   controller                          0x000000010da9fb7c main + 76
5   controller                          0x000000010d876084 start + 52
6   ???                                 0x0000000000000001 0x0 + 1
```
