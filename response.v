module very

import net.http

pub struct Response {
	http.Response
}

pub fn (mut resp Response) to_http_response() http.Response {
	http_resp := resp.Response
	return http_resp
}

pub fn new_response(cfg Configuration) &Response {
	mut resp := &Response{
		Response: http.new_response(http.ResponseConfig{})
	}
	if cfg.server_name.len > 0 {
		resp.header.set(.server, cfg.server_name)
	}
	resp.header.set(.connection, 'close')
	return resp
}
