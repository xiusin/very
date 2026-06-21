module di

struct Counter {
mut:
	n int
}

interface Greeter {
	greet() string
}

struct EnglishGreeter {
	name string
}

fn (g EnglishGreeter) greet() string {
	return 'hello from ${g.name}'
}

// CallCounter is a heap-allocated helper to track factory invocations across a closure.
struct CallCounter {
mut:
	n int
}

fn test_singleton() {
	mut c := new_container()
	counter := &Counter{
		n: 0
	}
	c.register_singleton[&Counter](counter, 'counter')
	mut c1 := c.get[Counter]('counter')!
	c2 := c.get[Counter]('counter')!
	assert voidptr(c1) == voidptr(c2)
	c1.n = 5
	assert c2.n == 5
}

fn test_prototype() {
	mut c := new_container()
	c.register_factory[Counter](fn () &Counter {
		return &Counter{ n: 0 }
	}, .prototype, 'counter')
	mut c1 := c.get[Counter]('counter')!
	c2 := c.get[Counter]('counter')!
	assert voidptr(c1) != voidptr(c2)
	c1.n = 10
	assert c2.n == 0
}

fn test_lazy() {
	mut c := new_container()
	cc := &CallCounter{
		n: 0
	}
	c.register_lazy[Counter](fn [cc] () &Counter {
		unsafe { cc.n++ }
		return &Counter{ n: 0 }
	}, 'counter')
	assert unsafe { cc.n } == 0
	c1 := c.get[Counter]('counter')!
	assert unsafe { cc.n } == 1
	c2 := c.get[Counter]('counter')!
	assert unsafe { cc.n } == 1
	assert voidptr(c1) == voidptr(c2)
}

fn test_interface_binding() {
	mut c := new_container()
	impl := &EnglishGreeter{
		name: 'en'
	}
	c.bind_instance[Greeter](impl, 'greeter')
	g := c.get[Greeter]('greeter')!
	assert g.greet() == 'hello from en'
}

fn test_type_mismatch() {
	mut c := new_container()
	val := 42
	c.register_singleton[&int](&val, 'x')
	_ := c.get[&string]('x') or {
		assert err.msg().contains('mismatch')
		return
	}
	assert false, 'should have returned error'
}

fn test_request_container_isolation() {
	mut root := new_container()
	root_val := &Counter{
		n: 1
	}
	root.register_singleton[&Counter](root_val, 'x')

	mut child := root.create_request_container()
	child_val := &Counter{
		n: 2
	}
	child.register_singleton[&Counter](child_val, 'x')

	child_got := child.get[Counter]('x')!
	assert child_got.n == 2

	root_got := root.get[Counter]('x')!
	assert root_got.n == 1
}

fn test_parent_delegation() {
	mut root := new_container()
	root_val := &Counter{
		n: 99
	}
	root.register_singleton[&Counter](root_val, 'y')

	mut child := root.create_request_container()
	// child has no 'y', should delegate to parent
	got := child.get[Counter]('y')!
	assert got.n == 99
}

fn test_has_remove_clear() {
	mut c := new_container()
	val := &Counter{
		n: 1
	}
	c.register_singleton[&Counter](val, 'a')
	assert c.has('a')
	c.remove('a')
	assert !c.has('a')

	c.register_singleton[&Counter](val, 'b')
	c.register_singleton[&Counter](val, 'c')
	assert c.count() == 2
	c.clear()
	assert c.count() == 0
}

fn test_compat_inject_on() {
	mut c := default_container()
	c.clear()
	val := &Counter{
		n: 7
	}
	inject_on[&Counter](val, 'compat_counter')
	got := c.get[Counter]('compat_counter')!
	assert got.n == 7
	c.clear()
}

fn test_register_factory() {
	mut c := new_container()
	c.register_factory[Counter](fn () &Counter {
		return &Counter{ n: 42 }
	}, .singleton, 'factory_counter')
	got := c.get[Counter]('factory_counter')!
	assert got.n == 42
	// singleton: second get returns same instance
	got2 := c.get[Counter]('factory_counter')!
	assert voidptr(got) == voidptr(got2)
}
