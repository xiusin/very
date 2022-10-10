module veb

struct Configuration {
mut:
	port         int    = 8080
	dbpath       string = 'database.db'
	session_name string = 'SESSION_ID'
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

pub fn (mut conf Configuration) get_dbpath() string {
	return conf.dbpath
}
