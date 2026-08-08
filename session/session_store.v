module session

import time

// SessionStore abstracts session persistence. Implementations may store
// sessions in memory, Redis, a database, etc.
pub interface SessionStore {
	// get retrieves session data by id. Returns an empty map if the session
	// does not exist or has expired (implementations should delete expired
	// entries as part of this call).
	get(id string) map[string]string
	// set stores session data with a time-to-live in seconds.
	set(id string, data map[string]string, ttl_seconds int)
	// delete removes a session by id.
	delete(id string)
	// exists reports whether a non-expired session with the given id exists.
	exists(id string) bool
	// gc purges all expired sessions. Implementations may also run this
	// periodically in a background task.
	gc()
}

// StoreItem holds a session's data and its expiration time.
struct StoreItem {
	expire_time time.Time
	data        map[string]string
}

// MemorySessionStore is the default in-memory SessionStore implementation.
@[heap]
pub struct MemorySessionStore {
mut:
	data shared map[string]StoreItem
}

// new_memory_session_store creates an empty MemorySessionStore.
pub fn new_memory_session_store() &MemorySessionStore {
	return &MemorySessionStore{
		data: map[string]StoreItem{}
	}
}

pub fn (mut s MemorySessionStore) get(id string) map[string]string {
	mut result := map[string]string{}
	lock s.data {
		if id !in s.data {
			return result
		}
		item := s.data[id]
		if item.expire_time <= time.now() {
			// expired: remove and return empty map
			s.data.delete(id)
			return result
		}
		result = item.data.clone()
	}
	return result
}

pub fn (mut s MemorySessionStore) set(id string, data map[string]string, ttl_seconds int) {
	lock s.data {
		s.data[id] = StoreItem{
			expire_time: time.now().add_seconds(ttl_seconds)
			data:        data.clone()
		}
	}
}

pub fn (mut s MemorySessionStore) delete(id string) {
	lock s.data {
		s.data.delete(id)
	}
}

pub fn (mut s MemorySessionStore) exists(id string) bool {
	mut flag := false
	lock s.data {
		if id !in s.data {
			return false
		}
		item := s.data[id]
		if item.expire_time <= time.now() {
			s.data.delete(id)
			flag = false
		} else {
			flag = true
		}
	}
	return flag
}

pub fn (mut s MemorySessionStore) gc() {
	lock s.data {
		mut expired := []string{}
		for sess_id, item in s.data {
			if item.expire_time <= time.now() {
				expired << sess_id
			}
		}
		for sess_id in expired {
			s.data.delete(sess_id)
		}
	}
}

// default_store is the process-wide default SessionStore used by Session
// when no explicit store is provided. It is a const pointer to a mutable
// heap struct; the struct's shared map is mutable but the pointer itself
// cannot be reassigned. For application-level store replacement, use
// Application.set_session_store instead.
const default_store = &MemorySessionStore{
	data: map[string]StoreItem{}
}

// default_session_store returns the default in-memory SessionStore.
pub fn default_session_store() &MemorySessionStore {
	return default_store
}

// init starts a background goroutine that periodically purges expired
// sessions from the default store.
fn init() {
	go fn () {
		for {
			unsafe {
				mut store := default_store
				store.gc()
			}
			time.sleep(time.second * 30)
		}
	}()
}
