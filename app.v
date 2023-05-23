module very

import net.http { Request, Response, ResponseConfig, Server, new_response }
import net.urllib
import log
import os
import vweb
import very.di
import orm
import xiusin.vcolor
import time
import context

type Handler = fn (mut ctx Context) !

const check_implement_err = error('Must pass in a structure that implements `AbstractController`')

const version = 'v0.0.1 dev'

pub interface AbstractController {
	ctx &Context
}

pub interface Injectable {
	get_di() &di.Builder
	set_di(mut builder di.Builder)
}

struct GroupRouter {
mut:
	trier  &Trier
	mws    []Handler
	prefix string
pub mut:
	di &di.Builder = unsafe { &di.Builder{} }
}

fn (mut app GroupRouter) get_di() &di.Builder {
	return app.di
}

fn (mut app GroupRouter) set_di(mut builder di.Builder) {
	app.di = unsafe { builder }
}

[heap]
pub struct Application {
	Server
	GroupRouter
mut:
	cfg        Configuration
	quit_ch    chan os.Signal
	interrupts []fn () !
pub mut:
	global_mws        []Handler
	logger            log.Log
	recover_handler   Handler
	not_found_handler Handler
	db                orm.Connection
}

// new 获取一个Application实例
pub fn new(cfg Configuration) Application {
	mut app := Application{
		Server: Server{}
		cfg: cfg
		db: unsafe { nil }
		di: &di.Builder{}
		trier: new_trie()
		logger: log.Log{
			level: .debug
		}
		recover_handler: fn (mut ctx Context) ! {
			ctx.set_status(.internal_server_error)
			ctx.text('has err: ${ctx.err}')
		}
		not_found_handler: fn (mut ctx Context) ! {
			ctx.resp = Response{
				body: 'the router ${ctx.req.url} not found'
			}
			ctx.resp.set_status(.not_found)
		}
	}

	app.Server.port = app.cfg.get_port()
	return app
}

// use_db 注册数据库连接对象
[inline]
pub fn (mut app Application) use_db(mut db orm.Connection) {
	app.db = db
}

// global_use 注册全局中间件: 在每个请求都会触发
[inline]
pub fn (mut app Application) global_use(mws ...Handler) {
	app.global_mws << mws
}

// 注册中间件: 匹配到路由时才会执行
[inline]
pub fn (mut app GroupRouter) use(mws ...Handler) {
	app.mws << mws
}

// 注册get路由
pub fn (mut app GroupRouter) get(path string, handle Handler, mws ...Handler) {
	app.trier.add('GET;' + app.get_with_prefix(path), handle, mws)
	app.options(path, handle, ...mws)
}

pub fn (mut app GroupRouter) post(path string, handle Handler, mws ...Handler) {
	app.trier.add('POST;' + app.get_with_prefix(path), handle, mws)
	app.options(path, handle, ...mws)
}

pub fn (mut app GroupRouter) options(path string, handle Handler, mws ...Handler) {
	app.trier.add('OPTIONS;' + app.get_with_prefix(path), handle, mws)
}

pub fn (mut app GroupRouter) put(path string, handle Handler, mws ...Handler) {
	fk := 'PUT;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.options(path, handle, ...mws)
}

[inline]
pub fn (mut app GroupRouter) delete(path string, handle Handler, mws ...Handler) {
	app.trier.add('DELETE;' + app.get_with_prefix(path), handle, mws)
	app.options(path, handle, ...mws)
}

[inline]
pub fn (mut app GroupRouter) head(path string, handle Handler, mws ...Handler) {
	app.trier.add('HEAD;' + app.get_with_prefix(path), handle, mws)
	app.options(path, handle, ...mws)
}

// add 添加一个路由
[inline]
pub fn (mut app GroupRouter) add(method http.Method, path string, handle Handler, mws ...Handler) {
	app.trier.add(method.str() + ';' + app.get_with_prefix(path), handle, mws)
}

