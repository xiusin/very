module di

pub struct Builder  {
mut:
    services shared map[string]Service
}

pub fn new() Builder {
	return Builder {
		services:  map[string]Service{}
	}
}
