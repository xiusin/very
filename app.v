module very

import net.http { Request, Response, ResponseConfig, Server, new_response }
import net.urllib
import log
import os
import vweb
import very.di
import xiusin.vcolor
import v.reflection
import compress.gzip

type Handler = fn (mut ctx Context) !

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
	logger            log.Logger
	recover_handler   fn (mut ctx Context, err IError) ! = unsafe { nil }
	not_found_handler Handler = unsafe { nil }
	pool              Pool
	db_pool           &Pool = unsafe { nil }
}

// new 获取一个Application实例
pub fn new(cfg Configuration) &Application {
	mut logger := &log.Log{
		level: cfg.logger_level
	}
	if cfg.logger_path.len > 0 {
		logger.set_full_logpath(cfg.logger_path)
	}

	mut app := &Application{
		cfg: cfg
		di: di.default_builder()
		trier: new_trie()
		logger: unsafe { nil }
		pool: new_pool(fn () &Context {
			return new_context()
		})
		recover_handler: fn (mut ctx Context, err IError) ! {
			ctx.set_status(.internal_server_error)
			ctx.text('${err}')
		}
		not_found_handler: fn (mut ctx Context) ! {
			ctx.resp = &Response{
				body: 'the router ${ctx.req.url} not found'
			}
			ctx.resp.set_status(.not_found)
		}
	}

	app.use_logger(logger)

	return app
}

[inline]
pub fn (mut app Application) use_logger(logger log.Logger) {
	app.logger = logger
	di.inject_on(app.logger, 'logger')
}

[inline]
pub fn (mut app Application) use_db_pool(mut pool Pool) {
	app.db_pool = unsafe { &pool }
}

// global_use 注册全局中间件: 在每个请求都会触发
[inline]
pub fn (mut app Application) global_use(mws ...Handler) {
	app.global_mws << mws
}

// use 注册中间件: 匹配到路由时才会执行
[inline]
pub fn (mut app GroupRouter) use(mws ...Handler) {
	app.mws << mws
}

// get 注册get路由
pub fn (mut app GroupRouter) get(path string, handle Handler, mws ...Handler) {
	app.trier.add('GET;' + app.get_with_prefix(path), handle, mws)
	app.options(path, handle, ...mws)
}

pub fn (mut app GroupRouter) post(path string, handle Handler, mws ...Handler) {
	app.trier.add('POST;' + app.get_with_prefix(path), handle, mws)
	app.options(path, handle, ...mws)
}

[inline]
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

fn (mut app GroupRouter) file_handler(dir string, index_file string) fn (mut ctx Context) ! {
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
		ctx.bytes(data.data)
	}
}

fn (mut app GroupRouter) register_file(dir string, prefix string, index_file string) {
	cfn := fn [mut app] (dir string, index_file string) fn (mut ctx Context) ! {
		return app.file_handler(dir, index_file)
	}

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

pub fn (mut app GroupRouter) embed_statics(prefix string, mut asset Asset) {
	app.all('${prefix}/*filepath', fn [mut asset] (mut ctx Context) ! {
		mut file := ctx.param('filepath')

		data := asset.find(file) or {
			file = if file == '' { 'index.html' } else { '${file}/index.html' }
			asset.find(file)!
		}
		ext := os.file_ext(file)
		if ext in vweb.mime_types {
			ctx.resp.header.add(.content_type, vweb.mime_types[ext])
		}
		ctx.bytes(data.data)
	})
}

pub fn (mut app GroupRouter) statics(prefix string, dir string, index_file ...string) {
	default_index_file := if index_file.len > 0 { index_file[0] } else { '' }
	app.register_file(dir, if prefix == '/' { '' } else { prefix }, default_index_file)
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
		$if field.name == 'Context'
			&& reflection.get_type(field.typ).sym.name == 'xiusin.very.Context' {
			return true
		}
	}
	return false
}

fn (mut app GroupRouter) get_injected_fields[T]() map[string]voidptr {
	di_flag := 'inject: '
	mut injected_fields := map[string]voidptr{}
	$for field in T.fields {
		$if field.typ !is Context {
			services := field.attrs.filter(it.contains(di_flag)).map(it.replace(di_flag,
				''))
			if services.len == 1 {
				sym := reflection.get_type_symbol(field.typ) or {
					reflection.TypeSymbol{
						kind: .placeholder
					}
				}
				is_interface := sym.kind == reflection.VKind.interface_

				if field.indirections == 1 || is_interface { // only pointer or interface
					service := app.di.get_service(services[0]) or { panic(err) }
					field_typ := '${if is_interface { '' } else { '&' }}${reflection.type_symbol_name(field.typ)}'
					if service.get_type() == field_typ {
						injected_fields[field.name] = service.get_instance()
					} else {
						panic('`${field.name}` field type mut be `${service.get_type()}` current `${field_typ}`')
					}
				} else {
					println(vcolor.red_string('[WARN] inject field must be a ref field: ${field.name}'))
				}
			}
		}
	}
	return injected_fields
}

