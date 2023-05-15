module di

// fn test_di() {
// 	mut ioc := new()
// 	nn := 'hello world'
// 	ioc.set(Service{ name: 'service', instance: &nn })
// 	info := ioc.get[string]('service')?
// }

pub struct Name {
pub mut:
	age string
}

pub struct Ba {
	Name
}
