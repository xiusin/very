module veb

import net.http { CommonHeader, Request, Response, Server, Status }
import net.urllib
import log
import os
import vweb

type VebHandler = fn(mut ctx Context)
type OrmInstance = sqlite.DB | mysql.DB | pg.DB

struct GroupRouter {
mut:
	trier 				&Trier
	mws 				[]VebHandler
	prefix 				string
}

struct VebApp {
	Server
	GroupRouter
mut:
	cfg 				Configuration

pub mut:
	logger 				log.Log
	recover_handler 	VebHandler
	not_found_handler 	VebHandler
	db     				OrmInstance
}

// 获取一个VebApp实例
pub fn new_app(cfg Configuration) VebApp {
	mut app := VebApp{
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

// 注册中间件
pub fn (mut app GroupRouter) use(mw VebHandler) {
	app.mws << mw
}

pub fn (mut app GroupRouter) get(path string, handle VebHandler, mws ...VebHandler)  {
	fk := "GET;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) post(path string, handle VebHandler, mws ...VebHandler)  {
	fk := "POST;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}


pub fn (mut app GroupRouter) options(path string, handle VebHandler, mws ...VebHandler)  {
	fk := "OPTIONS;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) put(path string, handle VebHandler, mws ...VebHandler)  {
	fk := "PUT;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) delete(path string, handle VebHandler, mws ...VebHandler)  {
	fk := "DELETE;" + app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
	app.head(path, handle, ...mws)
}

pub fn (mut app GroupRouter) head(path string, handle VebHandler, mws ...VebHandler) {
	fk := "HEAD;" +  app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
}

// add 添加一个路由
pub fn (mut app GroupRouter) add(method http.Method, path string, handle VebHandler, mws ...VebHandler) {
	fk := method.str() + ";" +  app.get_with_prefix(path)
	app.trier.add(fk, handle, mws)
}

// all 注册所有请求方法
pub fn (mut app GroupRouter) all(path string, handle VebHandler, mws ...VebHandler) {
	app.add(.get, path, handle, ...mws)
	app.add(.post, path, handle, ...mws)
	app.add(.delete, path, handle, ...mws)
	app.add(.put, path, handle, ...mws)
}

// get_with_prefix 获取带前缀的路由path
fn (mut app GroupRouter) get_with_prefix(key string) string {
	if key.starts_with('/') {
		return '${app.prefix}${key}'
	} else {
		return '${app.prefix}/${key}'
	}
}

// group 获取一个路由分组
pub fn (mut app GroupRouter) group(prefix string, mws ...VebHandler) &GroupRouter {
	return &GroupRouter {
		trier: app.trier
		mws: mws
		prefix: app.get_with_prefix(prefix)
	}
}

// statics 静态文件处理
pub fn (mut app GroupRouter) statics(prefix string, dir string, index_file ...string) {
	app.all(prefix + "/*filepath", fn [dir, index_file] (mut ctx Context) {
		mut filepath := ctx.param('filepath')
		if filepath.len == 0 && index_file.len > 0 {
			filepath = index_file[0]
		}
		ffile := dir.trim('/') + '/' + filepath

		data := os.read_file(ffile) or {
			ctx.abort(500, '${err}')
			return
		}
		ext := os.file_ext(ffile)
		if ext in vweb.mime_types {
			ctx.resp.header.add(.content_type, vweb.mime_types[ext])
		}
		ctx.resp.body = data
	})
}

// 暂不支持， 官方没有给出反射调用方法
pub fn (mut app GroupRouter) _controller<T>(ctrl T) {
	$for method in T.methods {
		http_methods, route_path := parse_attrs(method.name, method.attrs) or {
			 panic('error parsing method attributes: $err')
			 return
		}
		// app.add(http_methods[0], route_path, ret)
		app.add(http_methods[0], route_path, fn [ctrl, method] (mut ctx Context) {
			println('${ctx.path()}')
			ctrl.$method([]string{len: 0})
			// dump(ret)
		})
	}
}


// handle 请求处理
fn (mut app VebApp) handle(req Request) Response {
	url := urllib.parse(req.url) or {
		return Response{ body: '${err}' }
	}

	key := req.method.str() + ";" + url.path
	mut ctx := Context {
		req: req
		url: url
		resp: Response{}
		db: &app.db
		query: http.parse_form(url.raw_query)
		params: map[string]string{}
	}

	node, params, ok := app.trier.find(key)
	ctx.params = params.clone()
	if !ok {
		app.not_found_handler(mut ctx)
	} else {
		ctx.handler = node.handler_fn()
		ctx.mws = app.mws
		ctx.mws << node.mws
		ctx.next()
	}

	return ctx.resp
}

// run 启动vebapp服务
pub fn (mut app VebApp) run() {
	app.Server.handler = app
	print('[Pine for V] ')
	app.Server.listen_and_serve() or {
		panic(err)
	}
}
