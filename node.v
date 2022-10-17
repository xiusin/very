module veb

import regex

struct Node {
mut:
	val      	string
	path    	string
	param_name  string
	params     	map[string]string
	term     	bool
	depth    	int
	is_group 	bool
	children 	map[string]&Node
	is_pattern  bool
	re 			&regex.RE = unsafe { nil }
	parent   	&Node = unsafe { nil }
	mws 		[]Handler
	handler 	Handler
	term_count 	int
}

pub fn (mut t Node) new_child(val string, path string, handler Handler, term bool, is_group bool) &Node {
	unsafe {
		node := &Node{
			val: val
			path: path
			term: term
			depth: t.depth + 1
			is_group: is_group
			handler: handler
			children: map[string]&Node{}
		}

		t.children[node.val] = node
		return node
	}
}

pub fn (mut t Node) set_pattern(is_pattern bool, segment string, param_name string) {
	if is_pattern {
		re := regex.regex_opt(segment) or {
			panic('注册路由节点${segment}失败: ${err}')
		}
		t.param_name = param_name
		t.is_pattern = is_pattern
		t.re = &re
	}
}

pub fn (t Node) parent() &Node {
	return t.parent
}

pub fn (t Node) children() map[string]&Node {
	return t.children.clone()
}

pub fn (t Node) terminating() bool {
	return t.term
}

pub fn (t Node) val() string {
	return t.val
}

pub fn (t Node) depth() int {
	return t.depth
}

pub fn (t Node) handler_fn() Handler {
	return t.handler
}

pub fn (t Node) str() string {
	return "path:${t.path} pattern: ${t.is_pattern} is_term: ${t.term}"
}
