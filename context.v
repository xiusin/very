module very

import net.http
import very.session
import json
import log
import xiusin.validator

pub type Val = []byte
	| []f64
	| []i64
	| []int
	| []rune
	| []string
	| byte
	| f64
	| i64
	| i8
	| int
	| rune
	| string
	| u64
	| u8
	| voidptr

pub struct Context {
mut:
	app 	  &Application
	mw_index   int = -1
	is_stopped bool
	resp       &http.Response
	params     map[string]string
	values     map[string]Val = map[string]Val{}
pub mut:
	req     &Request
	mws     []Handler
	handler Handler
	sess    session.Session
	logger  log.Log
}

fn new_context() &Context {
	return &Context{
		resp: unsafe { nil }
		req: unsafe { nil }
		app: unsafe { nil }
	}
}

pub fn (mut ctx Context) reset(req &Request, resp &http.Response) {
	ctx.req = unsafe { req }
	ctx.resp = unsafe { resp }
	ctx.values.clear()
	ctx.params.clear()
	ctx.is_stopped = false
	ctx.mw_index = -1
	ctx.mws.clear()
}

pub fn (mut ctx Context) value(key string) !Val {
	return ctx.values[key]!
}

fn (ctx &Context) str() string {
	return ''
}

pub fn (mut ctx Context) get_db[T]() !T {
	unsafe {
		if ctx.app.db_pool != nil  {
			inst := ctx.app.db_pool.acquire()
			return T(inst)
		}
	}

	return error('db_pool not set')
}

pub fn (mut ctx Context) put_db(inst voidptr) {
	unsafe {
		if ctx.app.db_pool != nil  {
			ctx.app.db_pool.release(inst)
		}
	}
}

pub fn (mut ctx Context) next() ! {
	if ctx.is_stopped {
		return
	}
	ctx.mw_index++
	if ctx.mw_index == ctx.mws.len {
		ctx.handle()!
	} else {
		mw := ctx.mws[ctx.mw_index]
		mw(mut ctx)!
	}
}

pub fn (mut ctx Context) stop() {
	ctx.is_stopped = true
}

pub fn (mut ctx Context) is_stopped() bool {
	return ctx.is_stopped
}

pub fn (mut ctx Context) handle() ! {
	defer {
		ctx.sess.sync()
	}
	ctx.handler(mut ctx)!
}

pub fn (mut ctx Context) set_status(status_code http.Status) {
	ctx.resp.status_code = status_code.int()
	ctx.resp.status_msg = status_code.str()
}

pub fn (mut ctx Context) abort(status_code http.Status, msg ...string) {
	ctx.set_status(status_code)
	ctx.stop()

	if msg.len > 0 {
		ctx.resp.status_msg = msg[0]
	}
}

pub fn (mut ctx Context) json[T](result T) {
	ctx.resp.header.add(.content_type, 'application/json')
	ctx.resp.body = json.encode(result)
}

pub fn (mut ctx Context) json_pretty[T](result T) {
	ctx.resp.header.add(.content_type, 'application/json')
	ctx.resp.body = json.encode_pretty(result)
}

[inline]
pub fn (mut ctx Context) text(result string) {
	ctx.resp.body = result
}

[inline]
pub fn (mut ctx Context) bytes(result []byte) {
	ctx.resp.body = result.str()
}

pub fn (mut ctx Context) html(result string) {
	ctx.resp.header.set(.content_type, 'text/html')
	ctx.resp.body = result
}

[inline]
pub fn (mut ctx Context) redirect(url string) {
	ctx.resp.header.add(.location, url)
}

[inline]
pub fn (mut ctx Context) writer() &http.Response {
	return ctx.resp
}

pub fn (mut ctx Context) request() &Request {
	return ctx.req
}

[inline]
pub fn (mut ctx Context) param(key string) string {
	return ctx.params[key] or { '' }
}

[inline]
pub fn (mut ctx Context) set(key string, value Val) {
	ctx.values[key] = value
}

[inline]
pub fn (mut ctx Context) set_cookie(cookie http.Cookie) {
	ctx.resp.header.add(.set_cookie, cookie.str())
}

pub fn (mut ctx Context) body_parse[T]() !T {
	return ctx.req.body_parse[T]()
}

[inline]
pub fn (mut ctx Context) validate[T](data &T) ?[]IError {
	return validator.validate[T](data)
}
