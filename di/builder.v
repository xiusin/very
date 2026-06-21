module di

import v.reflection

// Box is an internal helper used to heap-allocate interface values so they can
// be stored as voidptr and later retrieved as &T.
struct Box[T] {
mut:
	val T
}

@[heap]
pub struct Container {
mut:
	beans  shared map[string]&Bean
	parent &Container = unsafe { nil }
}

pub fn new_container() &Container {
	return &Container{}
}

const default_container = new_container()

pub fn default_container() &Container {
	return default_container
}

// register_singleton registers a singleton instance directly.
pub fn (mut c Container) register_singleton[T](instance T, name ...string) {
	n := if name.len > 0 { name[0] } else { T.name }
	def := BeanDefinition{
		name:  n
		typ:   T.name
		scope: .singleton
	}
	mut vp := unsafe { nil }
	$if T is $interface {
		box := &Box[T]{
			val: instance
		}
		vp = voidptr(box)
	} $else {
		vp = voidptr(instance)
	}
	bean := new_bean(def, vp)
	lock c.beans {
		c.beans[n] = bean
	}
}

// register_factory registers a factory that creates instances.
// Use scope to control singleton vs prototype behaviour.
pub fn (mut c Container) register_factory[T](factory fn () &T, scope BeanScope, name ...string) {
	n := if name.len > 0 { name[0] } else { T.name }
	wrapped := fn [factory] [T]() voidptr {
		return unsafe { voidptr(factory()) }
	}
	def := BeanDefinition{
		name:    n
		typ:     T.name
		scope:   scope
		factory: wrapped
	}
	bean := new_bean(def, unsafe { nil })
	lock c.beans {
		c.beans[n] = bean
	}
}

// register_lazy registers a factory with lazy init (singleton scope, created on first get).
pub fn (mut c Container) register_lazy[T](factory fn () &T, name ...string) {
	n := if name.len > 0 { name[0] } else { T.name }
	wrapped := fn [factory] [T]() voidptr {
		return unsafe { voidptr(factory()) }
	}
	def := BeanDefinition{
		name:    n
		typ:     T.name
		scope:   .singleton
		factory: wrapped
		lazy:    true
	}
	bean := new_bean(def, unsafe { nil })
	lock c.beans {
		c.beans[n] = bean
	}
}

// bind_instance binds an interface to a concrete instance (registers under interface type name).
pub fn (mut c Container) bind_instance[T](instance T, name ...string) {
	n := if name.len > 0 { name[0] } else { T.name }
	def := BeanDefinition{
		name:  n
		typ:   T.name
		scope: .singleton
	}
	mut vp := unsafe { nil }
	$if T is $interface {
		box := &Box[T]{
			val: instance
		}
		vp = voidptr(box)
	} $else {
		vp = voidptr(instance)
	}
	bean := new_bean(def, vp)
	lock c.beans {
		c.beans[n] = bean
	}
}

// get retrieves a bean by name with type checking.
pub fn (mut c Container) get[T](name string) !&T {
	mut bean := &Bean(unsafe { nil })
	mut found := false
	lock c.beans {
		if name in c.beans {
			bean = unsafe { c.beans[name] }
			found = true
		}
	}
	if !found {
		if c.parent != unsafe { nil } {
			return c.parent.get[T](name)
		}
		return error('bean not found: ${name}')
	}

	// Type check (normalised: strip leading '&' so '&Foo' matches 'Foo')
	stored := bean.definition.typ
	requested := T.name
	stored_norm := if stored.starts_with('&') { stored[1..] } else { stored }
	requested_norm := if requested.starts_with('&') { requested[1..] } else { requested }
	if stored_norm != requested_norm {
		return error('bean type mismatch: expected ${requested}, got ${stored}')
	}

	def := bean.definition

	// Prototype: call factory each time, do NOT cache
	if def.scope == .prototype {
		if def.factory == unsafe { nil } {
			return error('prototype bean has no factory: ${name}')
		}
		instance := def.factory()
		if def.init_method != unsafe { nil } {
			def.init_method(instance)!
		}
		$if T is $interface {
			box := unsafe { &Box[T](instance) }
			return &box.val
		} $else {
			return unsafe { &T(instance) }
		}
	}

	// Singleton: create on first get if not yet initialized and a factory is present
	if !bean.initialized && def.factory != unsafe { nil } {
		instance := def.factory()
		if def.init_method != unsafe { nil } {
			def.init_method(instance)!
		}
		bean.instance = instance
		bean.initialized = true
	}

	// Return cached singleton instance
	$if T is $interface {
		box := unsafe { &Box[T](bean.instance) }
		return &box.val
	} $else {
		return unsafe { &T(bean.instance) }
	}
}

