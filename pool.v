module very

struct Pool {
mut:
	objs    shared []voidptr
	factory fn () voidptr
}

pub fn new_pool(factory fn () voidptr) &Pool {
	return &Pool{
		objs: []voidptr{}
		factory: factory
	}
}

pub fn (mut p Pool) len() int {
	lock p.objs {
		return p.objs.len
	}

	return 0
}

pub fn (mut p Pool) acquire() voidptr {
	lock p.objs {
		if p.objs.len > 0 {
			return p.objs.pop()
		}
	}

	return p.factory()
}

pub fn (mut p Pool) release(inst voidptr) {
	lock p.objs {
		p.objs << inst
	}
}

pub fn (mut p Pool) iter(cb fn (voidptr)) {
	lock p.objs {
		for obj in p.objs {
			cb(obj)
		}
	}
}

pub fn (mut p Pool) clear() {
	lock p.objs {
		p.objs = []voidptr{}
	}
}
