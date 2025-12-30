module main

import xiusin.very
import xiusin.very.di
import json

[table: 'users']
pub struct User {
pub mut:
	id         int    [primary; sql: serial]
	username   string [required; sql_type: 'TEXT']
	password   string [required; sql_type: 'TEXT']
	created_at string [default: 'CURRENT_TIMESTAMP']
	updated_at string [default: 'CURRENT_TIMESTAMP']
	active     bool
}

[table: 'articles']
pub struct Article {
pub mut:
	id      int    [primary; sql: serial]
	title   string
	content string
	time    string
	tags    string
	star    bool
}

pub struct ApiResponse[T] {
	code int
	msg  string
	data T
}

[group: '/demo']
struct DemoController {
    very.Context
pub mut:
	userid int
}

['/success'; get]
pub fn (mut c DemoController) success() ! {
	if c.userid > 0 {
		c.ctx.text('success: exists')
	} else {
		c.userid = 1
		c.ctx.text('success set user_id = ${c.userid}')
	}
}

['/success1'; get]
pub fn (mut c DemoController) success1() ! {
	if c.userid > 0 {
		c.ctx.text('success1: exists')
	} else {
		c.userid = 2
		c.ctx.text('success1 set user_id = ${c.userid}')
	}
}

// 添加时间追踪功能
pub struct TimedContext {
	very.Context
	start_time f64
}

// 自定义错误处理中间件
fn custom_error_handler(mut ctx very.Context, err very.IError) ! {
	println('发生错误: ${err}')
	ctx.set_status(very.http.Status.internal_server_error)
	ctx.json(ApiResponse[string]{
		code: 500
		msg: '服务器内部错误'
		data: '${err}'
	})
}

fn main() {
	mut app := very.new(very.default_configuration())
	
	// 使用自定义错误处理器
	app.use_error_handler(custom_error_handler)
	
	// 添加日志中间件
	app.global_use(fn (mut ctx very.Context) ! {
		start_time := f64(very.time.now().nanosecond())
		println('请求: ${ctx.req.method.str()} ${ctx.req.url}')
		ctx.next()!
		end_time := f64(very.time.now().nanosecond())
		duration := (end_time - start_time) / 1000000.0  // 转换为毫秒
		println('响应: ${ctx.resp.status_code} 耗时: ${duration}ms')
	})
	
	// 创建API路由组
	mut api := app.group('/api')
	
	mut counter := 0
	
	api.get('/hello', fn [mut counter] (mut ctx very.Context) ! {
		ctx.json(ApiResponse[string]{
			code: 200
			msg: 'success'
			data: 'hello world: ${counter}'
		})
		counter++
	})
	
	// 演示路由参数
	api.get('/user/:id', fn (mut ctx very.Context) ! {
		uid := ctx.param('id')
		ctx.json(ApiResponse[User]{
			code: 200
			msg: 'success'
			data: User{
				id: uid.int()
				username: 'test_user_${uid}'
				password: 'encrypted_password'
				active: true
			}
		})
	})
	
	// 演示通配符路由
	api.get('/static/*filepath', fn (mut ctx very.Context) ! {
		filepath := ctx.param('filepath')
		ctx.text('访问静态文件: ${filepath}')
	})
	
	app.mount[DemoController]()
	
	// 添加默认的404处理
	app.not_found_handler = fn (mut ctx very.Context) ! {
		ctx.set_status(very.http.Status.not_found)
		ctx.json(ApiResponse[string]{
			code: 404
			msg: '请求的资源不存在'
			data: ''
		})
	}
	
	println('服务器启动在端口: ${app.cfg.get_port()}')
	app.run()
}