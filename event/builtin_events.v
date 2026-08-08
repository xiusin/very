module event

// Built-in events

pub struct ServerStartEvent {
pub:
	port     int
	app_name string
}

pub fn (e ServerStartEvent) name() string {
	return 'ServerStart'
}

pub struct ServerShutdownEvent {}

pub fn (e ServerShutdownEvent) name() string {
	return 'ServerShutdown'
}

pub struct RequestStartEvent {
pub:
	method string
	path   string
}

pub fn (e RequestStartEvent) name() string {
	return 'RequestStart'
}

pub struct RequestEndEvent {
pub:
	method      string
	path        string
	status_code int
	duration_ms i64
}

pub fn (e RequestEndEvent) name() string {
	return 'RequestEnd'
}
