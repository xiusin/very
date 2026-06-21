module di

// BeanScope - Spring-like scopes
pub enum BeanScope {
	singleton // default: single instance shared across container
	prototype // new instance per get
	request   // per HTTP request (isolated in request child container)
}

// BeanDefinition - metadata describing how a bean is created and managed
pub struct BeanDefinition {
pub:
	name          string
	typ           string // type name string, e.g. '&sqlite.DB' or 'Foo'
	scope         BeanScope      = .singleton
	factory       fn () voidptr  = unsafe { nil } // for factory-registered beans
	init_method   fn (voidptr) ! = unsafe { nil } // post-construct hook
	deinit_method fn (voidptr) ! = unsafe { nil } // pre-destroy hook
	lazy          bool // if true, factory called on first get
	primary       bool // if multiple beans of same type, this one wins
}

// Bean - a managed instance with its definition
@[heap]
pub struct Bean {
pub:
	definition BeanDefinition
mut:
	instance    voidptr = unsafe { nil }
	initialized bool
}

pub fn new_bean(def BeanDefinition, instance voidptr) &Bean {
	return &Bean{
		definition:  def
		instance:    instance
		initialized: instance != unsafe { nil }
	}
}

// Compat: Service is an alias for Bean (backward compatibility)
pub type Service = Bean

pub fn new_service(name string, instance voidptr, typ string) &Service {
	def := BeanDefinition{
		name:  name
		typ:   typ
		scope: .singleton
	}
	return unsafe { &Service(new_bean(def, instance)) }
}

pub fn (s Service) get_instance() voidptr {
	return s.instance
}

pub fn (s Service) get_type() string {
	return s.definition.typ
}
