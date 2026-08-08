module very

import runtime

// PoolChannel is a generic channel-based pool.
//
// Note: The factory is stored as `fn () !T`, but `acquire()` calls it through
// `call_factory_voidptr()` (which returns `voidptr`) to work around a V 0.5.1
// bug that prevents returning `!&T` from a generic function when `T` is a
// pointer type.
pub struct PoolChannel[T] {
mut:
	objs    chan voidptr
	factory fn () !T = unsafe { nil }
pub mut:
	test_on_borrow fn (it T) ! = unsafe { nil }
}

pub fn new_ch_pool[T](factory fn () !T, size ...int) &PoolChannel[T] {
	cap := if size.len > 0 {
		size[0]
	} else {
		runtime.nr_jobs()
	}
	return &PoolChannel[T]{
		objs:    chan voidptr{cap: cap}
		factory: factory
	}
}

pub fn (mut p PoolChannel[T]) len() u32 {
	return p.objs.len
}

// call_factory_voidptr invokes the factory and returns the result as voidptr,
// or nil on error. This avoids the V 0.5.1 `!&T` return bug.
fn (mut p PoolChannel[T]) call_factory_voidptr() voidptr {
	r := p.factory() or { return unsafe { nil } }
	return voidptr(r)
}

// acquire returns an instance from the pool, or creates a new one via the
// factory when the pool is empty.
pub fn (mut p PoolChannel[T]) acquire() !T {
	select {
		inst := <-p.objs {
			mut t := unsafe { *(&T(&inst)) }
			if !isnil(p.test_on_borrow) {
				p.test_on_borrow(t) or {
					vp := p.call_factory_voidptr()
					if isnil(vp) {
						return error('pool factory failed')
					}
					return unsafe { *(&T(&vp)) }
				}
			}
			return t
		}
		else {}
	}
	vp := p.call_factory_voidptr()
	if isnil(vp) {
		return error('pool factory failed')
	}
	return unsafe { *(&T(&vp)) }
}

pub fn (mut p PoolChannel[T]) release(inst T) {
	p.objs.try_push(voidptr(&inst))
}
