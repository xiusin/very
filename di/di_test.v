module di

struct Person {
pub mut:
	name string
}

fn test_di() {
	nn := 'hello world'
	set('str', &nn)
	s1 := &string(get_voidptr('str')!)
	s2 := &string(get_voidptr('str')!)
	s3 := &string(get_voidptr('str1')!)
	assert s1 == s2
	println('s1 = ${ptr_str(s1)} - ${ptr_str(s2)}')

	inject_on(&Person{ name: 'xiusin' })
}
