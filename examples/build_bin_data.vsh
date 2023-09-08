import xiusin.very

fn main() {
	input_arg := real_path('./dist')
	mut assets_ := very.Asset{}
	assets_.scan_dir(input_arg)
	assets_.gen()!
}
