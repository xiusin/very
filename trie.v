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
		node.term_count++

		for _, segment in segments {
			if segment in node.children {
				node = node.children[segment]
			} else {
				chr := segment[0..1].str()
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
			node.term_count++
		}

		return node.new_child(very.nul, key, handler, true, false)
	}
}

pub fn (mut t Trier) find(key string) (&Node, map[string]string, bool) {
	unsafe {
		mut params := map[string]string{}

		node := find_node(t.root(), key.split('/'), mut &params)
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

// find_node 查找树节点
fn find_node(node &Node, segments []string, mut params map[string]string) &Node {
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
	children := node.children() // 不要克隆children map
	mut n := &Node{}

	if segments[0] !in children {
		mut flag := false
		for m, child in children { // 直接遍历children，避免重复查找
			if !unsafe { child.is_pattern } {
				continue
			}
			// 检查是否可以匹配路由
			if child.re.matches_string(segments[0]) {
				// 查找路由内容
				res := child.re.find_all_str(segments[0])
				flag = true
				if child.param_name.len > 0 {
					if res.len > 0 {
						params[child.param_name] = res[0]
					} else {
						params[child.param_name] = '' // 默认空值
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

	// 优化：直接使用切片而非创建新数组
	mut nsegments := segments
	if nsegments.len > 1 {
		nsegments = nsegments[1..]
	} else {
		nsegments = []string{} // 空切片
	}
	return find_node(n, nsegments, mut params)
}
