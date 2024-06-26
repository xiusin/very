module main

import xiusin.very

struct Test {}

fn main() {
	mut pool := very.new_ch_pool[&Test](fn () &Test {
		return &Test{}
	})

	obj1 := pool.acquire()
	obj2 := pool.acquire()
	obj3 := pool.acquire()

	println('${ptr_str(obj1)}')
	println('${ptr_str(obj2)}')
	println('${ptr_str(obj3)}')
	pool.release(obj1)

	obj4 := pool.acquire()

	println('obj1 = ${obj1}, obj4 = ${obj4}')
}
