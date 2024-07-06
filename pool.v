module very

import runtime
import time

@[heap]
pub struct PoolCfg[T] {
pub:
	factory           fn () !T          = unsafe { nil }
	release_failed_fn fn (mut inst T)   = unsafe { nil }
	loop_fn           fn (mut inst T) ! = unsafe { nil }
	loop_duration     time.Duration     = time.second * 5
	size              int = runtime.nr_jobs()
}

pub struct PoolChannel[T] {
mut:
	objs chan T
	cfg  PoolCfg[T]
}

pub fn new_ch_pool[T](cfg PoolCfg[T]) &PoolChannel[T] {
	if isnil(cfg.factory) {
		panic('factory is nil')
	}

	mut ch := &PoolChannel[T]{
		objs: chan T{cap: cfg.size}
		cfg: cfg
	}

	if !isnil(cfg.loop_fn) {
		spawn fn [mut ch] [T]() {
			for {
				time.sleep(ch.cfg.loop_duration)
				mut inst := <-ch.objs
				ch.cfg.loop_fn(mut inst) or {
					println('${ptr_str(inst)} -> ${err}')
					if !isnil(ch.cfg.release_failed_fn) {
						unsafe {
							ch.cfg.release_failed_fn(mut inst)
						}
					}
					continue
				}
				ch.release(inst)
			}
		}()
	}

	return ch
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
	return p.cfg.factory()!
}

pub fn (p &PoolChannel[T]) release(inst T) {
	if p.objs.try_push(voidptr(&inst)) != .success && !isnil(p.cfg.release_failed_fn) {
		unsafe {
			p.cfg.release_failed_fn(mut inst)
		}
	}
}
