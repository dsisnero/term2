package main

// An example program to show how to switch the terminal into the altscreen and
// back.

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	altscreen bool
}

type toggleScreenMsg struct {
	err error
}

func switchScreen(b bool) tea.Cmd {
	return func() tea.Msg {
		return toggleScreenMsg{err: tea.EnterAltScreen()}
	}
}

func (m model) Init() tea.Cmd {
	return tea.EnterAltScreen
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case toggleScreenMsg:
		return m, msg.err
	case tea.KeyMsg:
		switch msg.String() {
		case " ":
			m.altscreen = !m.altscreen
			return m, tea.Batch(
				tea.ExitAltScreen,
				tea.WithAltScreen(tea.EnterAltScreen),
			)

		case "q", "esc":
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m model) View() string {
	if m.altscreen {
		return lipgloss.NewStyle().
			Align(lipgloss.Center, lipgloss.Center).
			Foreground(lipgloss.Color("42")).
			Render("Mmmm, crisp.\n\nIs this not the best flan ever?") + "\n"
	}
	return "Back to classic =)\n\n"
}

func main() {
	if _, err := tea.NewProgram(model{}).Run(); err != nil {
		fmt.Println("Uh oh:", err)
		os.Exit(1)
	}
}
