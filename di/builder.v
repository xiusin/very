module di

[head]
pub struct Builder {
mut:
	services shared map[string]Service
}

// 必须设置引用类型
pub fn (mut b Builder) set(service Service) {
	lock b.services {
		b.services[service.name] = service
	}
}

pub fn (mut b Builder) get<T>(name string) ?&T {
	lock b.services {
		val := b.services[name].instance
		match val {
			T { return val } 
			else {}
		}
	}
	
	return error("未找到服务${name}")
}
