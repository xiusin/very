module very

pub struct Trier {
mut:
	root &Node
	size int
}

const nul = ''

pub fn new_trie() &Trier {
	return &Trier{
		root: &Node{
			depth: 0
			children: map[string]&Node{}
		}
		size: 0
	}
}

pub fn (mut t Trier) root() &Node {
	return t.root
}

pub fn (mut t Trier) add(key string, handler Handler, mws []Handler) &Node {
	unsafe {
		t.size++
		segments := key.split('/')
		mut node := t.root // 根节点

		for _, segment in segments {
			if segment in node.children {
				node = node.children[segment]
			} else {
				chr := if segment.len > 0 { segment[0..1].str() } else { '' }
				mut se := segment
				is_pattern := match chr {
					'*', ':' { true }
					else { false }
				}
				mut param_name := ''
				if is_pattern {
					if chr == ':' {
						param_name = segment[1..]
						se = '(?P<${param_name}>.+)'
					} else if chr == '*' {
						if segment.len > 1 {
							param_name = segment[1..]
							se = '(?P<${param_name}>.*)'
						} else {
							se = '(.*)'
						}
					}
				}
				node = node.new_child(se, '', nil, false, false)
				node.set_pattern(is_pattern, se, param_name)
			}
		}

		return node.new_child(very.nul, key, handler, true, false)
	}
}

pub fn (mut t Trier) find(key string) (&Node, map[string]string, bool) {
	unsafe {
		mut params := map[string]string{}
		segments := key.split('/')
		node := find_node(t.root(), mut segments, mut &params)
		if node == nil {
			return nil, map[string]string{}, false
		}
		children := node.children()
		if very.nul !in children { // 还没有初始化过
			return nil, map[string]string{}, false
		}
		child := children[very.nul]
		if !child.term {
			return nil, map[string]string{}, false
		}
		return child, params, true
	}
}

// find_node
fn find_node(node &Node, mut segments []string, mut params map[string]string) &Node {
	unsafe {
		if node == nil {
			return nil
		}
	}
	if segments.len == 0 {
		unsafe {
			return node
		}
	}
	mut children := node.children()
	mut n := &Node{}

	if segments[0] !in children {
		mut flag := false
		for m, _ in children {
			if !unsafe { children[m].is_pattern } {
				continue
			}

			mut child := children[m] or { continue }
			if child.re.query.contains('*') {
				segments = [segments.join('/')]
			}

			if child.re.matches_string(segments[0]) {
				res := child.re.find_all_str(segments[0])
				flag = true
				if child.param_name.len > 0 {
					params[child.param_name] = ''
					if res.len > 0 {
						params[child.param_name] = res[0]
					}
				}
				unsafe {
					n = child
				}
				break
			}
		}
		if !flag {
			return unsafe { nil }
		}
	} else {
		unsafe {
			n = children[segments[0]]
		}
	}

	mut nsegments := []string{}
	if segments.len > 1 {
		nsegments = unsafe { segments[1..] }
	}
	return find_node(n, mut nsegments, mut params)
}