// all 注册所有请求方法
pub fn (mut app GroupRouter) all(path string, handle Handler, mws ...Handler) {
	app.add(.get, path, handle, ...mws)
	app.add(.post, path, handle, ...mws)
	app.add(.delete, path, handle, ...mws)
	app.add(.put, path, handle, ...mws)
	app.add(.options, path, handle, ...mws)
}

// get_with_prefix 获取带前缀的路由path
fn (mut app GroupRouter) get_with_prefix(key string) string {
	if key.starts_with('/') {
		if key == '/' {
			return '${app.prefix}*filepath'
		} else {
			return '${app.prefix}${key}'
		}
	} else {
		return '${app.prefix}/${key}'
	}
}

// group Get a group router
pub fn (mut app GroupRouter) group(prefix string, mws ...Handler) &GroupRouter {
	mut group := &GroupRouter{
		trier: app.trier
		mws: mws
		di: app.get_di()
		prefix: app.get_with_prefix(prefix)
	}
	return group
}

fn (mut app GroupRouter) register_file(dir string, prefix string, index_file string) {
	cfn := fn (dir string, index_file string) fn (mut ctx Context) !Response {
		return fn [dir, index_file] (mut ctx Context) ! {
			mut filepath := ctx.param('filepath')
			if index_file.len > 0 && filepath.len == 0 {
				filepath = index_file
			}
			file := os.join_path(dir.trim('/'), filepath)
			data := os.read_file(file)!
			ext := os.file_ext(file)
			if ext in vweb.mime_types {
				ctx.resp.header.add(.content_type, vweb.mime_types[ext])
			}
			ctx.resp.body = data
		}
	}

	// 待优化
	files := os.ls(dir) or { return }
	app.all('${prefix}/*filepath', cfn(dir, index_file))
	for file in files {
		f_dir := os.join_path(dir, file)
		if os.is_dir(f_dir) {
			app.register_file(f_dir, '${prefix}/${file}', index_file)
			app.all('${prefix}/${file}/*filepath', cfn(f_dir, index_file))
		}
	}
}

pub fn (mut app GroupRouter) statics(prefix string, dir string, index_file ...string) {
	default_index_file := if index_file.len > 0 {
		index_file[0]
	} else {
		''
	}
	app.register_file(dir, if prefix == '/' { '' } else { prefix }, default_index_file)
}

pub fn (mut app GroupRouter) parse_group_attr[T]() string {
	mut group_route := ''
	$for f in T.attributes {
		if f.name == 'group' && f.has_arg && f.arg.len > 0 {
			if !f.arg.starts_with('/') {
				panic(error('must'))
			}
			group_route = f.arg
		}
	}
	return group_route
}

fn (mut app GroupRouter) is_controller[T]() bool {
	mut is_controller := false
	$for field in T.fields {
		$if field.name == 'Context' {
			is_controller = true
		}
	}
	return is_controller
}

fn (mut app GroupRouter) get_injected_fields[T]() map[string]voidptr {
	mut di_flag := 'inject: '
	mut injected_fields := map[string]voidptr{}
	$for field in T.fields {
		services := field.attrs.filter(it.contains(di_flag)).map(it.replace(di_flag, ''))
		if services.len == 1 {
			injected_fields[field.name] = app.di.get_voidptr(services[0]) or { panic(err) }
		}
	}
	return injected_fields
}

pub fn (mut app GroupRouter) mount[T]() {
	// if app.is_controller[T]() {
	// 	panic(very.check_implement_err)
	// }

	injected_fields := app.get_injected_fields[T]()
	route_prefix := app.parse_group_attr[T]()

	mut router := if route_prefix.len > 0 {
		app.group(route_prefix)
	} else {
		app
	}

	$for method_ in T.methods {
		if method_.attrs.len > 0 {
			mut http_methods, route_path := parse_attrs(method_.name, method_.attrs) or {
				panic(err)
			}
			if !http_methods.contains(http.Method.options) {
				http_methods << http.Method.options
			}
			method := method_
			for _, ano_method in http_methods {
				router.add(ano_method, route_path, fn [method, injected_fields] [T](mut ctx Context) !Response {
					mut ctrl := T{}
					ctrl.Context = ctx

					$for method__ in T.methods {
						if method__.name == method.name {
							$for field in T.fields {
								$if field.typ !is Context {
									if field.name in injected_fields {
										ctrl.$(field.name) = unsafe { injected_fields[field.name] }
									}
								}
							}
							$if method__.is_pub && method__.return_type is Response {
								return error(ctrl.$method())
							}
						}
					}
					return error('no handler')
				})
			}
		}
	}
}

