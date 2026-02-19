module github.com/charmbracelet/x/examples

go 1.24.2

replace (
	charm.land/lipgloss/v2 => ../../vendor/lipgloss
	github.com/charmbracelet/x/ansi => ../../vendor/x/ansi
	github.com/charmbracelet/x/cellbuf => ../../vendor/x/cellbuf
	github.com/charmbracelet/x/exp/charmtone => ../../vendor/x/exp/charmtone
	github.com/charmbracelet/x/exp/toner => ../../vendor/x/exp/toner
	github.com/charmbracelet/x/input => ../../vendor/x/input
	github.com/charmbracelet/x/mosaic => ../../vendor/x/mosaic
	github.com/charmbracelet/x/term => ../../vendor/x/term
	github.com/charmbracelet/x/termios => ../../vendor/x/termios
	github.com/charmbracelet/x/windows => ../../vendor/x/windows
)

toolchain go1.24.5

require (
	charm.land/lipgloss/v2 v2.0.0-beta.3.0.20251106193318-19329a3e8410
	github.com/charmbracelet/colorprofile v0.4.1
	github.com/charmbracelet/fang v0.4.4
	github.com/charmbracelet/lipgloss v1.1.0
	github.com/charmbracelet/x/ansi v0.11.5
	github.com/charmbracelet/x/cellbuf v0.0.14
	github.com/charmbracelet/x/exp/charmtone v0.0.0-20250603201427-c31516f43444
	github.com/charmbracelet/x/exp/toner v0.0.0-20250602202920-5fecc56e9a94
	github.com/charmbracelet/x/input v0.3.7
	github.com/charmbracelet/x/mosaic v0.0.0-20250313150240-c09addb0e197
	github.com/creack/pty v1.1.24
	github.com/lucasb-eyer/go-colorful v1.3.0
	github.com/spf13/cobra v1.10.2
)

require (
	github.com/aymanbagabas/go-osc52/v2 v2.0.1 // indirect
	github.com/bits-and-blooms/bitset v1.24.4 // indirect
	github.com/charmbracelet/ultraviolet v0.0.0-20251205161215-1948445e3318 // indirect
	github.com/charmbracelet/x/termios v0.1.1 // indirect
	github.com/charmbracelet/x/windows v0.2.2 // indirect
	github.com/clipperhouse/displaywidth v0.9.0 // indirect
	github.com/clipperhouse/stringish v0.1.1 // indirect
	github.com/clipperhouse/uax29/v2 v2.5.0 // indirect
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/mattn/go-runewidth v0.0.19 // indirect
	github.com/muesli/mango v0.1.0 // indirect
	github.com/muesli/mango-cobra v1.2.0 // indirect
	github.com/muesli/mango-pflag v0.1.0 // indirect
	github.com/muesli/roff v0.1.0 // indirect
	github.com/muesli/termenv v0.16.0 // indirect
	github.com/spf13/pflag v1.0.9 // indirect
	golang.org/x/sync v0.19.0 // indirect
	golang.org/x/text v0.33.0 // indirect
)

require (
	github.com/charmbracelet/x/term v0.2.2
	github.com/muesli/cancelreader v0.2.2 // indirect
	github.com/rivo/uniseg v0.4.7
	github.com/xo/terminfo v0.0.0-20220910002029-abceb7e1c41e // indirect
	golang.org/x/image v0.35.0 // indirect
	golang.org/x/sys v0.40.0 // indirect
)
