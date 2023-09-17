module middleware

import xiusin.very
import compress.gzip

pub fn compress(mut ctx very.Context) ! {
	ctx.next()!

	if ctx.req.header.get(.accept_encoding)!.contains('gzip') {
		mut resp := ctx.writer()
		resp.header.delete(.content_length)
		resp.header.set(.content_encoding, 'gzip')
		resp.body = gzip.compress(ctx.writer().body.bytes())!.bytestr()
	}
}
