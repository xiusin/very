module very

import net.http { Request, Response, ResponseConfig, Server, new_response }
import net.urllib
import log
import os
import time
import veb
import xiusin.very.di
import xiusin.very.event
import xiusin.very.session
import xiusin.vcolor
import dl.loader

pub type Handler = fn (mut ctx Context) !

const version = 'v0.0.1 dev'

struct GroupRouter {
mut:
	trier  &Trier
	mws    []Handler
	prefix string
pub mut:
	di                &di.Container  = unsafe { di.default_container() }
	init_method       fn (voidptr) ! = unsafe { nil } // 调用结束方法 （controller）
	deinit_method     fn (voidptr) ! = unsafe { nil } // 调用结束方法 （controller）
	not_found_handler Handler        = unsafe { nil }
}

pub fn (app &GroupRouter) get_di() &di.Container {
	return app.di
}

pub fn (mut app GroupRouter) set_di(mut builder di.Container) {
	app.di = unsafe { builder }
}

@[heap]
pub struct Application {
	Server
	GroupRouter
mut:
	cfg        Configuration
	quit_ch    chan os.Signal
	interrupts []fn () !
	ctx_pool   PoolChannel[&Context]
pub mut:
	logger            log.Logger
	event_bus         &event.EventBus                    = unsafe { nil }
	session_store     &session.MemorySessionStore        = unsafe { nil }
	recover_handler   fn (mut ctx Context, err IError) ! = unsafe { nil }
	not_found_handler Handler = unsafe { nil }
}

// new 获取一个Application实例
pub fn new(cfg Configuration) &Application {
	mut logger := &log.Log{}
	logger.set_level(cfg.logger_level)

	if cfg.logger_path.len > 0 {
		logger.set_full_logpath(cfg.logger_path)
	}

	if cfg.logger_console {
		logger.log_to_console_too()
	}

	mut app := &Application{
		cfg:               cfg
		di:                di.new_container()
		event_bus:         event.new_event_bus()
		trier:             new_trie()
		logger:            unsafe { nil }
		ctx_pool:          new_ch_pool[&Context](fn () !&Context {
			return new_context()
		}, int(cfg.max_request))
		recover_handler:   fn (mut ctx Context, err IError) ! {
			ctx.set_status(.internal_server_error)
			return ctx.text('${err}')
		}
		not_found_handler: fn (mut ctx Context) ! {
			ctx.resp.set_status(.not_found)
			code := ctx.resp.status_code
			message := ctx.resp.status_msg
			ctx.html($tmpl('resources/status.html'))
		}
	}
	app.use_logger(logger)

	return app
}

pub fn (mut app Application) inject_on[T](service T, name ...string) {
	if name.len > 0 {
		di.inject_on(service, name[0])
	} else {
		di.inject_on(service)
	}
}

pub fn (mut app Application) register_singleton[T](instance T, name ...string) {
	app.di.register_singleton(instance, ...name)
}

pub fn (mut app Application) register_factory[T](factory fn () &T, scope di.BeanScope, name ...string) {
	app.di.register_factory(factory, scope, ...name)
}

pub fn (mut app Application) register_lazy[T](factory fn () &T, name ...string) {
	app.di.register_lazy(factory, ...name)
}

pub fn (mut app Application) bind_instance[T](instance T, name ...string) {
	app.di.bind_instance(instance, ...name)
}

// register registers a service struct type with auto-injection.
// The container creates an instance of T and injects all @[inject: 'name'] fields.
// This is the Spring @Service equivalent.
pub fn (mut app Application) register[T](scope di.BeanScope, name ...string) ! {
	app.di.register[T](scope, ...name)!
}

// register_service reads @[service] and @[scope] attributes from T and auto-registers it.
// Example:
//   @[service]
//   struct UserService {
//       repo &UserRepo @[inject: 'user_repo']
//   }
//   app.register_service[UserService]()!
pub fn (mut app Application) register_service[T]() ! {
	app.di.register_service[T]()!
}

pub fn (mut app Application) on(event_name string, listener event.EventListener) {
	app.event_bus.on(event_name, listener)
}

pub fn (mut app Application) emit(e event.Event) ! {
	app.event_bus.emit(e)!
}

