module very

import net.http { Request, Response, Server, Status }
import net.urllib
import log
import os
import vweb
import very.di
import orm
import xiusin.vcolor

type Handler = fn (mut ctx Context) !

const check_implement_err = error('Must pass in a structure that implements `IController`')

pub interface IController {
	ctx &Context
}

struct GroupRouter {
mut:
	trier  &Trier
	mws    []Handler
	prefix string
}

[heap]
pub struct Application {
	Server
	GroupRouter
mut:
	cfg Configuration
pub mut:
	logger            log.Log
	recover_handler   Handler
	not_found_handler Handler
	db                orm.Connection
	di                di.Builder
}

// 获取一个Application实例
pub fn new(cfg Configuration) Application {
	mut app := Application{
		Server: Server{}
		cfg: cfg
		db: unsafe { nil }
		trier: new_trie()
		logger: log.Log{
			level: .debug
		}
		not_found_handler: fn (mut ctx Context) ! {
			ctx.resp = Response{
				body: 'the router ${ctx.req.url} not found'
				status_code: Status.not_found.int()
			}
		}
	}

	app.Server.port = app.cfg.get_port()
	return app
}

// 注册数据库连接对象
pub fn (mut app Application) use_db(mut db orm.Connection) {
	app.db = db
}

// 注册中间件
pub fn (mut app GroupRouter) use(mw Handler) {
	app.mws << mw
}

// 注册get路由
pub fn (mut app GroupRouter) get(path string, handle Handler, mws ...Handler) {
	fk := 'GET;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) post(path string, handle Handler, mws ...Handler) {
	fk := 'POST;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) options(path string, handle Handler, mws ...Handler) {
	fk := 'OPTIONS;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) put(path string, handle Handler, mws ...Handler) {
	fk := 'PUT;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) delete(path string, handle Handler, mws ...Handler) {
	fk := 'DELETE;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) head(path string, handle Handler, mws ...Handler) {
	fk := 'HEAD;' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
}

// add 添加一个路由
pub fn (mut app GroupRouter) add(method http.Method, path string, handle Handler, mws ...Handler) {
	fk := method.str() + ';' + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
}

// all 注册所有请求方法
pub fn (mut app GroupRouter) all(path string, handle Handler, mws ...Handler) {
	app.add(.get, path, handle, ...mws)
	app.add(.post, path, handle, ...mws)
	app.add(.delete, path, handle, ...mws)
	app.add(.put, path, handle, ...mws)
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
	return &GroupRouter{
		trier: app.trier
		mws: mws
		prefix: app.get_with_prefix(prefix)
	}
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
				ctx.abort(500, '${err}')
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
	// TODO need register all files?
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
	app.deep_register(dir, if prefix == '/' { '' } else { prefix }, if index_file.len > 0 {
		index_file[0]
	} else {
		''
	})
}

pub fn (mut app GroupRouter) mount[T](mut instance T) {
	$if instance !is IController {
		panic(very.check_implement_err)
	}

	mut valid_ctx := false
	$for field in T.fields {
		$if field.name == 'ctx' && field.is_mut && field.is_pub {
			valid_ctx = true
		}
	}
	if !valid_ctx {
		panic(error('Please set the `pub mut: ctx &very.Context = unsafe { nil }` attribute in struct `${T.name}`'))
	}
	$for method in T.methods {
		http_methods, route_path := parse_attrs(method.name, method.attrs) or { panic(err) }
		name := method.name
		app.add(http_methods[0], route_path, fn [instance, name] [T](mut ctx Context) ! {
			mut ctrl := instance
			ctrl.ctx = unsafe { ctx }
			$for method in T.methods {
				if method.name == name {
					ctrl.$method()
					return
				}
			}
		})
	}
}

// handle 请求处理
fn (mut app Application) handle(req Request) Response {
	mut url := urllib.parse(req.url) or { return Response{
		body: '${err}'
	} }
	url.host = req.header.get(.host) or { '' }
	key := req.method.str() + ';' + url.path
	mut req_ctx := Context{
		req: req
		url: url
		resp: Response{}
		di: &app.di
		query: http.parse_form(url.raw_query)
		params: map[string]string{}
	}

	node, params, ok := app.trier.find(key)
	req_ctx.params = params.clone()
	if !ok {
		app.not_found_handler(mut req_ctx) or { return Response{
			body: '${err}'
		} }
	} else {
		req_ctx.handler = node.handler_fn()
		req_ctx.mws = app.mws
		req_ctx.mws << node.mws
		req_ctx.next() or { return Response{
			body: '${err}'
		} }
	}

	return req_ctx.resp
}

// run 启动Application服务
pub fn (mut app Application) run() {
	app.Server.handler = app

	mut color := vcolor.new(.bg_yellow, vcolor.Attribute.bold, vcolor.Attribute.underline,
		vcolor.Attribute.bg_hi_red)

	print(color.sprint('[Very]'))
	app.Server.listen_and_serve()
}
