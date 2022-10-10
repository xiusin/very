module veb

import rand

pub struct Session {
mut:
	id   string
	data map[string]string
}

pub fn new_session(id string) Session {
	mut sess := Session{
		id: id
	}
	sess.load()
	return sess
}

fn (mut s Session) set_id(id string) {
	s.id = id
}

fn (mut s Session) load() {
	s.data = store.get(s.get_id())
}

fn (mut s Session) sync() {
	store.set(s.get_id(), s.data.clone(), 3600)
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
