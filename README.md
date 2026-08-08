# very [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/xiusin/very)

Express inspired web framework written in V with `net.http.server` module. 

>  [Experimental]

## Features

- **Spring-like DI Container** — singleton / prototype / request scopes, interface binding, factory registration, lazy initialization
- **Event Bus** — decoupled event-driven architecture with built-in server lifecycle events
- **Session Store** — pluggable session storage with in-memory default
- **Middleware** — composable request pipeline (compress, cors, etc.)
- **Controller Mount** — struct-based controllers with field injection via `@[inject: 'name']`
- **Validation** — struct tag based validation (required, min, max, number, regexp, url)
- **Static Files** — directory serving and embedded assets

## Quick Start

```vlang
module main

import xiusin.very
import xiusin.very.middleware
import log

@[group: '/app']
pub struct App {
	very.Context
pub mut:
	logger_ log.Logger @[inject: 'logger'] // field injection
}

@['/'; get]
pub fn (mut app App) index() ! {
	app.text('Hello, World!')!
}

fn main() {
	mut app := very.new()

	// Register services in the DI container
	app.register_singleton[log.Logger](&log.Log{})

	// Listen for server lifecycle events
	app.on('ServerStart', fn (e very.event.Event) ! {
		println('Server started!')
	})

	app.use(middleware.compress, middleware.cors())
	app.mount[App]()
	app.run()
}
```

## Dependency Injection

The DI container supports three bean scopes and multiple registration styles:

### Singleton (default)

A single instance shared across the entire application:

```vlang
app.register_singleton[Database](my_db)
// or with a custom name:
app.register_singleton[Database](my_db, 'primary_db')
```

### Factory

Create instances via a factory function. Use `.prototype` scope to get a new instance each time:

```vlang
app.register_factory[Connection](fn () &Connection {
	return &Connection{ host: 'localhost' }
}, scope: .prototype)
```

### Lazy

The factory is called only on first `get`:

```vlang
app.register_lazy[ExpensiveService](fn () &ExpensiveService {
	// heavy initialization runs only when first requested
	return &ExpensiveService{ data: load_data() }
})
```

### Interface Binding

Bind an interface to a concrete implementation:

```vlang
interface Repository {
	find(id int) ?Entity
}

struct UserRepo {
	repo_db &Database [inject: 'db']
}

// Register the concrete type, then bind it to the interface name
app.register_singleton[UserRepo](&UserRepo{})
app.bind_instance[Repository](&UserRepo{}, 'repository')
```

### Retrieving Beans

```vlang
// In a handler:
db := ctx.di[Database]('db')!

// In a controller (via field injection):
@[inject: 'db']
db &Database = unsafe { nil }
```

### Request Scope

Enable per-request child containers so request-scoped beans are isolated:

```vlang
cfg := very.Configuration{
	enable_request_scope: true
}
mut app := very.new(cfg)
```

## Event System

The event bus provides decoupled communication between components:

```vlang
// Register a listener
app.on('ServerStart', fn (e very.event.Event) ! {
	println('Server is starting on port ${e.port}')
})

// Emit a custom event
app.emit(MyEvent{ message: 'hello' })!

// Remove all listeners for an event
app.off('ServerStart')
```

### Built-in Events

| Event | Triggered When |
|-------|---------------|
| `ServerStartEvent` | `app.run()` starts the server |
| `ServerShutdownEvent` | Graceful shutdown completes |
| `RequestStartEvent` | Each incoming request begins |
| `RequestEndEvent` | Each request finishes (includes duration) |

## Session Management

The default in-memory session store works out of the box. For custom backends (Redis, DB, etc.), implement the `SessionStore` interface:

```vlang
app.set_session_store(my_redis_store)
```

## Configuration

```vlang
cfg := very.Configuration{
	port: 8080
	app_name: 'MyApp'
	enable_request_scope: true
	max_request: 10000
	logger_level: .debug
}
mut app := very.new(cfg)
```

## Full Example

```vlang
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
	hello   &string    @[inject: 'string']
	i_int   &int       @[inject: 'int']
}

@['/inject'; get]
pub fn (mut app App) app_inject() ! {
	unsafe { *app.i_int = *app.i_int + 1 }
	app.logger_.info('request #${*app.i_int}')
	app.text('app inject ${*app.i_int}')!
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

	{
		a := 'hello world'
		i := 100
		app.inject_on(&a, 'string')
		app.inject_on(&i, 'int')
	}

	app.on('ServerStart', fn (e very.event.Event) ! {
		println('Server started!')
	})

	app.get('/hello/*name', fn (mut ctx very.Context) ! {
		ctx.html('<h1>Hello, ${ctx.param('name')}!</h1>')
	})

	app.use(middleware.compress, middleware.cors())
	app.mount[App]()
	app.run()
}
```
