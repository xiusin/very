module veb

import net.http
import net.urllib
import json
import log

pub type Val = int | string | i64 | i8  | u8 | u64 | f64 | nil | rune | byte | []string | []int | []i64 | []byte | []rune | []f64

pub struct Context {
pub:
	req 		http.Request
mut:
	mw_index 	int = -1
	is_stopped 	bool
	resp 		http.Response
	query 		map[string]string
	form  		map[string]string
	files		map[string][]http.FileData
	params		map[string]string
	values 		map[string]Val
pub mut:
	mws 		[]VebHandler
	handler 	VebHandler
	url 		urllib.URL
	sess  		Session
	logger    	log.Log
	db     		Orm
}

pub fn (mut ctx Context) next() {
	if ctx.is_stopped {
		return
	}
	ctx.mw_index++
	if ctx.mw_index == ctx.mws.len {
		ctx.handle()
	} else {
		ctx.mws[ctx.mw_index](mut ctx)
	}
}

pub fn (mut ctx Context) stop() {
	ctx.is_stopped = true
}

pub fn (mut ctx Context) is_stopped() bool {
	return ctx.is_stopped
}

pub fn (mut ctx Context) handle() {
	defer {
		ctx.sess.sync()
	}
	ctx.handler(mut ctx)
}

pub fn (mut ctx Context) set_status(status_code int) {
	ctx.resp.status_code = status_code
}

pub fn (mut ctx Context) abort(status_code int, msg ... string) {
	ctx.set_status(status_code)
	ctx.stop()
	if msg.len > 0 {
		ctx.resp.status_msg = msg[0]
	}
}

pub fn (mut ctx Context) is_ajax() bool {
	return ctx.req.header.custom_values('X-Requested-With').contains('XMLHttpRequest')
}

pub fn (mut ctx Context) json<T>(result T) {
	ctx.resp.header.add(.content_type, "application/json")
	ctx.resp.body = json.encode(result)
}

pub fn (mut ctx Context) text(result string) {
	ctx.resp.body = result
}

pub fn (mut ctx Context) bytes(result []byte) {
	ctx.resp.body = result.str()
}

pub fn (mut ctx Context) html(result string) {
	ctx.resp.header.add(.content_type, "text/html")
	ctx.resp.body = result
}

pub fn(mut ctx Context) query(key string) string {
	return ctx.query[key] or { '' }
}

pub fn (mut ctx Context) file(name string) ?[]http.FileData  {
	// http.parse_multipart_form()
	return ctx.files[name] or {
		return error("不存在上传文件")
	}
}

pub fn (mut ctx Context) form(name string) string {
	return ctx.form[name] or { '' }
}

pub fn (mut ctx Context) parse_form() ? {
	if ctx.form.len == 0 {
		ctx.form, ctx.files = parse_form_from_request(ctx.req) or {
			return err
		}
	}
}

pub fn (mut ctx Context) redirect(url string) {
	ctx.resp.header.add(.location, url)
}

pub fn (mut ctx Context) param(key string) string {
	return ctx.params[key] or  { '' }
}

pub fn (mut ctx Context) host() string {
	return ctx.url.host
}

pub fn (mut ctx Context) path() string {
	return ctx.url.path
}

pub fn (mut ctx Context) writer() &http.Response  {
	return &ctx.resp
}

pub fn (mut ctx Context) set(key string, value Val) {
	ctx.values[key] = value
}

pub fn (mut ctx Context) value(key string) Val {
	return ctx.values[key] or { unsafe { nil } }
}

pub fn (mut ctx Context) set_cookie(cookie http.Cookie) {
	ctx.resp.header.add(.set_cookie, cookie.str())
}

pub fn (mut ctx Context) cookie(key string) ?string {
	mut cookie_header := ctx.header(.cookie)
	cookie_header = ' ' + cookie_header
	cookie := if cookie_header.contains(';') {
		cookie_header.find_between(' $key=', ';')
	} else {
		cookie_header.find_between(' $key=', '\r')
	}
	if cookie != '' {
		return cookie.trim_space()
	}
	return error('Cookie not found')
}

pub fn (mut ctx Context) header(key http.CommonHeader) string {
	return ctx.req.header.get(key) or { '' }
}

pub fn (mut ctx Context)body_parse<T>() ?T {
	return json.decode(T, ctx.req.data)
}

pub fn (mut ctx Context) client_ip() string {
	mut ip := ctx.req.header.get(.x_forwarded_for) or { '' }
	if ip == '' {
		ip = ctx.req.header.get_custom('X-Real-Ip') or { '' }
	}
	if ip.contains(',') {
		ip = ip.all_before(',')
	}

	// todo 等待暴露netconn

	return ip
}