module validator

pub struct Test {
	username string @[validate: 'min=3,max=110,regexp=^\\d+$']
	age      int    @[validate: 'min=0,max=78']
	content  string @[validate: 'required']
	number   string @[validate: 'number']
	url      string @[validate: 'url']
}

pub struct TestRequired {
	count int  @[validate: 'required']
	price f64  @[validate: 'required']
	flag  bool @[validate: 'required']
}

pub struct TestNumber {
	age int @[validate: 'number']
}

pub struct TestMinMax {
	score f64 @[validate: 'min=1.5,max=10.5']
}

pub struct TestUnknown {
	no string @[validate: 'no_vad']
}

fn test_validate() {
	test := Test{
		username: 'xiusin'
		age:      100
		content:  '1'
		number:   '+1000'
		url:      'go1ogle.123'
	}
	errs := validate[Test](&test) or { []IError{} }
	// username 'xiusin' fails regexp=^\d+$ (not all digits)
	// age 100 fails max=78
	// number '+1000' fails number (regex ^[0-9]+$ does not match '+')
	// url 'go1ogle.123' is a valid URL, so url validator passes
	assert errs.len == 3
}

fn test_required_int() {
	// int 0 fails required
	t := TestRequired{
		count: 0
		price: 1.5
		flag:  true
	}
	errs := validate[TestRequired](&t) or { []IError{} }
	assert errs.len == 1
	assert '${errs[0]}'.contains('count')

	// non-zero int passes
	t2 := TestRequired{
		count: 5
		price: 1.5
		flag:  true
	}
	errs2 := validate[TestRequired](&t2) or { []IError{} }
	assert errs2.len == 0
}

fn test_required_f64() {
	// f64 0.0 fails required
	t := TestRequired{
		count: 5
		price: 0.0
		flag:  true
	}
	errs := validate[TestRequired](&t) or { []IError{} }
	assert errs.len == 1
	assert '${errs[0]}'.contains('price')

	// non-zero f64 passes
	t2 := TestRequired{
		count: 5
		price: 9.99
		flag:  true
	}
	errs2 := validate[TestRequired](&t2) or { []IError{} }
	assert errs2.len == 0
}

fn test_required_bool() {
	// bool is always valid for required, even when false
	t := TestRequired{
		count: 5
		price: 1.5
		flag:  false
	}
	errs := validate[TestRequired](&t) or { []IError{} }
	assert errs.len == 0
}

fn test_number_int() {
	// numeric types are always valid numbers
	t := TestNumber{
		age: 100
	}
	errs := validate[TestNumber](&t) or { []IError{} }
	assert errs.len == 0
}

fn test_min_max_f64() {
	// score < 1.5 fails min
	t := TestMinMax{
		score: 1.0
	}
	errs := validate[TestMinMax](&t) or { []IError{} }
	assert errs.len == 1

	// score > 10.5 fails max
	t2 := TestMinMax{
		score: 11.0
	}
	errs2 := validate[TestMinMax](&t2) or { []IError{} }
	assert errs2.len == 1

	// score in range passes
	t3 := TestMinMax{
		score: 5.0
	}
	errs3 := validate[TestMinMax](&t3) or { []IError{} }
	assert errs3.len == 0
}

fn test_unknown_validator() {
	t := TestUnknown{
		no: 'something'
	}
	errs := validate[TestUnknown](&t) or { []IError{} }
	assert errs.len == 1
	assert '${errs[0]}'.contains('no_vad')
}