// handle 请求处理
fn (mut app Application) handle(req Request) Response {
	mut url := urllib.parse(req.url) or { return Response{
		body: '${err}'
	} }
	mut background := context.background()
	mut ctx, cancel := context.with_timeout(mut &background, time.second * 4)

	url.host = req.header.get(.host) or { '' }
	key := req.method.str() + ';' + url.path
	mut req_ctx := Context{
		req: req
		ctx: ctx
		url: url
		resp: new_response(ResponseConfig{})
		di: app.get_di()
		db: app.db
		query: http.parse_form(url.raw_query)
		finished: chan int{}
		params: map[string]string{}
	}

	defer {
		req_ctx.finished.close()
		cancel()
	}

	if app.cfg.server_name.len > 0 {
		req_ctx.resp.header.set(.server, app.cfg.server_name)
	}
	req_ctx.resp.header.set(.connection, 'close')

	// spawn fn [mut app, mut req_ctx, key] () {
	// 	defer {
	// 		req_ctx.finished <- 0
	// 	}
	//
	//
	// }()
	//
	node, params, ok := app.trier.find(key)
	req_ctx.params = params.clone()
	if !ok {
		app.not_found_handler(mut req_ctx) or {
			req_ctx.err = err
			app.recover_handler(mut req_ctx) or {}
		}
	} else {
		req_ctx.handler = node.handler_fn()
		if app.cfg.pre_parse_multipart_form {
			req_ctx.parse_form() or { panic(err) }
		}
		req_ctx.mws = app.mws
		req_ctx.mws << node.mws
		req_ctx.next() or {
			req_ctx.err = err
			app.recover_handler(mut req_ctx) or {}
		}
	}

	// done := ctx.done()
	// select {
	// 	_ := <-req_ctx.finished {}
	// 	_ := <-done {
	// 		req_ctx.resp.set_status(.gateway_timeout)
	// 		println('context canceled')
	// 	}
	// }
	req_ctx.resp.header.set(.content_length, '${req_ctx.resp.body.len}')
	return req_ctx.resp
}

pub fn (mut app Application) graceful_shutdown() ! {
	_ := <-app.quit_ch
	for interrupt_fn in app.interrupts {
		interrupt_fn()!
	}
	app.close()
}

[inline]
pub fn (mut app Application) register_on_interrupt(cbs ...fn () !) {
	app.interrupts << cbs
}

fn (mut app Application) register_signal() {
	os.signal_opt(.int, fn [mut app] (it os.Signal) {
		app.quit_ch <- it
	}) or {}

	os.signal_opt(.kill, fn [mut app] (it os.Signal) {
		app.quit_ch <- it
	}) or {}

	os.signal_opt(.term, fn [mut app] (it os.Signal) {
		app.quit_ch <- it
	}) or {}
}

// run Start web service
pub fn (mut app Application) run() {
	app.Server.handler = app
	app.quit_ch = chan os.Signal{}
	app.register_signal()
	attrs := [vcolor.Attribute.bg_yellow, .bold, .underline, .bg_green]

	mut color := vcolor.new(...attrs)

	if !app.cfg.disable_startup_message {
		println(
			r'
	 _  _  ____  ____  _  _
	/ )( \(  __)(  _ \( \/ )
	\ \/ / ) _)  )   / )  /
	 \__/ (____)(__\_)(__/  '.trim_left('\n') +
			very.version + '\n')
		print(color.sprint('[Very] '))
	}

	spawn app.graceful_shutdown()
	app.Server.listen_and_serve()
}
