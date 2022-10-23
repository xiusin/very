module di

pub interface Any {}

pub struct Service {
	name string
mut:
	instance Any
}
