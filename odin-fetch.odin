package main

import "core:flags"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import si "core:sys/info"

import "sysinfo"

PROGRAM_NAME :: "odin-fetch"

write_help :: proc() {
	fmt.println("Usage: %v [FLAGS]", PROGRAM_NAME)

	os.exit(0)
}

get_uptime :: proc(uptime: ^Uptime) {
	uptime_in_seconds, ok := sysinfo.get_system_uptime_in_seconds()

	uptime.days = uptime_in_seconds / 86400
	uptime.hours = (uptime_in_seconds / 3600) - (uptime.days * 24)
	uptime.minutes = (uptime_in_seconds / 60) - (uptime.hours * 60)
	uptime.seconds = uptime_in_seconds % 60
}

get_max_line_length :: proc(s: string) -> (max: int) {
	str := s
	for line in strings.split_lines_iterator(&str) {
		l := len(line)
		if l > max {
			max = l
		}
	}

	return
}

get_distro :: proc() -> (string, mem.Allocator_Error) {
	i := strings.index(si.os_version.as_string, ",")

	return strings.clone(si.os_version.as_string[:i])
}

add_padding :: proc(b: ^strings.Builder, amount_of_padding: int) {
	for i := 0; i <= amount_of_padding; i += 1 {
		strings.write_rune(b, ' ')
	}
}

_main :: proc() {
	options: Options
	style : flags.Parsing_Style = .Unix
	small_logo := false
	possible_flags: [dynamic]string
	defer delete(possible_flags)
	for arg in os.args {
		if arg[0] == '-' {
			append(&possible_flags, arg)
		}
	}
	if len(possible_flags) > 0 {
		err := flags.parse(&options, possible_flags[:], style)
		#partial switch e in err {
			case flags.Parse_Error:
				write_help()
			case flags.Validation_Error:
				write_help()
			case flags.Help_Request:
				write_help()
		}
		if options.small {
			small_logo = true
		}
	}

	hostname, hostname_ok := sysinfo.get_hostname()
	defer delete(hostname)
	if !hostname_ok {
		fmt.eprintln("Failed to get hostname")
		os.exit(-1)
	}

	uptime: Uptime
	get_uptime(&uptime)

	distro, distro_err := get_distro()
	defer delete(distro)
	if distro_err != nil {
		fmt.eprintln("Failed to determine distribution")
		return
	}

	user := os.get_env("USER")
	defer delete(user)

	logo_name: string
	if small_logo {
		logo_name = fmt.tprintf("%s Small", distro)
	} else {
		logo_name = distro
	}
	logo, ok := Logos[logo_name]
	if !ok {
		fmt.eprintln("Sorry your distribution is not currently supported")

		return
	}

	num_spaces := get_max_line_length(logo) + 2

	b: strings.Builder
	strings.builder_init_none(&b)
	i := 0
	for line in strings.split_lines_iterator(&logo) {
		if i == 0 {
			i += 1
			continue
		}
		strings.write_string(&b, BOLD_GREEN)
		strings.write_string(&b, line)
		strings.write_string(&b, NORMAL)

		if i == 1 {
			add_padding(&b, num_spaces-len(line))
			user_details := fmt.aprint(BOLD_WHITE, "User:   ", BOLD_BLUE, user, NORMAL, sep="")
			strings.write_string(&b, user_details)
			delete(user_details)
		} else if i == 2 {
			add_padding(&b, num_spaces-len(line))
			host_details := fmt.aprint(BOLD_WHITE, "Host:   ", BOLD_BLUE, hostname, NORMAL, sep="")
			strings.write_string(&b, host_details)
			delete(host_details)
		} else if i == 3 {
			add_padding(&b, num_spaces-len(line))
			uptime_details := fmt.aprint(
				BOLD_WHITE,
				"Uptime: ",
				BOLD_BLUE,
				uptime.days,
				" days, ",
				uptime.hours,
				" hours, ",
				uptime.minutes,
				" minutes, ",
				uptime.seconds,
				" seconds",
				NORMAL,
				sep="",
			)
			strings.write_string(&b, uptime_details)
			delete(uptime_details)
		}

		strings.write_rune(&b, '\n')

		i += 1
	}

	output := strings.to_string(b)
	defer delete(output)

	fmt.println(output)
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}
