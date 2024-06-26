module contracts
import very.di

pub interface Injectable {
	get_di() &di.Builder
	set_di(mut di.Builder)
}