pub fn (mut app Application) off(event_name string) {
	app.event_bus.off(event_name)
}

// set_session_store configures the session store used by request contexts.
// When set, every request context's session will use this store instead of
// the global default. Pass a MemorySessionStore or a custom implementation.
pub fn (mut app Application) set_session_store(store &session.MemorySessionStore) {
	app.session_store = store
}

@[inline]
pub fn (mut app Application) use_logger(logger &log.Log) {
	app.logger = logger
	app.inject_on(logger, 'logger')
}

pub fn (mut app Application) register_plugin(path string) ! {
	mut dl_loader := loader.get_or_create_dynamic_lib_loader(paths: [path], key: path) or { return }
	app.register_on_interrupt(fn [mut dl_loader] () ! {
		dl_loader.unregister()
	})
}

@[inline]
pub fn (mut app GroupRouter) use(mws ...Handler) {
	app.mws << mws
}

@[inline]
pub fn (mut app GroupRouter) get(path string, handle Handler, mws ...Handler) {
	app.trier.add('GET;' + app.get_with_prefix(path), handle, mws)
}

@[inline]
pub fn (mut app GroupRouter) post(path string, handle Handler, mws ...Handler) {
	app.trier.add('POST;' + app.get_with_prefix(path), handle, mws)
}

@[inline]
pub fn (mut app GroupRouter) options(path string, handle Handler, mws ...Handler) {
	app.trier.add('OPTIONS;' + app.get_with_prefix(path), handle, mws)
}

@[inline]
pub fn (mut app GroupRouter) put(path string, handle Handler, mws ...Handler) {
	app.trier.add('PUT;' + app.get_with_prefix(path), handle, mws)
}

@[inline]
pub fn (mut app GroupRouter) delete(path string, handle Handler, mws ...Handler) {
	app.trier.add('DELETE;' + app.get_with_prefix(path), handle, mws)
}

@[inline]
pub fn (mut app GroupRouter) head(path string, handle Handler, mws ...Handler) {
	app.trier.add('HEAD;' + app.get_with_prefix(path), handle, mws)
}

@[inline]
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
@[inline]
fn (mut app GroupRouter) get_with_prefix(key string) string {
	return '${app.prefix}/${key.trim_left('/')}'
}

// group Get a group router
pub fn (mut app GroupRouter) group(prefix string, mws ...Handler) &GroupRouter {
	return &GroupRouter{
		trier:         app.trier
		mws:           mws
		di:            app.get_di()
		prefix:        app.get_with_prefix(prefix)
		deinit_method: app.deinit_method
		init_method:   app.init_method
	}
}

fn (mut app GroupRouter) file_handler(dir string, index_file string) Handler {
	return fn [dir, index_file] (mut ctx Context) ! {
		mut filepath := ctx.param('filepath')
		if index_file.len > 0 && filepath.len == 0 {
			filepath = index_file
		}
		file := os.join_path(dir.trim('/'), filepath)
		data := os.read_file(file)!
		ext := os.file_ext(file)
		if ext in veb.mime_types {
			ctx.resp.header.add(.content_type, veb.mime_types[ext])
		}
		ctx.resp.body = data
	}
}

fn (mut app GroupRouter) register_file(dir string, prefix string, index_file string) ! {
	files := os.ls(dir)!
	app.all('${prefix}/*filepath', app.file_handler(dir, index_file))
	for file in files {
		f_dir := os.join_path(dir, file)
		if os.is_dir(f_dir) {
			app.register_file(f_dir, '${prefix}/${file}', index_file)!
			app.all('${prefix}/${file}/*filepath', app.file_handler(f_dir, index_file))
		}
	}
}

pub fn (mut app GroupRouter) embed_statics(prefix string, mut asset Asset) {
	app.all('${prefix}/*filepath', fn [mut asset] (mut ctx Context) ! {
		mut file := ctx.param('filepath')

		data := asset.find(file) or {
			file = if file == '' { 'index.html' } else { '${file}/index.html' }
			asset.find(file)!
		}
		ext := os.file_ext(file)
		if ext in veb.mime_types {
			ctx.resp.header.add(.content_type, veb.mime_types[ext])
		}
		ctx.bytes(data.data)
	})
}

