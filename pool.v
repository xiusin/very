module very

struct Pool[T] {
mut:
	objs    shared []&T
	factory fn () &T
}

pub fn new_pool[T](factory fn () &T) &Pool[T] {
	return &Pool[T]{
		objs: []&T{}
		factory: factory
	}
}

pub fn (mut p Pool[T]) len() int {
	lock p.objs {
		return p.objs.len
	}

	return 0
}

pub fn (mut p Pool[T]) acquire() &T {
	lock p.objs {
		if p.objs.len > 0 {
			return &T(p.objs.pop())
		}
	}

	return p.factory()
}

pub fn (mut p Pool[T]) release(inst &T) {
	lock p.objs {
		p.objs << inst
	}
}
