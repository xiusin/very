module di


pub interface ServiceIntf {
	name string

	service_name() string
}

pub struct Service {
	name string
mut:
 	instance shared ServiceIntf
}
