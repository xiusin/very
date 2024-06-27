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

	println('obj1 = ${ptr_str(obj1)}, obj4 = ${ptr_str(obj4)}  eq: ${obj1 == obj4}')
	obj5 := pool.acquire()
	println('obj1 = ${ptr_str(obj1)}, obj5 = ${ptr_str(obj5)}  eq: ${obj1 == obj5}')
}
