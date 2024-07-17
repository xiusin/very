module builder

enum InsertType {
	insert         = 'INSERT'
	insert_ignore  = 'INSERT IGNORE'
	insert_replace = 'REPLACE'
}

pub fn (builder &Builder) insert_sql() {}
