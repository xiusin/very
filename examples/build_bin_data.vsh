import xiusin.very

fn main() {
	rm('bindata.v') or {}
	input_arg := real_path('./dist')
	mut assets_ := very.Asset{}
	assets_.scan_dir(input_arg)
	assets_.gen()!

	execute_or_panic('v -d net_blocking_sockets . -o examples')
}
