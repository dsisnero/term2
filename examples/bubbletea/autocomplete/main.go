package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

const (
	defaultWidth     = 20
	listHeight       = 5
	charLimit        = 32
	waitingIndicator = "…"
)

type model struct {
	textInput textinput.Model
	choices   []list.Item
	list      list.Model
	matches   []list.Item
	err       error
}

type searchCompleteMsg struct {
	results []list.Item
}

func newModel() model {
	ti := textinput.New()
	ti.CharLimit = charLimit

	items := []list.Item{
		list.Item("bubbletea"),
		list.Item("bubbles"),
		list.Item("lipgloss"),
	}

	l := list.New(items, list.NewDefaultDelegate(), defaultWidth, listHeight)
	l.InfiniteScrolling = true
	l.SetShowHelp(false)
	l.DisableQuitKeybindings()
	return model{
		textInput: ti,
		choices:   items,
		list:      l,
		matches:   items,
	}
}

func search(query string, choices []list.Item) tea.Cmd {
	return func() tea.Msg {
		time.Sleep(750 * time.Millisecond) // simulate search delay

		var results []list.Item
		for _, choice := range choices {
			if strings.Contains(choice.FilterValue(), query) {
				results = append(results, choice)
			}
		}

		if len(results) == 0 {
			return searchCompleteMsg{results: []list.Item{list.Item("No results found.")}}
		}
		return searchCompleteMsg{results: results}
	}
}

func initialSearch(choices []list.Item) tea.Cmd {
	return func() tea.Msg {
		return searchCompleteMsg{results: choices}
	}
}

func updateMatches(msg tea.Msg, m model) (model, tea.Cmd) {
	var cmd tea.Cmd
	m.textInput, cmd = m.textInput.Update(msg)

	if len(m.textInput.Value()) >= 1 {
		m.matches = []list.Item{list.Item(waitingIndicator)}
		return m, tea.Batch(initialSearch(m.matches), search(m.textInput.Value(), m.choices), cmd)
	}

	m.matches = m.choices
	m.list.ResetSelected()
	m.list.SetHeight(listHeight)
	return m, tea.Batch(initialSearch(m.matches), cmd)
}

func (m model) Init() tea.Cmd {
	return initialSearch(m.matches)
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			return m, tea.Quit
		case "enter":
			return m, tea.Quit
		}
	case searchCompleteMsg:
		m.matches = msg.results
		m.list.SetItems(m.matches)
		m.list.ResetSelected()
		m.list.SetHeight(listHeight)
	}

	m, cmd = updateMatches(msg, m)
	if cmd == nil {
		m.list, cmd = m.list.Update(msg)
	}
	return m, cmd
}

func (m model) View() string {
	return fmt.Sprintf(
		"Search: %s\n\n%s\n\n%s",
		m.textInput.View(),
		m.list.View(),
		"(ctrl+c/esc to quit)",
	)
}

func main() {
	f, err := tea.LogToFile("debug.log", "autocomplete")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close() // nolint:errcheck

	if err := tea.NewProgram(newModel(), tea.WithAltScreen()).Start(); err != nil {
		fmt.Println("Error running program:", err)
		os.Exit(1)
	}
}
