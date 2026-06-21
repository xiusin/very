module very

import runtime

// PoolChannel is a generic channel-based pool.
//
// Note: `factory` is stored as `fn () voidptr` (wrapped at construction time)
// instead of `fn () !T` to work around a V 0.5.1 type-inference bug that
// prevents returning `!&T` from a generic function when `T` is a pointer
// type defined in the same module as a consumer (e.g. `&Context` in `app.v`).
pub struct PoolChannel[T] {
mut:
	objs    chan voidptr
	factory fn () voidptr = unsafe { nil }
pub mut:
	test_on_borrow fn (it T) ! = unsafe { nil }
}

pub fn new_ch_pool[T](factory fn () !T, size ...int) &PoolChannel[T] {
	cap := if size.len > 0 {
		size[0]
	} else {
		runtime.nr_jobs()
	}
	// Wrap the user-supplied `!T` factory into a `voidptr`-returning closure.
	wrapped := fn [factory] [T] () voidptr {
		r := factory() or { return unsafe { nil } }
		return voidptr(r)
	}
	return &PoolChannel[T]{
		objs:    chan voidptr{cap: cap}
		factory: wrapped
	}
}

pub fn (mut p PoolChannel[T]) len() u32 {
	return p.objs.len
}

// acquire returns an instance from the pool, or creates a new one via the
// factory when the pool is empty.
pub fn (mut p PoolChannel[T]) acquire() !T {
	select {
		inst := <-p.objs {
			mut t := unsafe { *(&T(&inst)) }
			if !isnil(p.test_on_borrow) {
				// 无法测试通过，丢弃连接重新拿实例
				p.test_on_borrow(t) or {
					new_inst := p.factory()
					if isnil(new_inst) {
						return error('pool factory failed')
					}
					return unsafe { *(&T(&new_inst)) }
				}
			}
			return t
		}
		else {}
	}
	new_inst := p.factory()
	if isnil(new_inst) {
		return error('pool factory failed')
	}
	return unsafe { *(&T(&new_inst)) }
}

pub fn (mut p PoolChannel[T]) release(inst T) {
	p.objs.try_push(voidptr(&inst))
}
