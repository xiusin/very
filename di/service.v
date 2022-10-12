module di


pub struct Service {
	name string
mut:
	received bool
 	instance voidptr
	builder  fn (mut b Builder) voidptr
}

pub fn (mut s Service) get_instance(mut b Builder) voidptr {
		if !s.received {
			s.instance = s.builder(mut b)
			s.received = true
		}
		return s.instance
}
