package main

// An example program using a tea.Program with multiple models.

import (
	"fmt"
	"math"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	currentView int
	views       []tea.Model
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "tab", "shift+tab":
			m.nextView()
		case "ctrl+r":
			m.reset()
		}
	}
	return m, nil
}

func (m model) View() string {
	var views []string
	for _, view := range m.views {
		views = append(views, view.View())
	}
	grid := lipgloss.JoinHorizontal(lipgloss.Left,
		focusedModelStyle.Render(views[0]),
		unfocusedModelStyle.Render(views[1]),
		unfocusedModelStyle.Render(views[2]),
	)
	return fmt.Sprintf("%s\n\n%s\n\n%s",
		grid,
		activeModelStyle.Render(fmt.Sprintf("Focused: %d", m.currentView)),
		helpStyle.Render("tab/shift+tab: move focus  •  ctrl+r: reset timer  •  ctrl+c: quit"),
	)
}

func (m *model) nextView() {
	m.currentView = (m.currentView + 1) % len(m.views)
}

func (m *model) reset() {
	for _, view := range m.views {
		if tm, ok := view.(*timerModel); ok {
			tm.reset()
		}
	}
}

type timerModel struct {
	status string
}

func newTimerModel() tea.Model {
	return &timerModel{
		status: "Timer ready",
	}
}

func (m *timerModel) Init() tea.Cmd {
	return nil
}

func (m *timerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case " ":
			if m.status == "Timer paused" {
				m.status = "Timer running"
				return m, tickCmd
			}
			m.status = "Timer paused"
		case "r":
			m.reset()
		}
	case tickMsg:
		m.status = "Timer running"
		return m, tickCmd
	}
	return m, nil
}

func (m *timerModel) View() string {
	return activeModelStyle.Render(fmt.Sprintf("Timer: %s", m.status))
}

func (m *timerModel) reset() {
	m.status = "Timer ready"
}

type spinnerModel struct {
	spinner spinner.Model
}

func newSpinnerModel() tea.Model {
	s := spinner.New()
	s.Style = spinnerStyle
	return &spinnerModel{spinner: s}
}

func (m *spinnerModel) Init() tea.Cmd {
	return m.spinner.Tick
}

func (m *spinnerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(spinner.TickMsg(msg))
		return m, cmd
	}
	return m, nil
}

func (m *spinnerModel) View() string {
	return activeModelStyle.Render(fmt.Sprintf("Spinner: %s", m.spinner.View()))
}

type counterModel struct {
	count int
}

func newCounterModel() tea.Model {
	return &counterModel{count: 0}
}

func (m *counterModel) Init() tea.Cmd {
	return nil
}

func (m *counterModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "k":
			m.count++
		case "j":
			m.count--
		case "0":
			m.count = 0
		}
	}
	return m, nil
}

func (m *counterModel) View() string {
	return activeModelStyle.Render(fmt.Sprintf("Counter: %d", m.count))
}

type tickMsg time.Time

func tickCmd() tea.Msg {
	time.Sleep(time.Second)
	return tickMsg{}
}

func main() {
	m := model{
		views: []tea.Model{
			newCounterModel(),
			newTimerModel(),
			newSpinnerModel(),
		},
	}
	if _, err := tea.NewProgram(m, tea.WithAltScreen()).Run(); err != nil {
		fmt.Println("Error running program:", err)
		os.Exit(1)
	}
}

var (
	focusedModelStyle = lipgloss.NewStyle().Width(15).Height(5).Align(lipgloss.Center).BorderStyle(lipgloss.NormalBorder()).BorderForeground(lipgloss.Color("63"))
	unfocusedModelStyle = focusedModelStyle.Copy().BorderForeground(lipgloss.Color("238"))

	spinnerStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))
	activeModelStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))
	helpStyle        = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
)
