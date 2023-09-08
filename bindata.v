module very

import os
import strings

pub struct Asset {
pub mut:
	files map[string]&File = map[string]&File{}
}

pub struct File {
	data []u8
}

pub fn (mut asset Asset) find(name string) !&File {
	return asset.files[name] or { return error('file `${name}` not exist!') }
}

pub fn (mut asset Asset) scan_dir(dir string) {
	os.walk(dir, fn [mut asset, dir] (it string) {
		asset.append(it, dir)
	})
}

pub fn (mut asset Asset) append(it string, root string) {
	if !it.contains('bindata') {
		asset.files[it.replace(root, '')] = &File{
			data: os.read_bytes(it) or { []u8{} }
		}
	}
}

pub fn (mut asset Asset) gen() ! {
	mut buf := strings.new_builder(1024 * 1024 * 1024 * 5)

	buf.write_string(r'module main
import xiusin.very

pub fn byte_file_data() &very.Asset {
	mut asset := &very.Asset {}
')

	for file, asset_ in asset.files {
		mut str := asset_.data.str()

		index := str.index(',') or { -1 }

		if index > 1 {
			substr := str.substr(1, index)
			str = str.replace_once('[' + substr, '[u8(' + substr + ')')
		}

		buf.write_string('	asset.files["${file.trim_left('/')}"] = &very.File { data: ${str} }\n')
	}
	buf.write_string(r'
	return asset
}')

	os.write_file('bindata.v', buf.str())!
}
