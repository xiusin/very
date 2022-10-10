module di

pub struct Builder  {
mut:
    services shared map[string]Service
}

pub fn new() Builder {
	return Builder {
		services:  map[string]Service{}
	}
}

pub fn (mut b Builder) set(service Service) {
	lock b.services {
		b.services[service.name] = service
	}
}


pub fn (mut b Builder) get(name string) voidptr {
	lock b.services {
		return b.services[name].instance 
	}

	return unsafe { nil }
}
