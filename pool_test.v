module main

import xiusin.very

struct Test {
	name string
}

fn pool_test() {
	mut i := 0
	mut pool := very.new_ch_pool[&Test](fn [mut i] () &Test {
		i += 1
		return &Test{
			name: 'name = ${i}'
		}
	})

	obj1 := pool.acquire()
	obj2 := pool.acquire()
	obj3 := pool.acquire()

	println('${ptr_str(obj1)}')
	println('${ptr_str(obj2)}')
	println('${ptr_str(obj3)}')
	pool.release(obj1)

	asset obj1 == pool.acquire()
	asset obj1 != pool.acquire()
}
