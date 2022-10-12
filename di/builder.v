module di

pub struct Builder  {
mut:
    services shared map[string]&Service
}

pub fn new() Builder {
	return Builder {
		services:  map[string]&Service{}
	}
}

pub fn (mut b Builder) set_service(service &Service) {
	lock b.services {
		b.services[service.name] = unsafe { service }
	}
}

pub fn (mut b Builder) set(name string, builder fn(b &Builder) voidptr) {
	b.set_service(&Service {
		name: name,
		builder: builder
	})
}

pub fn (mut b Builder) instance(name string, instance voidptr) {
	b.set_service(&Service {
		name: name,
		received: true
		instance: instance
	})
}

pub fn (mut b Builder) get<T>(name string) ?T {
		lock b.services {
			mut service := b.services[name] or {
				return error("service ${name} not register")
			}
			instance := service.get_instance(mut b)
			dump(&T(instance))
			dump(&T(instance))
			dump(&T(instance))
			dump(&T(instance))
			dump(&T(instance))
			return *&T(instance)
		}
		return error("get failed")
}
