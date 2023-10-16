module middleware

import xiusin.very

pub fn powered_by(mut ctx very.Context) ! {
	ctx.next()!
	ctx.req.header.set_custom('X-Powered-By', 'Very')!
}
