module di

fn test_di() {
	mut ioc := new()
	nn := "hello world"
	ioc.set(Service{
		name: "service", 
		instance: &nn
	})

	info := *&string(ioc.get("service"))
	dump(info)
}
