module middleware

import xiusin.very
import compress.gzip

pub fn compress(mut ctx very.Context) ! {
	ctx.next()!

	if ctx.req.header.get(.accept_encoding)!.contains('gzip') {
		ctx.resp.header.delete(.content_length)
		ctx.resp.header.set(.content_encoding, 'gzip')
		ctx.resp.body = gzip.compress(ctx.resp.bytes())!.bytestr()
	}
}
