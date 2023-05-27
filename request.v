module very

import net.http
import net.urllib
import json

pub struct Request {
	http.Request
mut:
	form  map[string]string
	files map[string][]http.FileData
	url   urllib.URL
	query map[string]string
}

pub fn new_request(req &http.Request, url urllib.URL) &Request {
	return &Request{
		Request: req
		url: url
		query: http.parse_form(url.raw_query)
	}
}

[inline]
pub fn (mut req Request) get_custom_header(key string) !string {
	return req.header.get_custom(key)!
}

[inline]
pub fn (mut req Request) get_header(key http.CommonHeader) !string {
	return req.header.get(key)!
}

[inline]
pub fn (mut req Request) is_ajax() bool {
	return req.header.custom_values('X-Requested-With').contains('XMLHttpRequest')
}

[inline]
pub fn (mut req Request) referer() string {
	return req.header.get(.referer) or { '' }
}

[inline]
pub fn (mut req Request) host() string {
	return req.url.host
}

[inline]
pub fn (mut req Request) path() string {
	return req.url.path
}

[inline]
pub fn (mut req Request) query(key string) string {
	return req.query[key] or { '' }
}

[inline]
pub fn (mut req Request) add_query(key string, value string) {
	req.query[key] = value
}

[inline]
pub fn (mut req Request) file(name string) ![]http.FileData {
	return req.files[name] or { return error('have no upload file ${name}.') }
}

[inline]
pub fn (mut req Request) form(name string) string {
	return req.form[name] or { '' }
}

pub fn (mut req Request) parse_form() ! {
	if req.form.len == 0 {
		req.form, req.files = req.parse_form_from_request() or { return err }
	}
}

pub fn (mut req Request) cookie(key string) !string {
	mut cookie_header := req.get_header(.cookie)!
	cookie_header = ' ' + cookie_header
	cookie := if cookie_header.contains(';') {
		cookie_header.find_between(' ${key}=', ';')
	} else {
		cookie_header.find_between(' ${key}=', '\r')
	}
	if cookie != '' {
		return cookie.trim_space()
	}
	return error('cookie not found')
}

fn (mut req Request) parse_form_from_request() !(map[string]string, map[string][]http.FileData) {
	mut form := map[string]string{}
	mut files := map[string][]http.FileData{}
	if req.method in [http.Method.post, .put, .patch] {
		ct := req.header.get(.content_type) or { '' }.split(';').map(it.trim_left(' \t'))
		if 'multipart/form-data' in ct {
			boundary := ct.filter(it.starts_with('boundary='))
			if boundary.len != 1 {
				return error('detected more that one form-data boundary')
			}
			form, files = http.parse_multipart_form(req.data, boundary[0][9..])
		} else {
			form = http.parse_form(req.data)
		}
	}
	return form, files
}

pub fn (mut req Request) client_ip() string {
	mut ip := req.header.get(.x_forwarded_for) or { '' }
	if ip == '' {
		ip = req.header.get_custom('X-Real-Ip') or { '' }
	}
	if ip.contains(',') {
		ip = ip.all_before(',')
	}
	if ip == '' {
		ip = req.header.get_custom('Remote-Addr') or { '' }
	}
	return ip
}

pub fn (mut req Request) body_parse[T]() !T {
	if req.data.len > 0 {
		return json.decode(T, req.data)!
	}
	return T{}
}
