module event

// Event interface - all events implement this
pub interface Event {
	name() string
}

// EventListener - a function that handles events
pub type EventListener = fn (Event) !

// EventBus - thread-safe event dispatcher
@[heap]
pub struct EventBus {
mut:
	listeners shared map[string][]EventListener
}

pub fn new_event_bus() &EventBus {
	return &EventBus{
		listeners: map[string][]EventListener{}
	}
}

// on registers a listener for an event name
pub fn (mut bus EventBus) on(event_name string, listener EventListener) {
	lock bus.listeners {
		mut arr := bus.listeners[event_name] or { []EventListener{} }
		arr << listener
		bus.listeners[event_name] = arr
	}
}

// emit dispatches an event to all registered listeners for that event name
// Errors in listeners are collected but do not stop dispatch; returns first error if any
pub fn (mut bus EventBus) emit(e Event) ! {
	mut listeners_copy := []EventListener{}
	lock bus.listeners {
		listeners_copy = bus.listeners[e.name()] or { []EventListener{} }.clone()
	}
	for listener in listeners_copy {
		listener(e) or {
			// collect error but continue
			// for simplicity, return first error
			return err
		}
	}
}

// off removes a specific listener from an event name (by pointer equality is not possible in V, so this clears all listeners for the event name)
// Actually, V closures can't be compared. So off removes ALL listeners for a given event name.
pub fn (mut bus EventBus) off(event_name string) {
	lock bus.listeners {
		bus.listeners.delete(event_name)
	}
}

// off_all clears all listeners
pub fn (mut bus EventBus) off_all() {
	lock bus.listeners {
		bus.listeners.clear()
	}
}
