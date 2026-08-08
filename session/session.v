module session

import rand

// Session represents a single user session. It delegates persistence to a
// SessionStore (in-memory by default, replaceable via set_default_store or
// new_session_with_store).
@[head]
pub struct Session {
mut:
	id    string
	data  map[string]string
	store &MemorySessionStore = unsafe { nil }
}

// new_session creates a session with the given id, loading any existing
// data from the default store.
pub fn new_session(id string) &Session {
	mut sess := &Session{
		id:    id
		store: default_session_store()
	}
	sess.load()
	return sess
}

// new_session_with_store creates a session backed by an explicit store.
pub fn new_session_with_store(id string, store &MemorySessionStore) &Session {
	mut sess := &Session{
		id:    id
		store: store
	}
	sess.load()
	return sess
}

fn (mut s Session) set_store(store &MemorySessionStore) {
	s.store = store
}

// set_session_store sets the backing store for this session. Allows the
// application to plug in a custom store (e.g. Redis-backed) per session.
pub fn (mut s Session) set_session_store(store &MemorySessionStore) {
	s.store = store
}

fn (mut s Session) load() {
	if s.store == unsafe { nil } {
		s.store = default_session_store()
	}
	s.data = s.store.get(s.get_id())
}

pub fn (mut s Session) sync() {
	if s.store == unsafe { nil } {
		s.store = default_session_store()
	}
	s.store.set(s.get_id(), s.data.clone(), 3600)
}

fn (mut s Session) all() map[string]string {
	return s.data
}

pub fn (mut s Session) get_id() string {
	mut prng := rand.get_current_rng()
	if s.id == '' {
		s.id = 'sess_' + prng.string(32)
	}
	return s.id
}

pub fn (mut s Session) get(key string) string {
	return s.data[key] or { '' }
}

pub fn (mut s Session) set(key string, value string) {
	s.data[key] = value
}
