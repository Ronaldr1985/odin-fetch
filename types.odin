package main

// Colours
NORMAL  :: "\x1B[0m"
BLACK   :: "\033[30m"
BLUE    :: "\x1B[34m"
RED     :: "\x1B[31m"
GREEN   :: "\x1B[32m"
YELLOW  :: "\x1B[33m"
WHITE   :: "\x1B[37m"

BOLD_BLACK  :: "\033[1m\033[30m"
BOLD_BLUE   :: "\033[1m\033[34m"
BOLD_RED    :: "\033[1m\033[31m"
BOLD_GREEN  :: "\033[1m\033[32m"
BOLD_YELLOW :: "\033[1m\033[33m"
BOLD_WHITE  :: "\033[1m\033[37m"

Options :: struct {
	small: bool,
}


Uptime :: struct {
	days, hours, minutes, seconds: int
}
