module very

import time

// 性能基准测试
pub fn benchmark_router_performance() {
	mut app := new(default_configuration())
	
	// 注册多个路由用于测试
	for i := 0; i < 1000; i++ {
		path := '/test/${i}'
		app.get(path, fn (mut ctx Context) ! {
			ctx.text('Hello World!')
		})
	}
	
	// 性能测试
	start_time := time.now()
	
	// 模拟多次路由查找
	for i := 0; i < 10000; i++ {
		test_path := 'GET;/test/${i % 1000}'
		node, _, ok := app.trier.find(test_path)
		if ok {
			// 模拟处理
			_ = node
		}
	}
	
	end_time := time.now()
	elapsed := end_time - start_time
	
	println('路由查找 10000 次耗时: ${elapsed}ms')
	println('平均每次路由查找: ${(elapsed.f64() / 10000.0)}ms')
}

pub fn benchmark_context_pool_performance() {
	mut app := new(default_configuration())
	
	// 性能测试
	start_time := time.now()
	
	// 模拟多次Context获取和释放
	for i := 0; i < 100000; i++ {
		ctx := app.pool.acquire().(Context)
		// 模拟使用Context
		ctx.reset(unsafe { nil }, unsafe { nil })
		app.pool.release(ctx)
	}
	
	end_time := time.now()
	elapsed := end_time - start_time
	
	println('Context池获取/释放 100000 次耗时: ${elapsed}ms')
	println('平均每次Context池操作: ${(elapsed.f64() / 100000.0)}ms')
}

fn main() {
	println('开始性能基准测试...')
	benchmark_router_performance()
	benchmark_context_pool_performance()
	println('性能基准测试完成!')
}