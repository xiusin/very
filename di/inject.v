module di

// inject_name_attr is the field attribute prefix used to mark fields for auto-injection.
// Example: `logger &Logger @[inject: 'logger']`
const inject_attr = 'inject: '

// parse_inject_name extracts the bean name from a field's @[inject: 'name'] attribute.
// Returns empty string if the field has no inject attribute or has multiple.
// Strips surrounding single/double quotes from the value, since V stores
// @[inject: 'repo'] as the literal string "inject: 'repo'" (quotes included).
pub fn parse_inject_name(attrs []string) string {
	mut names := []string{}
	for attr in attrs {
		if attr.contains(di.inject_attr) {
			mut val := attr.replace(di.inject_attr, '')
			if val.len >= 2 {
				if (val[0] == `'` && val[val.len - 1] == `'`) || (val[0] == `"` && val[val.len - 1] == `"`) {
					val = val[1..val.len - 1]
				}
			}
			names << val
		}
	}
	if names.len == 1 {
		return names[0]
	}
	return ''
}

// has_inject_attr returns true if the field attrs contain an @[inject: ...] marker.
pub fn has_inject_attr(attrs []string) bool {
	return parse_inject_name(attrs).len > 0
}

// inject_fields resolves all @[inject: 'name'] annotated fields of a struct instance
// by looking up the bean in the container and copying the pointer into the field.
//
// This is the core auto-injection primitive. It works for both:
//   - Service instances (called once at registration/first-get time)
//   - Controller instances (called per-request)
//
// Uses resolve_instance_or_nil which triggers factory creation for lazy/factory
// beans and supports circular dependency resolution via early references.
//
// Note: Uses runtime `field.indirections` check instead of comptime `$if` because
// V 0.5.1 does not reliably evaluate comptime `$if field.indirections == 1` inside
// generic closures (the branch is silently skipped).
pub fn inject_fields[T](mut instance T, mut c Container) ! {
	$for field in T.fields {
		bean_name := parse_inject_name(field.attrs)
		if bean_name.len > 0 && field.indirections >= 1 {
			raw := c.resolve_instance_or_nil(bean_name)
			if isnil(raw) {
				return error('inject failed: bean `${bean_name}` not found or nil for field `${field.name}`')
			}
			unsafe {
				C.memcpy(&instance.$(field.name), &raw, sizeof(voidptr))
			}
		}
	}
}

// inject_fields_safe is like inject_fields but returns void on error.
// Useful for cases where injection failure should not be fatal (e.g. per-request
// controller injection, or circular dependency resolution where the early
// reference may temporarily be nil).
//
// Uses resolve_instance_or_nil to avoid V 0.5.1 generic `or` block `err` bug.
pub fn inject_fields_safe[T](mut instance T, mut c Container) {
	$for field in T.fields {
		bean_name := parse_inject_name(field.attrs)
		if bean_name.len > 0 && field.indirections >= 1 {
			raw := c.resolve_instance_or_nil(bean_name)
			if !isnil(raw) {
				unsafe {
					C.memcpy(&instance.$(field.name), &raw, sizeof(voidptr))
				}
			}
		}
	}
}
