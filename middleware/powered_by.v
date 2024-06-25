module middleware

import xiusin.very

pub fn powered_by(mut ctx very.Context) ! {
	ctx.next()!
	ctx.resp.header.set_custom('X-Powered-By', 'xiusin/very')!
}