// get_or_default returns the bean value or a default if not found / type mismatch.
pub fn (mut c Container) get_or_default[T](name string, default_value T) T {
	res := c.get[T](name) or { return default_value }
	return unsafe { *res }
}

// has reports whether a bean with the given name exists (checking parent too).
pub fn (mut c Container) has(name string) bool {
	mut flag := false
	lock c.beans {
		flag = name in c.beans
	}
	if !flag && c.parent != unsafe { nil } {
		return c.parent.has(name)
	}
	return flag
}

// remove deletes a bean by name from this container.
pub fn (mut c Container) remove(name string) {
	lock c.beans {
		c.beans.delete(name)
	}
}

// clear removes all beans from this container.
pub fn (mut c Container) clear() {
	lock c.beans {
		keys := c.beans.keys()
		for k in keys {
			c.beans.delete(k)
		}
	}
}

// names returns the names of all beans in this container.
pub fn (mut c Container) names() []string {
	mut result := []string{}
	lock c.beans {
		result = c.beans.keys()
	}
	return result
}

// count returns the number of beans in this container.
pub fn (mut c Container) count() int {
	mut n := 0
	lock c.beans {
		n = c.beans.len
	}
	return n
}

// create_request_container creates a request-scoped child container (parent = this).
pub fn (mut c Container) create_request_container() &Container {
	return &Container{
		parent: unsafe { &c }
	}
}

// destroy calls deinit_method on all beans, then clears the container.
pub fn (mut c Container) destroy() {
	lock c.beans {
		for _, mut bean in c.beans {
			if bean.definition.deinit_method != unsafe { nil } {
				bean.definition.deinit_method(bean.instance) or {}
			}
		}
		keys := c.beans.keys()
		for k in keys {
			c.beans.delete(k)
		}
	}
}

// ---- Backward-compat methods (old Builder API) ----

// set registers a Service (Bean) - old API.
pub fn (mut c Container) set(service &Service) {
	lock c.beans {
		c.beans[service.definition.name] = unsafe { service }
	}
}

// exists reports whether a bean exists - old API (alias for has).
pub fn (mut c Container) exists(name string) bool {
	return c.has(name)
}

// get_voidptr returns the raw instance pointer - old API.
pub fn (mut c Container) get_voidptr(name string) !voidptr {
	service := c.get_service(name)!
	return service.instance
}

// get_service returns the Service (Bean) by name - old API.
pub fn (mut c Container) get_service(name string) !&Service {
	lock c.beans {
		if name in c.beans {
			return unsafe { c.beans[name] }
		}
	}
	if c.parent != unsafe { nil } {
		return c.parent.get_service(name)
	}
	return error('Unable to find service `${name}`')
}

// ---- Builder type alias (backward compat) ----

pub type Builder = Container

pub fn new_builder() &Builder {
	return unsafe { &Builder(new_container()) }
}

pub fn default_builder() &Builder {
	return unsafe { &Builder(default_container) }
}

// ---- Package-level compat functions (delegate to default container) ----

pub fn remove(name string) {
	mut c := default_container()
	c.remove(name)
}

pub fn exists(name string) bool {
	mut c := default_container()
	return c.exists(name)
}

pub fn get_voidptr(name string) !voidptr {
	mut c := default_container()
	return c.get_voidptr(name)
}

pub fn get[T](name string) !&T {
	mut c := default_container()
	return c.get[T](name)
}

// inject_on registers a singleton - old API.
pub fn inject_on[T](ptr T, names ...string) {
	if !T.name.starts_with('&') && reflection.type_of(ptr).sym.kind != reflection.VKind.interface {
		panic('argument must be of reference type.')
	}
	name := if names.len > 0 {
		names[0]
	} else {
		T.name
	}
	mut c := default_container()
	c.set(new_service(name, voidptr(ptr), T.name))
}
