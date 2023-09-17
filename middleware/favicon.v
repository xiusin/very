module middleware

import xiusin.very
import os

[params]
pub struct FaviconConfig {
pub mut:
	url           string = '/favicon.ico'
	data          []u8
	file          string
	typ           string = 'image/x-icon'
	cache_control string = 'public, max-age=31536000'
}

pub fn favicon(cfg FaviconConfig) very.Handler {
	mut conf := cfg
	if conf.data.len == 0 && conf.file.len > 0 {
		conf.data = os.read_bytes(conf.file) or { []u8{} }
	}

	return fn [mut conf] (mut ctx very.Context) ! {
		if ctx.req.path() != conf.url {
			ctx.next()!
			return
		}
		if conf.data.len == 0 && conf.file.len == 0 {
			ctx.set_status(.no_content)
		} else {
			mut header := ctx.writer().header
			header.set(.content_type, conf.typ)
			header.set(.cache_control, conf.cache_control)
			ctx.writer().header = header
			ctx.bytes(conf.data)
		}
		ctx.stop()
	}
}
