module lark

import time
import net.http
import json

const (
	open_api_url = 'https://open.feishu.cn/open-apis'
)

pub struct Client {
	app_id     string
	app_secret string
mut:
	timer        time.Time
	expire       int
	access_token shared string
}

fn new_feishu_client(key string, secret string) ?Client {
	mut c := Client{
		app_secret: secret
		app_id: key
	}
	lock c.access_token {
		c.access_token = c.get_access_token()?
	}
	return c
}

fn (mut c Client) get_url(uri string) string {
	return lark.open_api_url + uri
}

fn (mut c Client) get_access_token() ?string {
	lock c.access_token {
		if c.access_token == '' || c.timer.add_seconds(c.expire) > time.now() {
			url := c.get_url('/auth/v3/app_access_token/internal')
			body := {
				'app_id':     c.app_id
				'app_secret': c.app_secret
			}

			res := http.post_json(url, json.encode(body)) or { return err }
			if res.status() != .ok {
				return error('请求认证接口错误')
			}

			ret := json.decode(AppAccessToken, res.body)?

			if ret.code != 0 {
				return error(ret.msg)
			}

			c.access_token = ret.app_access_token
			c.expire = ret.expire
			c.timer = time.now()
		}
	}
	return c.access_token
}
