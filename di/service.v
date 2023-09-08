module di

pub struct Service {
	name string
	typ  string
mut:
	instance voidptr
}

pub fn new_service(name string, instance voidptr, typ string) &Service {
	return &Service{
		name: name
		instance: instance
		typ: typ
	}
}

pub fn (s Service) get_instance() voidptr {
	return s.instance
}

pub fn (s Service) get_type() string {
	return s.typ
}
