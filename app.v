module very

import net.http { Request, Response, ResponseConfig, Server, Status, new_response }
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

const check_implement_err = error('Must pass in a structure that implements `IController`')

const version = 'v0.0.0 dev'

pub interface IController {
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

// 获取一个Application实例
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

// 注册数据库连接对象
[inline]
pub fn (mut app Application) use_db(mut db orm.Connection) {
	app.db = db
}

// 注册全局中间件: 在每个请求都会触发
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

// group 获取一个路由分组
pub fn (mut app GroupRouter) group(prefix string, mws ...Handler) &GroupRouter {
	mut group := &GroupRouter{
		trier: app.trier
		mws: mws
		di: app.get_di()
		prefix: app.get_with_prefix(prefix)
	}
	return group
}

fn (mut app GroupRouter) deep_register(dir string, prefix string, index_file string) {
	cfn := fn (dir string, index_file string) fn (mut ctx Context) ! {
		return fn [dir, index_file] (mut ctx Context) ! {
			mut filepath := ctx.param('filepath')
			if index_file.len > 0 && filepath.len == 0 {
				filepath = index_file
			}
			file := dir.trim('/') + '/' + filepath
			data := os.read_file(file) or {
				eprintln('read file ${file} ${err}')
				ctx.abort(Status.internal_server_error, '${err}')
				return
			}
			ext := os.file_ext(file)
			if ext in vweb.mime_types {
				ctx.resp.header.add(.content_type, vweb.mime_types[ext])
			}
			ctx.resp.body = data
		}
	}

	files := os.ls(dir) or { return }
	// FIXME need register all files?
	app.all('${prefix}/*filepath', cfn(dir, index_file))
	for file in files {
		f_dir := os.join_path(dir, file)
		if os.is_dir(f_dir) {
			app.deep_register(f_dir, '${prefix}/${file}', index_file)
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
	app.deep_register(dir, if prefix == '/' { '' } else { prefix }, default_index_file)
}

pub fn (mut app GroupRouter) mount[T](mut instance T) {
	mut di_flag := 'inject: '
	$if instance !is IController {
		panic(very.check_implement_err)
	}
	mut valid_ctx := false
	mut injected_fields := map[string]voidptr{}
	$for field in T.fields {
		$if field.name == 'ctx' && field.is_mut && field.is_pub {
			valid_ctx = true
		}
		services := field.attrs.filter(it.contains(di_flag)).map(it.replace(di_flag, ''))
		if services.len == 1 {
			injected_fields[field.name] = app.di.get_voidptr(services[0]) or { panic(err) }
		}
	}
	if !valid_ctx {
		panic(error('Please set the `pub mut: ctx &very.Context = unsafe { nil }` attribute in struct `${T.name}`'))
	}
	$for method_ in T.methods {
		http_methods, route_path := parse_attrs(method_.name, method_.attrs) or { panic(err) }
		method := method_
		for _, ano_method in http_methods {
			app.add(ano_method, route_path, fn [method, injected_fields] [T](mut ctx Context) ! {
				mut ctrl := T{}
				ctrl.ctx = unsafe { ctx }
				$for field in T.fields {
					if field.name in injected_fields {
						ctrl.$(field.name) = unsafe { injected_fields[field.name] }
					}
				}
				$for method__ in T.methods {
					if method__.name == method.name {
						ctrl.$method()
						return
					}
				}
			})
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
	defer {
		cancel()
	}

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

	if app.cfg.server_name.len > 0 {
		req_ctx.resp.header.set(.server, app.cfg.server_name.len)
	}
	req_ctx.resp.header.set(.connection, 'close')

	spawn fn [mut app, mut req_ctx, key] () {
		defer {
			req_ctx.finished.close()
		}

		node, params, ok := app.trier.find(key)
		req_ctx.params = params.clone()
		if !ok {
			app.not_found_handler(mut req_ctx) or {
				req_ctx.err = err
				app.recover_handler(mut req_ctx) or {}
			}
		} else {
			req_ctx.handler = node.handler_fn()
			req_ctx.mws = app.mws
			req_ctx.mws << node.mws
			req_ctx.next() or {
				req_ctx.err = err
				app.recover_handler(mut req_ctx) or {}
			}
		}
	}()

	done := ctx.done()
	select {
		_ := <-done {
			req_ctx.resp.set_status(.gateway_timeout)
			println('context canceled')
		}
		_ := <-req_ctx.finished {}
	}
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
