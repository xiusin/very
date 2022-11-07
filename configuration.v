module very

[heap; noinit]
struct Configuration {
mut:
	port         int    = 8080
	session_name string = 'V_SESSION_ID'
}

pub fn default_configuration() Configuration {
	return Configuration{}
}

pub fn (mut conf Configuration) get_session_name() string {
	return conf.session_name
}

pub fn (mut conf Configuration) get_port() int {
	return conf.port
}
