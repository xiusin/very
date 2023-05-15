module di

pub interface AbstractBuilder {
	set(Service)
	exists(string) bool
	get_voidptr(string) !voidptr
}

const default_builder = new_builder()

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
		return b.services[name].instance
	}
	return error('未找到服务${name}')
}

pub fn (mut b Builder) inject_on(ptr voidptr) {
}

pub fn (mut b Builder) get[T](name string) !&T {
	return unsafe { &T(b.get_voidptr(name)!) }
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

pub fn set(service Service) {
	mut builder := default_builder()
	builder.set(service)
}

pub fn get_voidptr(name string) !voidptr {
	mut builder := default_builder()
	return builder.get_voidptr(name)
}

pub fn get[T](name string) !&T {
	mut builder := default_builder()
	return builder.get[T](name)
}
