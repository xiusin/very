module very

import runtime

pub struct PoolChannel[T] {
mut:
	objs    chan T
	factory fn () !T = unsafe { nil }
	release_failed_fn fn (mut inst T) = unsafe { nil }
}

pub fn new_ch_pool[T](factory fn () !T, size ...int) &PoolChannel[T] {
	cap := if size.len > 0 {
		size[0]
	} else {
		runtime.nr_jobs()
	}
	mut ch := &PoolChannel[T]{
		objs: chan T{cap: cap}
		factory: factory
	}

	for  i := 0; i < cap; i++ {
		ch.objs <- factory() or {  continue }
	}
	return ch
}

pub fn (mut p PoolChannel[T]) set_release_failed_fn(cb fn (mut inst T)) {
	unsafe {
		p.release_failed_fn = cb
	}
}

pub fn (mut p PoolChannel[T]) len() u32 {
	return p.objs.len
}

pub fn (p &PoolChannel[T]) acquire() !T {
	select {
		mut inst := <-p.objs {
			return inst
		}
		else {}
	}
	return p.factory()!
}

pub fn (p &PoolChannel[T]) release(inst T)  {
	if p.objs.try_push(voidptr(&inst)) != .success && !isnil(p.release_failed_fn) {
		unsafe {
			p.release_failed_fn(mut inst)
		}
	}
}
