module very

import net.http { CommonHeader, Request, Response, Server, Status }
import net.urllib
import log
import os
import vweb
import sqlite
import mysql

type Handler = fn(mut ctx Context)
type Orm = sqlite.DB | mysql.Connection 

struct GroupRouter {
mut:
	trier 				&Trier
	mws 				[]Handler
	prefix 				string
}

[heap]
struct Application {
	Server
	GroupRouter
mut:
	cfg 				Configuration

pub mut:
	logger 				log.Log
	recover_handler 	Handler
	not_found_handler 	Handler
	db     				Orm		
}

// 获取一个Application实例
pub fn new(cfg Configuration) Application {
	mut app := Application{
		Server: Server{}
		cfg: cfg
		trier: new_trie()
		logger: log.Log{
			level: .debug
		}
		not_found_handler: fn (mut ctx Context) {
			ctx.resp = Response {
				body: "the router ${ctx.req.url} not found"
				status_code: Status.not_found.int()
			}
		}
	}

	app.Server.port = app.cfg.get_port()
	return app
}

pub fn (mut app Application) use_db(mut db Orm) {
	app.db = db
} 

// 注册中间件
pub fn (mut app GroupRouter) use(mw Handler) {
	app.mws << mw
}

pub fn (mut app GroupRouter) get(path string, handle Handler, mws ...Handler)  {
	fk := "GET;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) post(path string, handle Handler, mws ...Handler)  {
	fk := "POST;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}


pub fn (mut app GroupRouter) options(path string, handle Handler, mws ...Handler)  {
	fk := "OPTIONS;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) put(path string, handle Handler, mws ...Handler)  {
	fk := "PUT;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) delete(path string, handle Handler, mws ...Handler)  {
	fk := "DELETE;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) head(path string, handle Handler, mws ...Handler) {
	fk := "HEAD;" +  app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
}

// add 添加一个路由
pub fn (mut app GroupRouter) add(method http.Method, path string, handle Handler, mws ...Handler) {
	fk := method.str() + ";" +  app.get_with_prefix(path)
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
	return &GroupRouter {
		trier: app.trier
		mws: mws
		prefix: app.get_with_prefix(prefix)
	}
}

fn (mut app GroupRouter) deep_register(dir string, prefix string, index_file string) {
	cfn := fn (dir string, index_file string) fn (mut ctx Context) {
			return fn [dir, index_file] (mut ctx Context) {
				mut filepath := ctx.param('filepath')
				if index_file.len > 0 && filepath.len == 0 {
					filepath = index_file
				}
				file := dir.trim('/') + '/' + filepath
				data := os.read_file(file) or {
					eprintln("read file ${file} ${err}")
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

	files := os.ls(dir) or {
		panic(err)
	}
	// 注册处理方法
	app.all("${prefix}/*filepath", cfn(dir, index_file))
	for file in files {
		f_dir := os.join_path(dir, file)
		if os.is_dir(f_dir) {
			app.deep_register(f_dir, '${prefix}/${file}', index_file)
			
			// 注册本级目录处理方法
			app.all("${prefix}/${file}/*filepath", cfn(f_dir, index_file))
		}
	}
}

// statics 静态文件处理
pub fn (mut app GroupRouter) statics(prefix string, dir string, index_file ...string) {
	app.deep_register(
		dir, 
		if prefix == '/' { '' } else {  prefix }, 
		if index_file.len > 0 { index_file[0] } else { '' }
	)
}

pub fn (mut app GroupRouter) controller<T>(mut instance T) {
	// TODO 判断T是否包含有ctx属性
	$for method in T.methods {
		http_methods, route_path := parse_attrs(method.name, method.attrs) or {
			 panic('解析方法`${method.name}`属性错误: $err')
			 return
		}
		name := method.name
		app.add(http_methods[0], route_path, fn [mut instance, name] <T> (mut ctx Context) {
			mut ctrl := instance // replace with .clone()
			ctrl.ctx = unsafe { ctx }

			// TODO 注入其他属性
			$for method in T.methods {
				if method.name == name {
					// FIXME error: invalid string method call: expected `string`, not `FunctionData`
					ctrl.$method() // 调用名称必须为 `method`
					return 
				} 
			}
		})
	}
}

// handle 请求处理
fn (mut app Application) handle(req Request) Response {
	// defer {
	// 	app.recover_handler()
	// }

	mut url := urllib.parse(req.url) or {
		return Response{ body: '${err}' }
	}
	url.host = req.header.get(.host) or { '' }
	key := req.method.str() + ";" + url.path 
	mut req_ctx := Context {
		req: req
		url: url
		resp: Response{}
		db: &app.db
		app: &app
		query: http.parse_form(url.raw_query)
		params: map[string]string{}
	}

	node, params, ok := app.trier.find(key)
	req_ctx.params = params.clone()
	if !ok {
		app.not_found_handler(mut req_ctx)
	} else {
		req_ctx.handler = node.handler_fn()
		req_ctx.mws = app.mws
		req_ctx.mws << node.mws
		req_ctx.next()
	}

	return req_ctx.resp
}

// run 启动Application服务
pub fn (mut app Application) run() {
	app.Server.handler = app
	print('[Pine for V] ')
	app.Server.listen_and_serve() or {
		panic(err)
	}
}
