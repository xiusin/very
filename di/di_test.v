module di

fn test_di() {
	mut ioc := new()
	ioc.set("dumper", fn (mut b Builder) voidptr {
		str := "e1313123  cho dumper"
		return &str
	})

	a := ioc.get<string>("dumper") or {
		dump('${err}')
	}
	println(a)

}
