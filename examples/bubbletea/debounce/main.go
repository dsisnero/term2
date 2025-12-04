package main

// A simple example illustrating how to debounce input.

import (
	"fmt"
	"math/rand"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

type model struct {
	tag         int
	buffer      []string
	autoRefresh bool
}

func init() {
	rand.New(rand.NewSource(time.Now().Unix())) // nolint:gosec
}

func makeBatchMsg(tag int, buffer []string) tea.Cmd {
	return func() tea.Msg {
		msg := strings.Join(buffer, "")
		return batchMsg{
			msg: msg,
			tag: tag,
		}
	}
}

type batchMsg struct {
	msg string
	tag int
}

func (m model) Init() tea.Cmd {
	return tea.Quit
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyEnter:
			return m, tea.Quit
		case tea.KeyBackspace:
			if len(m.buffer) > 0 {
				m.buffer = m.buffer[:len(m.buffer)-1]
			}
			return m, nil
		default:
			m.buffer = append(m.buffer, msg.String())
			if m.autoRefresh {
				m.tag += 1
				return m, tea.Batch(makeBatchMsg(m.tag, m.buffer), makeBatchMsg(m.tag, m.buffer))
			}
			return m, nil
		}

	case batchMsg:
		if m.tag != msg.tag {
			return m, nil
		}
		m.tag += 1
		return m, tea.Batch(
			tea.Printf("%s", msg.msg),
		)
	}

	return m, nil
}

func (m model) View() string {
	return fmt.Sprintf("This is just an example.\n\n%s\n", strings.Join(m.buffer, ""))
}

func main() {
	if _, err := tea.NewProgram(model{}).Run(); err != nil {
		fmt.Println("Uh oh:", err)
	}
}
