module very

import runtime

struct PoolChannel[T] {
mut:
	objs    chan T
	factory fn () T = unsafe { nil }
}

pub fn new_ch_pool[T](factory fn () T) &PoolChannel[T] {
	return &PoolChannel[T]{
		objs: chan T{cap: runtime.nr_jobs()}
		factory: factory
	}
}

pub fn (mut p PoolChannel[T]) len() u32 {
	return p.objs.len
}

pub fn (mut p PoolChannel[T]) acquire() T {
	select {
		mut inst := <-p.objs {
			println('acquire a inst -> ${ptr_str(inst)}')
			return inst
		}
		else {}
	}
	return p.factory()
}

pub fn (mut p PoolChannel[T]) release(inst voidptr) {
	p.objs.try_push(inst)
}
