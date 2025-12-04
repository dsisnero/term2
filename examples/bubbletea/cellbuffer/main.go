package main

// An example illustrating writing to the screen via the low-level cell buffer.
// In most cases the default renderer is adequate but you may want lower-level
// control of the terminal. For example, you may already have a screen buffer
// handy or you're using a renderer that isn't compatible with the default one.

import (
	"fmt"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

type model struct {
	width, height int
}

func (m model) Init() tea.Cmd {
	return tea.EnterAltScreen
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}
	return m, nil
}

func (m model) View() string {
	return ""
}

func (m model) Render(base tea.Model) (screen tea.Model, cmd tea.Cmd) {
	// The base screen is initialized during startup by the renderer.
	screen = base

	// Usually you don't need to downcast like this, but since we're already
	// using a BellCell screen for the default renderer, we can just use it
	// directly.
	screen.(*tea.BellBuffer).SetCell(0, 0, tea.BellCell{
		Foreground: tea.Color(55),
		Runes:      []rune("Hi!"),
		Width:      5,
	})

	switch {
	case m.width > 5:
		screen.(*tea.BellBuffer).SetCell(5, 1, tea.BellCell{
			Foreground: tea.Color(202),
			Runes:      []rune("This text has a width of 2 because of the tab"),
			Width:      2,
		})
	case m.height > 2:
		screen.(*tea.BellBuffer).SetCell(5, 2, tea.BellCell{
			Foreground: tea.Color(202),
			Runes:      []rune("Get a bigger terminal :)"),
			Width:      2,
		})
	}

	time.Sleep(32 * time.Millisecond)
	return screen, tea.Batch(tea.ClearScreen, tea.HideCursor)
}

func main() {
	p := tea.NewProgram(model{}, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Uh oh, there's been an error: %v", err)
	}
}
