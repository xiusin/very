module very

import runtime

struct Pool {
mut:
	objs    chan voidptr
	factory fn () voidptr
}

// new_pool  函数创建一个新的池(Pool)对象，使用给定的大小和工厂函数。
// - size: 池的大小。
// - factory: 用于填充池的工厂函数。
// 返回值: &Pool
pub fn new_pool(size int, factory fn () voidptr) &Pool {
	return &Pool{
		objs: chan voidptr{cap: if size > 1 { size } else { runtime.nr_jobs() }}
		factory: factory
	}
}

pub fn (mut p Pool) len() u32 {
	ch := p.objs
	return ch.len
}

pub fn (mut p Pool) acquire() voidptr {
	select {
		mut inst := <-p.objs {
			dump('${ptr_str(inst)}')
			return inst
		}
		else {}
	}
	println('工厂函数获取实例')
	return p.factory()
}

pub fn (mut p Pool) release(inst voidptr) {
	p.objs.try_push(inst)
}
