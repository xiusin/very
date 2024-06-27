module builder

pub fn (b &Builder) where(param WhereParam, args ...Arg) &Builder {
	unsafe {
		match param {
			QueryCallBack {
				param(mut b)
			}
			string {
				// param.count('?')
			}
		}
		return b
	}
}
