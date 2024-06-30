module contracts

pub interface Tabler {
	table_name() string
}

pub interface QueryResultValueDecoder {
	decode(field string, value string) !
}
