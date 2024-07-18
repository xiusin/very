module builder

enum InsertType {
	insert
	insert_ignore
	insert_replace
}

pub fn (it InsertType) str() string {
	return match it {
		.insert {
			'INSERT'
		}
		.insert_ignore {
			'INSERT IGNORE'
		}
		.insert_replace {
			'REPLACE'
		}
	}
}

pub fn (builder &Builder) insert_sql() {}
