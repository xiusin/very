module middleware

import xiusin.very
import time

@[params]
pub struct CorsOption {
pub mut:
	allow_origin      string = '*'
	allow_credentials bool
	allow_methods     []string = ['GET', 'HEAD', 'PUT', 'POST', 'DELETE', 'PATCH']
	allow_headers     []string
	max_age           time.Duration
	expose_headers    []string
}

pub fn cors(opt CorsOption) very.Handler {
	return fn [opt] (mut ctx very.Context) ! {
		mut header := ctx.writer().header

		if opt.allow_origin != '*' {
			header.set(.vary, 'Origin')
			header.set(.access_control_allow_origin, opt.allow_origin)
		}

		if opt.allow_credentials {
			header.set(.access_control_allow_credentials, 'true')
		}

		if opt.expose_headers.len > 0 {
			header.set(.access_control_expose_headers, opt.expose_headers.join(','))
		}

		ctx.writer().header = header
		if ctx.req.method.str() != 'OPTIONS' {
			ctx.next()!
		} else {
			if opt.max_age > 0 {
				header.set(.access_control_max_age, opt.max_age.seconds().str())
			}

			if opt.allow_methods.len > 0 {
				header.set(.access_control_allow_methods, opt.allow_methods.join(','))
			}

			if opt.allow_headers.len > 0 {
				header.set(.access_control_allow_headers, opt.allow_headers.join(','))
				header.add(.vary, 'Access-Control-Request-Headers')
			}

			header.delete(.content_length)
			header.delete(.content_type)
			ctx.stop()
		}
	}
}
