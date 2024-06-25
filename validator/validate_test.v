module validator

import os

pub struct Test {
	username string @[validate: 'min=3,max=110,regexp=^\\d+$']
	age      int    @[validate: 'min=0,max=78']
	content  string @[validate: 'required']
	number   string @[validate: 'number']
	url      string @[validate: 'url']
	no      string @[validate: 'no_vad']
}

fn test_test() {
	test := Test{
		username: 'xiusin'
		age: 100
		content: '1'
		number: '+1000'
		url: 'go1ogle.123'
	}
	errs := validate[Test](test)
	if errs != none {
		mut err_slice := []string{}
		for _, err in errs {
			err_slice << '${err}'
		}
		os.write_lines('valitor.log', err_slice) or {}
	}
}
