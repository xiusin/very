module middleware

import xiusin.very
import compress.gzip

pub fn powered_by(mut ctx very.Context) ! {
	ctx.next()!
	ctx.req.header.set_custom('X-Powered-By', 'Very')!
}
