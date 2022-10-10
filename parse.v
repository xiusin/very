module veb

import net.http

// @from vlib/vweb/parse.v
fn parse_attrs(name string, attrs []string) ?([]http.Method, string) {
	if attrs.len == 0 {
		return [http.Method.get], '/$name'
	}

	mut x := attrs.clone()
	mut methods := []http.Method{}
	mut path := ''

	for i := 0; i < x.len; {
		attr := x[i]
		attru := attr.to_upper()
		m := http.method_from_str(attru)
		if attru == 'GET' || m != .get {
			methods << m
			x.delete(i)
			continue
		}
		if attr.starts_with('/') {
			if path != '' {
				return IError(http.MultiplePathAttributesError{})
			}
			path = attr
			x.delete(i)
			continue
		}
		i++
	}
	if x.len > 0 {
		return IError(http.UnexpectedExtraAttributeError{
			attributes: x
		})
	}
	if methods.len == 0 {
		methods = [http.Method.get]
	}
	if path == '' {
		path = '/$name'
	}
	// Make path lowercase for case-insensitive comparisons
	return methods, path.to_lower()
}
