module di

pub interface AbstractBuilder {
	set(Service)
	exists(string) bool
	get_voidptr(string) !voidptr
}

const default_builder = new_builder() // like var, if not allow, we can use `__global`

[head]
pub struct Builder {
mut:
	services shared map[string]Service
}

pub fn new_builder() &Builder {
	return &Builder{}
}

pub fn default_builder() &Builder {
	return di.default_builder
}

// set The reference type must be set
pub fn (mut b Builder) set(service Service) {
	lock b.services {
		b.services[service.name] = service
	}
}

pub fn (mut b Builder) remove(name string) {
	lock b.services {
		b.services.delete(name)
	}
}

pub fn (mut b Builder) exists(name string) bool {
	mut flag := false
	lock b.services {
		flag = name in b.services
	}
	return flag
}

pub fn (mut b Builder) get_voidptr(name string) !voidptr {
	lock b.services {
		if name in b.services {
			return b.services[name].instance
		}
		return error('Unable to find service `${name}`, currently available services are: ${b.services.keys()}')
	}
	return error('Unable to find service `${name}`')
}

pub fn (mut b Builder) get[T](name string) !&T {
	return unsafe { T(b.get_voidptr(name)!) }
}

pub fn (mut b Builder) str() string {
	return ''
}

pub fn remove(name string) {
	mut builder := default_builder()
	builder.remove(name)
}

pub fn exists(name string) bool {
	mut builder := default_builder()
	return builder.exists(name)
}

pub fn set(name string, instance voidptr) {
	mut builder := default_builder()

	builder.set(Service{
		name: name
		instance: instance
	})
}

pub fn get_voidptr(name string) !voidptr {
	mut builder := default_builder()
	return builder.get_voidptr(name)
}

pub fn get[T](name string) !&T {
	mut builder := default_builder()
	return builder.get[T](name)
}

pub fn inject_on[T](ptr T) {
	if !T.name.starts_with('&') {
		panic('argument must be of reference type.')
	}

	mut builder := default_builder()
	builder.set(Service{
		name: T.name
		instance: ptr
	})
}
