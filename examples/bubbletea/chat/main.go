package main

// A simple program demonstrating the textinput component from the Bubbles
// component library.

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	chat     string
	typing   string
	quitting bool
	height   int
	width    int
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyEnter:
			if len(m.typing) > 0 {
				m.chat = fmt.Sprintf("%s\nYou: %s", m.chat, m.typing)
				m.typing = ""
			}
		case tea.KeyBackspace:
			if len(m.typing) > 0 {
				m.typing = m.typing[:len(m.typing)-1]
			}
		default:
			switch msg.String() {
			case "ctrl+c", "q":
				return m, tea.Quit
			default:
				m.typing = fmt.Sprintf("%s%s", m.typing, msg.String())
			}
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}
	return m, nil
}

func (m model) View() string {
	helpStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("241"))

	chatBox := lipgloss.NewStyle().
		Width(m.width).
		Height(m.height - 2).
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("63")).
		Render(m.chat)

	prompt := helpStyle.Render("Press esc to quit")
	prompt = lipgloss.PlaceHorizontal(m.width, lipgloss.Left, prompt)
	return fmt.Sprintf("%s\n%s\n> %s", chatBox, prompt, m.typing)
}

func main() {
	if _, err := tea.NewProgram(model{}).Run(); err != nil {
		fmt.Println("Error running program:", err)
		os.Exit(1)
	}
}