pub fn (mut app GroupRouter) statics(prefix string, dir string, index_file ...string) ! {
	default_index_file := if index_file.len > 0 { index_file[0] } else { '' }
	app.register_file(dir, if prefix == '/' { '' } else { prefix }, default_index_file)!
}

fn (mut app GroupRouter) parse_group_attr[T]() string {
	mut group_route := ''
	$for f in T.attributes {
		if f.name == 'group' && f.has_arg && f.arg.len > 0 {
			if !f.arg.starts_with('/') {
				panic(error('The `group` attr of a struct must begin with a forward slash (/).'))
			}
			group_route = f.arg
		}
	}
	return group_route
}

fn (mut app GroupRouter) mountable[T]() bool {
	$for field in T.fields {
		$if field.name == 'Context' {
			$if field.typ is Context {
				return true
			}
		}
	}
	return false
}

fn (mut app GroupRouter) parse_attrs(name string, attrs []string) !([]http.Method, string) {
	if attrs.len == 0 {
		return [http.Method.get], ''
	}
	mut methods := []http.Method{}
	mut path := ''
	mut leftover := []string{}

	for attr in attrs {
		attru := attr.to_upper()
		m := http.method_from_str(attru)
		// Recognised HTTP method?
		if attru == 'GET' || m != .get {
			methods << m
			continue
		}
		// Route path?
		if attr.starts_with('/') {
			if path != '' {
				return IError(http.MultiplePathAttributesError{})
			}
			path = attr
			continue
		}
		// Unknown attribute
		leftover << attr
	}
	if leftover.len > 0 {
		return IError(http.UnexpectedExtraAttributeError{
			attributes: leftover
		})
	}
	if methods.len == 0 {
		methods = [http.Method.get]
	}
	if path == '' {
		path = '/${name}'
	}
	return methods, path.to_lower()
}

pub fn (mut app GroupRouter) mount[T]() {
	if !app.mountable[T]() {
		panic(error('Must pass in a structure that implements `very.contracts.Controller`'))
	}

	route_prefix := app.parse_group_attr[T]()

	mut router := unsafe { &app }
	if route_prefix.len > 0 {
		router = app.group(route_prefix)
	}

	$for method_ in T.methods {
		if method_.attrs.len > 0 {
			mut http_methods, route_path := app.parse_attrs(method_.name, method_.attrs) or {
				panic(err)
			}

			if !http_methods.contains(http.Method.options) {
				http_methods << http.Method.options
			}

			// Only register handler if method is pub and takes no args
			$if method_.is_pub && method_.typ is fn () {
				for ano_method in http_methods {
					router.add(ano_method, route_path, app.warp_handler[T](method_))
				}
			}
		}
	}
}

fn (mut app GroupRouter) warp_handler[T](method FunctionData) Handler {
	return fn [method, mut app] [T](mut ctx Context) ! {
		mut ctrl := T{}
		ctrl.Context = ctx
		// Auto-inject @[inject: 'name'] fields from DI container per-request.
		// Uses di.inject_fields_safe which supports circular dependency resolution.
		// Safe variant used to avoid V 0.5.1 generic closure ! propagation bug.
		di.inject_fields_safe[T](mut ctrl, mut app.di)
		// init hook
		if !isnil(app.init_method) {
			unsafe {
				app.init_method(voidptr(&ctrl)) or {}
			}
		}
		// call the handler method
		$for method__ in T.methods {
			if method__.name == method.name {
				ctrl.$method() or { return error('handler `${method.name}` failed') }
			}
		}
		// deinit hook
		if !isnil(app.deinit_method) {
			unsafe {
				app.deinit_method(voidptr(&ctrl)) or {}
			}
		}
	}
}

