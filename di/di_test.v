module di

fn test_di() {
	mut ioc := new()
	nn := "hello world"
	ioc.set(Service{ name: "service",  instance: &nn })
	info := ioc.get<string>("service")?
}
