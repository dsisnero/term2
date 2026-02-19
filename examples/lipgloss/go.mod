module examples

go 1.24.3

replace (
	charm.land/bubbletea/v2 => ../../vendor/bubbletea
	charm.land/lipgloss/v2 => ../../vendor/lipgloss
	github.com/charmbracelet/x/ansi => ../../vendor/x/ansi
	github.com/charmbracelet/x/conpty => ../../vendor/x/conpty
	github.com/charmbracelet/x/exp/charmtone => ../../vendor/x/exp/charmtone
	github.com/charmbracelet/x/term => ../../vendor/x/term
	github.com/charmbracelet/x/termios => ../../vendor/x/termios
	github.com/charmbracelet/x/windows => ../../vendor/x/windows
)

toolchain go1.24.4

require (
	charm.land/bubbletea/v2 v2.0.0-rc.2.0.20251201184111-551c60ee5a5c
	charm.land/lipgloss/v2 v2.0.0-beta.3.0.20251106192539-4b304240aab7
	github.com/charmbracelet/colorprofile v0.4.1
	github.com/charmbracelet/ssh v0.0.0-20241211182756-4fe22b0f1b7c
	github.com/charmbracelet/wish/v2 v2.0.0-20251106193208-3cd15da8229f
	github.com/charmbracelet/x/exp/charmtone v0.0.0-20250627134340-c144409e381c
	github.com/charmbracelet/x/term v0.2.2
	github.com/rivo/uniseg v0.4.7
)

require (
	github.com/anmitsu/go-shlex v0.0.0-20200514113438-38f4b401e2be // indirect
	github.com/charmbracelet/keygen v0.5.1 // indirect
	github.com/charmbracelet/log/v2 v2.0.0-20251106192421-eb64aaa963a0 // indirect
	github.com/charmbracelet/ultraviolet v0.0.0-20251212194010-b927aa605560 // indirect
	github.com/charmbracelet/x/ansi v0.11.3 // indirect
	github.com/charmbracelet/x/conpty v0.1.0 // indirect
	github.com/charmbracelet/x/termios v0.1.1 // indirect
	github.com/charmbracelet/x/windows v0.2.2 // indirect
	github.com/clipperhouse/displaywidth v0.9.0 // indirect
	github.com/clipperhouse/stringish v0.1.1 // indirect
	github.com/clipperhouse/uax29/v2 v2.5.0 // indirect
	github.com/creack/pty v1.1.21 // indirect
	github.com/go-logfmt/logfmt v0.6.0 // indirect
	github.com/lucasb-eyer/go-colorful v1.3.0 // indirect
	github.com/mattn/go-runewidth v0.0.19 // indirect
	github.com/muesli/cancelreader v0.2.2 // indirect
	github.com/xo/terminfo v0.0.0-20220910002029-abceb7e1c41e // indirect
	golang.org/x/crypto v0.36.0 // indirect
	golang.org/x/exp v0.0.0-20240719175910-8a7402abbf56 // indirect
	golang.org/x/sync v0.18.0 // indirect
	golang.org/x/sys v0.40.0 // indirect
)

// replace with log v2
