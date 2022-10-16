module dto

pub struct ArticleDto {
pub:
	id         	int    [required]
	title 		string [required]
	content 	string [required]
	time 		string [required]
	tags 		string
	star     	bool   [required]
}
