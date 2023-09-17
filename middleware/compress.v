module middleware

import xiusin.very
import os

pub fn compress(mut ctx very.Context) ! {
	ctx.next()!
}
