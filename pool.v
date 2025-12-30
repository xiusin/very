module very

import sync

struct Pool {
mut:
	objs    []voidptr
	factory fn () voidptr
	mutex   sync.Mutex
}

pub fn new_pool(factory fn () voidptr) &Pool {
	return &Pool{
		objs: []voidptr{}
		factory: factory
		mutex: sync.new_mutex()
	}
}

pub fn (mut p Pool) len() int {
	p.mutex.lock()
	defer { p.mutex.unlock() }
	return p.objs.len
}

pub fn (mut p Pool) acquire() voidptr {
	p.mutex.lock()
	defer { p.mutex.unlock() }
	if p.objs.len > 0 {
		return p.objs.pop()
	}
	return p.factory()
}

pub fn (mut p Pool) release(inst voidptr) {
	p.mutex.lock()
	defer { p.mutex.unlock() }
	p.objs << inst
}

pub fn (mut p Pool) iter(cb fn (voidptr)) {
	p.mutex.lock()
	defer { p.mutex.unlock() }
	for obj in p.objs {
		cb(obj)
	}
}

pub fn (mut p Pool) clear() {
	p.mutex.lock()
	defer { p.mutex.unlock() }
	p.objs = []voidptr{}
}
