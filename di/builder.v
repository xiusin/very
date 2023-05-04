module di

[head]
pub struct Builder {
mut:
	services shared map[string]Service
}

// set The reference type must be set
pub fn (mut b Builder) set(service Service) {
	lock b.services {
		b.services[service.name] = service
	}
}

pub fn (mut b Builder) get[T](name string) !&T {
	lock b.services {
		val := b.services[name].instance
		return unsafe { &T(val) }
	}

	return error('未找到服务${name}')
}
