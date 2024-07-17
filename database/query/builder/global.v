module builder

import json

pub fn new_query_builder() &Builder {
	return &Builder{}
}

pub fn query() &Builder {
	return new_query_builder()
}

pub fn table(table TableName, alias ...string) &Builder {
	return new_query_builder().table(table, ...alias)
}

pub fn insert(raw string, args ...Arg) !int {
	return 0
	// _ = client.exec_param_many(raw, Args(args).to_strings())!
	// return client.last_id()
}

pub fn update(raw string, args ...Arg) !u64 {
	return 0
	// client := client_()!
	// _ = client.exec_param_many(raw, Args(args).to_strings())!
	// client.use_result()
	// return client.affected_rows()
}

pub fn delete(raw string, args ...Arg) !u64 {
	return 0
	// client := client_()!
	// _ = client.exec_param_many(raw, Args(args).to_strings())!
	// return client.affected_rows() // TODO 无法获取影响行数
}

pub fn select_as_maps(raw string, alias ...Arg) ![]map[string]string {
	return []map[string]string{}
	// mut client := client_()!
	// result := client.real_query(raw)!
	// defer {
	// 	unsafe {
	// 		result.free()
	// 	}
	// 	client.close()
	// }
	// return result.maps()
}

pub fn @select[T](raw string, alias ...Arg) ![]T {
	mut receiver := []T{}
	for _, row in select_as_maps(raw, ...alias)! {
		mut item := T{}
		$for field in T.fields {
			if field.name in row {
				$if field.is_option {
					if row[field.name] == '' {
						item.$(field.name) = none
					} else {
						$if field.typ is ?string {
							item.$(field.name) = row[field.name]
						} $else $if field.typ is ?int {
							item.$(field.name) = row[field.name].int()
						} $else $if field.typ is ?i8 {
							item.$(field.name) = row[field.name].i8()
						} $else $if field.typ is ?i64 {
							item.$(field.name) = row[field.name].i64()
						} $else $if field.typ is ?i16 {
							item.$(field.name) = row[field.name].i16()
						} $else $if field.typ is ?bool {
							item.$(field.name) = row[field.name].bool()
						} $else $if field.typ is ?f64 {
							item.$(field.name) = row[field.name].f64()
						} $else $if field.typ is ?f32 {
							item.$(field.name) = row[field.name].f32()
						} $else $if field.typ is ?u64 {
							item.$(field.name) = row[field.name].u64()
						} $else $if field.typ is ?u8 {
							item.$(field.name) = row[field.name].u8()
						} $else $if field.typ is ?u16 {
							item.$(field.name) = row[field.name].u16()
						} $else $if field.typ is ?u32 {
							item.$(field.name) = row[field.name].u32()
						} $else {
							$for method in T.methods {
								$if method.name == 'decode' {
									item.$method(field.name, row[field.name]) or { return err }
								}
							}
						}

						$if field.typ is ?[]string {
							item.$(field.name) = parse_result_arr_item[string](row[field.name])
						} $else $if field.typ is ?[]int {
							item.$(field.name) = parse_result_arr_item[int](row[field.name])
						} $else $if field.typ is ?[]i8 {
							item.$(field.name) = parse_result_arr_item[i8](row[field.name])
						} $else $if field.typ is ?[]i64 {
							item.$(field.name) = parse_result_arr_item[i64](row[field.name])
						} $else $if field.typ is ?[]i16 {
							item.$(field.name) = parse_result_arr_item[i16](row[field.name])
						} $else $if field.typ is ?[]bool {
							item.$(field.name) = parse_result_arr_item[bool](row[field.name])
						} $else $if field.typ is ?[]f64 {
							item.$(field.name) = parse_result_arr_item[f64](row[field.name])
						} $else $if field.typ is ?[]f32 {
							item.$(field.name) = parse_result_arr_item[f32](row[field.name])
						} $else $if field.typ is ?[]u64 {
							item.$(field.name) = parse_result_arr_item[u64](row[field.name])
						} $else $if field.typ is ?[]u8 {
							item.$(field.name) = parse_result_arr_item[u8](row[field.name])
						} $else $if field.typ is ?[]u16 {
							item.$(field.name) = parse_result_arr_item[u16](row[field.name])
						} $else $if field.typ is ?[]u32 {
							item.$(field.name) = parse_result_arr_item[u32](row[field.name])
						}
					}
				} $else {
					$if field.typ is string {
						item.$(field.name) = row[field.name]
					} $else $if field.typ is int {
						item.$(field.name) = row[field.name].int()
					} $else $if field.typ is i8 {
						item.$(field.name) = row[field.name].i8()
					} $else $if field.typ is i64 {
						item.$(field.name) = row[field.name].i64()
					} $else $if field.typ is i16 {
						item.$(field.name) = row[field.name].i16()
					} $else $if field.typ is bool {
						item.$(field.name) = row[field.name].bool()
					} $else $if field.typ is f64 {
						item.$(field.name) = row[field.name].f64()
					} $else $if field.typ is f32 {
						item.$(field.name) = row[field.name].f32()
					} $else $if field.typ is u64 {
						item.$(field.name) = row[field.name].u64()
					} $else $if field.typ is u8 {
						item.$(field.name) = row[field.name].u8()
					} $else $if field.typ is u16 {
						item.$(field.name) = row[field.name].u16()
					} $else $if field.typ is u32 {
						item.$(field.name) = row[field.name].u32()
					} $else {
						$for method in T.methods {
							$if method.name == 'decode' {
								item.$method(field.name, row[field.name]) or { return err }
							}
						}
					}

					$if field.typ is []string {
						item.$(field.name) = parse_result_arr_item[string](row[field.name])
					} $else $if field.typ is []int {
						item.$(field.name) = parse_result_arr_item[int](row[field.name])
					} $else $if field.typ is []i8 {
						item.$(field.name) = parse_result_arr_item[i8](row[field.name])
					} $else $if field.typ is []i64 {
						item.$(field.name) = parse_result_arr_item[i64](row[field.name])
					} $else $if field.typ is []i16 {
						item.$(field.name) = parse_result_arr_item[i16](row[field.name])
					} $else $if field.typ is []bool {
						item.$(field.name) = parse_result_arr_item[bool](row[field.name])
					} $else $if field.typ is []f64 {
						item.$(field.name) = parse_result_arr_item[f64](row[field.name])
					} $else $if field.typ is []f32 {
						item.$(field.name) = parse_result_arr_item[f32](row[field.name])
					} $else $if field.typ is []u64 {
						item.$(field.name) = parse_result_arr_item[u64](row[field.name])
					} $else $if field.typ is []u8 {
						item.$(field.name) = parse_result_arr_item[u8](row[field.name])
					} $else $if field.typ is []u16 {
						item.$(field.name) = parse_result_arr_item[u16](row[field.name])
					} $else $if field.typ is []u32 {
						item.$(field.name) = parse_result_arr_item[u32](row[field.name])
					}
				}
			}
		}
		receiver << item
	}

	return receiver
}

fn parse_result_arr_item[T](value string) []T {
	return json.decode([]T, value) or { []T{} }
}
