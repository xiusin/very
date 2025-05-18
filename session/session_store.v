module session

import time

struct StoreItem {
	expire_time time.Time
	data        map[string]string
}

pub struct SessionStore {
mut:
	data shared map[string]StoreItem
}

const store = &SessionStore{
	data: map[string]StoreItem{}
}

fn init() {
	go fn () {
		for {
			lock store.data {
				for sess_id, item in store.data {
					if item.expire_time <= time.now() {
						store.data.delete(sess_id)
					}
				}
			}
			time.sleep(time.second * 30)
		}
	}()
}

fn (mut store SessionStore) get(sess_id string) map[string]string {
	mut data := map[string]string{}
	lock store.data {
		item := store.data[sess_id]
		if  item.expire_time <= time.now() {
			store.data.delete(sess_id)
		}
		data = item.data.clone()
	}
	return data
}

fn (mut store SessionStore) set(sess_id string, data map[string]string, second int) {
	lock store.data {
		store.data[sess_id] = StoreItem{
			expire_time: time.now().add_seconds(second)
			data:        data.clone()
		}
	}
}
