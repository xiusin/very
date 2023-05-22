module very

import net.http
import net.urllib
import very.session
import json
import log
import very.di
import orm
import context
import time
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
pub:
	req http.Request
mut:
	mw_index   int = -1
	is_stopped bool
	resp       http.Response
	query      map[string]string
	form       map[string]string
	files      map[string][]http.FileData
	params     map[string]string
	err        IError = none
	values     map[string]Val = map[string]Val{}
	ctx        context.Context
	finished   chan int
pub mut:
	mws     []Handler
	handler Handler
	url     urllib.URL
	sess    session.Session
	logger  log.Log
	di      &di.Builder = unsafe { nil }
	db      orm.Connection
}

fn (ctx &Context) deadline() ?time.Time {
	return ctx.ctx.deadline()
}

pub fn (mut ctx Context) value(key string) !Val {
	return ctx.values[key]!
}

fn (ctx &Context) str() string {
	return ''
}

fn (mut ctx Context) done() chan int {
	return ctx.ctx.done()
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

pub fn (mut ctx Context) err() IError {
	return ctx.err
}

pub fn (mut ctx Context) get_custom_header(key string) !string {
	return ctx.req.header.get_custom(key)!
}

pub fn (mut ctx Context) get_header(key http.CommonHeader) !string {
	return ctx.req.header.get(key)!
}

pub fn (mut ctx Context) set_status(status_code http.Status) {
	ctx.resp.status_code = status_code.int()
}

pub fn (mut ctx Context) abort(status_code http.Status, msg ...string) {
	ctx.set_status(status_code)
	ctx.stop()
	if msg.len > 0 {
		ctx.resp.status_msg = msg[0]
	}
}

pub fn (mut ctx Context) is_ajax() bool {
	return ctx.req.header.custom_values('X-Requested-With').contains('XMLHttpRequest')
}

pub fn (mut ctx Context) json[T](result T) {
	ctx.resp.header.add(.content_type, 'application/json')
	ctx.resp.body = json.encode(result)
}

pub fn (mut ctx Context) text(result string) {
	ctx.resp.body = result
}

pub fn (mut ctx Context) bytes(result []byte) {
	ctx.resp.body = result.str()
}

pub fn (mut ctx Context) html(result string) {
	ctx.resp.header.set(.content_type, 'text/html')
	ctx.resp.body = result
}

pub fn (mut ctx Context) query(key string) string {
	return ctx.query[key] or { '' }
}

pub fn (mut ctx Context) add_query(key string, value string) {
	ctx.query[key] = value
}

pub fn (mut ctx Context) file(name string) ![]http.FileData {
	// http.parse_multipart_form()
	return ctx.files[name] or { return error('不存在上传文件') }
}

pub fn (mut ctx Context) form(name string) string {
	return ctx.form[name] or { '' }
}

pub fn (mut ctx Context) parse_form() ! {
	if ctx.form.len == 0 {
		ctx.form, ctx.files = parse_form_from_request(ctx.req) or { return err }
	}
}

pub fn (mut ctx Context) redirect(url string) {
	ctx.resp.header.add(.location, url)
}

pub fn (mut ctx Context) param(key string) string {
	return ctx.params[key] or { '' }
}

pub fn (mut ctx Context) referer() string {
	return ctx.req.header.get(.referer) or { '' }
}

pub fn (mut ctx Context) host() string {
	return ctx.url.host
}

pub fn (mut ctx Context) path() string {
	return ctx.url.path
}

pub fn (mut ctx Context) writer() &http.Response {
	return &ctx.resp
}

pub fn (mut ctx Context) set(key string, value Val) {
	ctx.values[key] = value
}

pub fn (mut ctx Context) set_cookie(cookie http.Cookie) {
	ctx.resp.header.add(.set_cookie, cookie.str())
}

pub fn (mut ctx Context) cookie(key string) !string {
	mut cookie_header := ctx.header(.cookie)
	cookie_header = ' ' + cookie_header
	cookie := if cookie_header.contains(';') {
		cookie_header.find_between(' ${key}=', ';')
	} else {
		cookie_header.find_between(' ${key}=', '\r')
	}
	if cookie != '' {
		return cookie.trim_space()
	}
	return error('Cookie not found')
}

pub fn (mut ctx Context) header(key http.CommonHeader) string {
	return ctx.req.header.get(key) or { '' }
}

pub fn (mut ctx Context) body_parse[T]() !T {
	if ctx.req.data.len > 0 {
		return json.decode(T, ctx.req.data)!
	}
	return T{}
}

pub fn (mut ctx Context) validate[T](data &T) ?[]IError {
	return validator.validate[T](data)
}

pub fn (mut ctx Context) client_ip() string {
	mut ip := ctx.req.header.get(.x_forwarded_for) or { '' }
	if ip == '' {
		ip = ctx.req.header.get_custom('X-Real-Ip') or { '' }
	}
	if ip.contains(',') {
		ip = ip.all_before(',')
	}

	// TODO 等待暴露 net conn
	if ip == '' {
		ip = ctx.req.header.get_custom('Remote-Addr') or { '' }
	}

	return ip
}