// handle
fn (mut app Application) handle(req Request) Response {
	mut url := urllib.parse(req.url) or {
		return Response{
			status_code: 500
			body:        '${err}'
		}
	}

	if app.cfg.max_request_body_size > 0 {
		content_length := req.header.get(.content_length) or { '0' }.u64()
		if app.cfg.max_request_body_size < content_length {
			return Response{
				status_code: 413
				body:        'request body size too large!'
			}
		}
	}

	url.host = req.header.get(.host) or { '' }

	mut req_ctx := app.ctx_pool.acquire() or {
		return Response{
			status_code: 419
			body:        'too many request'
		}
	}
	defer {
		app.ctx_pool.release(req_ctx)
	}

	mut very_req := new_request(&req, url)

	key := req.method.str() + ';' + url.path

	mut resp := new_response(ResponseConfig{})

	req_ctx.reset(very_req, resp)
	req_ctx.app = app
	unsafe {
		req_ctx.logger = app.logger
	}
	if app.cfg.disable_keep_alive {
		resp.header.set(.connection, 'close')
	}

	if app.cfg.server_name.len > 0 {
		req_ctx.resp.header.set(.server, app.cfg.server_name)
	}

	req_ctx.mws = app.mws

	if app.cfg.enable_request_scope {
		req_ctx.di_container = app.di.create_request_container()
	}

	if app.session_store != unsafe { nil } {
		req_ctx.sess.set_session_store(app.session_store)
	}

	start_ticks := time.ticks()
	app.emit(event.RequestStartEvent{
		method: req.method.str()
		path:   url.path
	}) or {}

	node, mut params, ok := app.trier.find(key)
	req_ctx.params = params.move()

	if !ok {
		req_ctx.handler = app.not_found_handler
	} else {
		req_ctx.handler = node.handler_fn()
		if app.cfg.pre_parse_multipart_form {
			very_req.parse_form() or { panic(err) }
		}
		req_ctx.mws << node.mws
	}
	req_ctx.next() or {
		app.recover_handler(mut req_ctx, err) or { app.logger.error('request failed: ${err}') }
	}

	req_ctx.resp.header.set(.content_length, '${req_ctx.resp.body.len}')
	app.emit(event.RequestEndEvent{
		method:      req.method.str()
		path:        url.path
		status_code: req_ctx.resp.status_code
		duration_ms: time.ticks() - start_ticks
	}) or {}
	return resp
}

pub fn (mut app Application) graceful_shutdown() ! {
	_ := <-app.quit_ch
	defer {
		app.close()
	}

	for interrupt_fn in app.interrupts {
		interrupt_fn()!
	}
	app.emit(event.ServerShutdownEvent{}) or {}
}

@[inline]
pub fn (mut app Application) register_on_interrupt(cbs ...fn () !) {
	app.interrupts << cbs
}

fn (mut app Application) signal_handler(it os.Signal) {
	if app.quit_ch.closed {
		return
	}
	defer {
		app.quit_ch.close()
	}
	$if debug {
		vcolor.yellow('received signal: ${it}')
	}
	app.quit_ch <- it
}

// register_os_signal This function registers the OS signals for interrupt, kill,
// and termination and sets a signal handler for each of them.
// It allows the application to gracefully handle these signals and perform necessary actions before shutting down.
fn (mut app Application) register_os_signal() {
	os.signal_opt(.int, app.signal_handler) or {}
	os.signal_opt(.kill, app.signal_handler) or {}
	os.signal_opt(.term, app.signal_handler) or {}
}

// run Start web service
pub fn (mut app Application) run() {
	app.Server.handler = app

	app.Server.addr = ':${app.cfg.port}'
	app.Server.accept_timeout = app.cfg.accept_timeout
	app.Server.write_timeout = app.cfg.write_timeout
	app.Server.read_timeout = app.cfg.read_timeout

	app.quit_ch = chan os.Signal{}
	app.register_os_signal()

	attrs := [vcolor.Attribute.bg_yellow, .bold, .underline, .bg_green]
	mut color := vcolor.new(...attrs)

	if !app.cfg.disable_startup_message {
		println(
			r'
	 _  _  ____  ____  _  _
	/ )( \(  __)(  _ \( \/ )
	\ \/ / ) _)  )   / )  /
	 \__/ (____)(__\_)(__/  '.trim_left('\n') +
			version + '\n')
		print(color.sprint('[' + app.cfg.app_name + '] '))
	}

	spawn app.graceful_shutdown()
	app.emit(event.ServerStartEvent{
		port:     app.cfg.port
		app_name: app.cfg.app_name
	}) or {}
	app.Server.listen_and_serve()
}
