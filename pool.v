module very

import runtime

struct PoolChannel[T] {
mut:
	objs    chan T
	factory fn () T = unsafe { nil }
}

pub fn new_ch_pool[T](factory fn () T, size ...int) &PoolChannel[T] {
	cap := if size.len > 0 {
		size[0]
	} else {
		runtime.nr_jobs()
	}
	return &PoolChannel[T]{
		objs: chan T{cap: cap}
		factory: factory
	}
}

pub fn (mut p PoolChannel[T]) len() u32 {
	return p.objs.len
}

pub fn (mut p PoolChannel[T]) acquire() T {
	select {
		mut inst := <-p.objs {
			return inst
		}
		else {}
	}
	return p.factory()
}

pub fn (mut p PoolChannel[T]) release(inst T) {
	p.objs.try_push(voidptr(&inst))
}
