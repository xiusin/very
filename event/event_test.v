module event

struct TestEvent {
	value int
}

fn (e TestEvent) name() string {
	return 'TestEvent'
}

// Counter is a heap-allocated holder so closures can mutate shared state.
struct Counter {
mut:
	val int
}

fn test_event_bus_basic() {
	mut bus := new_event_bus()
	mut c := &Counter{}
	bus.on('TestEvent', fn [mut c] (e Event) ! {
		c.val += 1
	})
	bus.emit(TestEvent{ value: 42 })!
	assert c.val == 1
}

fn test_event_bus_multiple_listeners() {
	mut bus := new_event_bus()
	mut c := &Counter{}
	bus.on('TestEvent', fn [mut c] (e Event) ! {
		c.val += 1
	})
	bus.on('TestEvent', fn [mut c] (e Event) ! {
		c.val += 10
	})
	bus.emit(TestEvent{ value: 1 })!
	assert c.val == 11
}

fn test_event_bus_off() {
	mut bus := new_event_bus()
	mut c := &Counter{}
	bus.on('TestEvent', fn [mut c] (e Event) ! {
		c.val += 1
	})
	bus.off('TestEvent')
	bus.emit(TestEvent{ value: 1 })!
	assert c.val == 0
}

fn test_event_bus_off_all() {
	mut bus := new_event_bus()
	mut c := &Counter{}
	bus.on('TestEvent', fn [mut c] (e Event) ! {
		c.val += 1
	})
	bus.on('OtherEvent', fn [mut c] (e Event) ! {
		c.val += 100
	})
	bus.off_all()
	bus.emit(TestEvent{ value: 1 })!
	assert c.val == 0
}

fn test_builtin_events() {
	assert ServerStartEvent{
		port:     8080
		app_name: 'very'
	}.name() == 'ServerStart'
	assert ServerShutdownEvent{}.name() == 'ServerShutdown'
	assert RequestStartEvent{
		method: 'GET'
		path:   '/'
	}.name() == 'RequestStart'
	assert RequestEndEvent{
		method:      'GET'
		path:        '/'
		status_code: 200
		duration_ms: 5
	}.name() == 'RequestEnd'
}

fn test_event_bus_emit_builtin() {
	mut bus := new_event_bus()
	mut c := &Counter{}
	bus.on('ServerStart', fn [mut c] (e Event) ! {
		c.val = (e as ServerStartEvent).port
	})
	bus.emit(ServerStartEvent{ port: 3000, app_name: 'very' })!
	assert c.val == 3000
}

fn test_event_bus_no_listeners() {
	mut bus := new_event_bus()
	// Emitting an event with no registered listeners should not fail.
	bus.emit(TestEvent{ value: 1 })!
}

fn test_event_bus_listener_error_propagates() {
	mut bus := new_event_bus()
	bus.on('TestEvent', fn (e Event) ! {
		return error('listener failed')
	})
	mut failed := false
	bus.emit(TestEvent{ value: 1 }) or { failed = true }
	assert failed == true
}
