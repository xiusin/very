module cache

import time

pub struct Config {
pub mut:
	shards  int
	lift_window time.Duration
	clear_window time.Duration
}


pub fn default_config(eviction time.Duration) Config {
	return Config {
		shards: 1024
		clear_window: time.second
		lift_window: eviction
	}
}
