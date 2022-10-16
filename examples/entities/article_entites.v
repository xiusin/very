module entities

[table: 'articles']
pub struct Article {
pub mut:
	id         	int    [primary; sql: serial]
	title 		string
	content 	string
	time 		string
	tags 		string
	star     	bool
}
