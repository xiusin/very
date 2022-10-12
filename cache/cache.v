module cache

import time

pub enum RemoveReason {
	expired
	no_space
	delete
}


pub struct Cache {
mut:
	shards 		[]&Shard
	shard_mask 	u64
	clock 		time.Time
	config 		Config
	close 		chan voidptr
}

pub fn new(cfg Config) ?Cache {
	cacher := Cache {
		shards: []&Shard{cap: cfg.shards}
		config: cfg
		clock: time.now(),
		shard_mask: u64(cfg.shards - 1)
		close: chan voidptr{}
	}

	if cfg.clear_window > 0 {
		go fn () {
			for {
				time.sleep(cfg.clear_window)
				select {
					<- cache.close {
						return
					}
				}
			}
		}()
	}


	return cacher
}