fn (mut app GroupRouter) parse_attrs(name string, attrs []string) !([]http.Method, string) {
	if attrs.len == 0 {
		return [http.Method.get], ''
	}
	mut x := attrs.clone()
	mut methods := []http.Method{}
	mut path := ''

	for i := 0; i < x.len; {
		attr := x[i]
		attru := attr.to_upper()
		m := http.method_from_str(attru)
		if attru == 'GET' || m != .get {
			methods << m
			x.delete(i)
			continue
		}
		if attr.starts_with('/') {
			if path != '' {
				return IError(http.MultiplePathAttributesError{})
			}
			path = attr
			x.delete(i)
			continue
		}
		i++
	}
	if x.len > 0 {
		return IError(http.UnexpectedExtraAttributeError{
			attributes: x
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
		panic('Must pass in a structure that implements `AbstractController`')
	}

	injected_fields, route_prefix := app.get_injected_fields[T](), app.parse_group_attr[T]()

	mut router := if route_prefix.len > 0 {
		app.group(route_prefix)
	} else {
		app
	}

	$for method_ in T.methods {
		if method_.attrs.len > 0 {
			mut http_methods, route_path := app.parse_attrs(method_.name, method_.attrs) or {
				panic(err)
			}

			if !http_methods.contains(http.Method.options) {
				http_methods << http.Method.options
			}

			method := method_
			for ano_method in http_methods {
				router.add(ano_method, route_path, fn [method, injected_fields] [T](mut ctx Context) ! {
					mut ctrl := T{}
					ctrl.Context = ctx
					$for method__ in T.methods {
						if method__.name == method.name {
							$for field in T.fields {
								$if field.typ !is Context {
									if field.name in injected_fields {
										unsafe {
											field_ptr := &voidptr(&ctrl.$(field.name)) // to &voidptr
											*field_ptr = injected_fields[field.name]
											_ = field_ptr // shield warning
										}
									}
								}
							}
							$if method__.is_pub && method__.typ is fn () {
								ctrl.$method() or { return err }
							} $else {
								return error('the method `${method.name}` is not available')
							}
						}
					}
				})
			}
		}
	}
}

// handle
fn (mut app Application) handle(req Request) Response {
	mut url := urllib.parse(req.url) or { return Response{
		body: '${err}'
	} }

	if app.cfg.max_request_body_size > 0 {
		content_length := req.header.get(.content_length) or { '0' }.u64()
		if app.cfg.max_request_body_size < content_length {
			return Response{
				body: 'request body size too large!'
			}
		}
	}

	url.host = req.header.get(.host) or { '' }

	mut req_ctx := new_context()

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

	// 需要联合其他中间件使用, 考虑compress等中间件需要全局
	if app.global_mws.len > 0 {
		for _, handler in app.global_mws {
			if !req_ctx.is_stopped() {
				handler(mut req_ctx) or {
					app.recover_handler(mut req_ctx, err) or {}
					return resp
				}
			}
		}

		if req_ctx.is_stopped() {
			return resp
		}
	}

	node, mut params, ok := app.trier.find(key)
	req_ctx.params = params.move()
	if !ok {
		app.not_found_handler(mut req_ctx) or { app.recover_handler(mut req_ctx, err) or {} }
	} else {
		req_ctx.handler = node.handler_fn()

		if app.cfg.pre_parse_multipart_form {
			very_req.parse_form() or { panic(err) }
		}
		req_ctx.mws = app.mws
		req_ctx.mws << node.mws
		req_ctx.next() or { app.recover_handler(mut req_ctx, err) or {} }
	}

	req_ctx.resp.header.set(.content_length, '${req_ctx.resp.body.len}')
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
}

[inline]
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
			very.version + '\n')
		print(color.sprint('[' + app.cfg.app_name + '] '))
	}

	spawn app.graceful_shutdown()
	app.Server.listen_and_serve()
}
