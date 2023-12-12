module very

import time
import log

@[params]
pub struct Configuration {
mut:
	port                       int           = 8080
	app_name                   string        = 'very'
	session_name               string        = 'V_SESSION_ID'
	server_name                string        = 'xiusin/very'
	accept_timeout             time.Duration = time.second * 300
	read_timeout               time.Duration = time.second * 300
	write_timeout              time.Duration = time.second * 300
	idle_timeout               time.Duration = time.second * 300
	max_request_body_size      i64 = 1024 * 1024 * 20
	pre_parse_multipart_form   bool
	disable_keep_alive         bool = true
	enable_trusted_proxy_check bool
	trusted_proxies            []string
	enable_print_routes        bool
	disable_startup_message    bool
	strict_routing             bool
	logger_level               log.Level = log.Level.debug
	logger_path                string
}

@[inline]
pub fn default_configuration() Configuration {
	return Configuration{}
}

@[inline]
pub fn (mut conf Configuration) get_session_name() string {
	return conf.session_name
}

@[inline]
pub fn (mut conf Configuration) get_port() int {
	return conf.port
}
