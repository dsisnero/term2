package main

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/timer"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// DashboardModel is the main model that contains all panes
type DashboardModel struct {
	counter CounterModel
	spinner SpinnerModel
	timer   TimerModel
	input   InputModel
	width   int
	height  int
}

// CounterModel represents a simple counter pane
type CounterModel struct {
	count int
}

func (m CounterModel) Init() tea.Cmd {
	return nil
}

func (m CounterModel) Update(msg tea.Msg) (CounterModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k":
			m.count++
		case "down", "j":
			m.count--
		}
	}
	return m, nil
}

func (m CounterModel) View() string {
	style := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("62")).
		Padding(1, 2)

	content := fmt.Sprintf("Counter: %d\n\n↑/k: increment\n↓/j: decrement", m.count)
	return style.Render(content)
}

// SpinnerModel represents a spinner pane
type SpinnerModel struct {
	spinner spinner.Model
	running bool
}

func (m SpinnerModel) Init() tea.Cmd {
	return m.spinner.Tick
}

func (m SpinnerModel) Update(msg tea.Msg) (SpinnerModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "s":
			m.running = !m.running
			if m.running {
				return m, m.spinner.Tick
			}
		}
	}

	var cmd tea.Cmd
	m.spinner, cmd = m.spinner.Update(msg)
	return m, cmd
}

func (m SpinnerModel) View() string {
	style := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("205")).
		Padding(1, 2)

	status := "stopped"
	if m.running {
		status = "running"
	}

	content := fmt.Sprintf("Spinner: %s\n\nStatus: %s\n\ns: toggle", m.spinner.View(), status)
	return style.Render(content)
}

// TimerModel represents a timer pane
type TimerModel struct {
	timer   timer.Model
	running bool
}

func (m TimerModel) Init() tea.Cmd {
	return m.timer.Init()
}

func (m TimerModel) Update(msg tea.Msg) (TimerModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "t":
			if !m.running {
				m.running = true
				return m, m.timer.Start()
			} else {
				m.running = false
				return m, m.timer.Stop()
			}
		case "r":
			m.timer = timer.NewWithInterval(10*time.Second, time.Second)
			m.running = false
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.timer, cmd = m.timer.Update(msg)
	return m, cmd
}

func (m TimerModel) View() string {
	style := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("190")).
		Padding(1, 2)

	status := "stopped"
	if m.running {
		status = "running"
	}

	content := fmt.Sprintf("Timer: %s\n\nStatus: %s\n\nt: start/stop\nr: reset", m.timer.View(), status)
	return style.Render(content)
}

// InputModel represents a text input pane
type InputModel struct {
	input textinput.Model
}

func (m InputModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m InputModel) Update(msg tea.Msg) (InputModel, tea.Cmd) {
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m InputModel) View() string {
	style := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("39")).
		Padding(1, 2)

	content := fmt.Sprintf("Text Input\n\n%s\n\nType to enter text", m.input.View())
	return style.Render(content)
}

// Dashboard implementation
func (m DashboardModel) Init() tea.Cmd {
	return tea.Batch(
		m.counter.Init(),
		m.spinner.Init(),
		m.timer.Init(),
		m.input.Init(),
	)
}

func (m DashboardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil
	case tea.KeyMsg:
		if msg.Type == tea.KeyCtrlC || msg.String() == "q" {
			return m, tea.Quit
		}
	}

	var (
		cmd  tea.Cmd
		cmds []tea.Cmd
	)

	// Update each pane concurrently
	m.counter, cmd = m.counter.Update(msg)
	cmds = append(cmds, cmd)

	m.spinner, cmd = m.spinner.Update(msg)
	cmds = append(cmds, cmd)

	m.timer, cmd = m.timer.Update(msg)
	cmds = append(cmds, cmd)

	m.input, cmd = m.input.Update(msg)
	cmds = append(cmds, cmd)

	return m, tea.Batch(cmds...)
}

func (m DashboardModel) View() string {
	if m.width == 0 || m.height == 0 {
		return "Initializing..."
	}

	// Create a 2x2 grid layout
	row1 := lipgloss.JoinHorizontal(
		lipgloss.Top,
		m.counter.View(),
		lipgloss.NewStyle().Width(2).Render(""), // spacer
		m.spinner.View(),
	)

	row2 := lipgloss.JoinHorizontal(
		lipgloss.Top,
		m.timer.View(),
		lipgloss.NewStyle().Width(2).Render(""), // spacer
		m.input.View(),
	)

	// Combine rows with vertical spacing
	dashboard := lipgloss.JoinVertical(
		lipgloss.Left,
		row1,
		lipgloss.NewStyle().Height(1).Render(""), // spacer
		row2,
	)

	// Center the dashboard
	return lipgloss.Place(
		m.width,
		m.height,
		lipgloss.Center,
		lipgloss.Center,
		dashboard,
	)
}

func main() {
	// Initialize the spinner
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))

	// Initialize the timer
	t := timer.NewWithInterval(10*time.Second, time.Second)

	// Initialize the text input
	ti := textinput.New()
	ti.Placeholder = "Type something..."
	ti.Focus()
	ti.CharLimit = 50
	ti.Width = 20

	model := DashboardModel{
		counter: CounterModel{count: 0},
		spinner: SpinnerModel{spinner: s, running: false},
		timer:   TimerModel{timer: t, running: false},
		input:   InputModel{input: ti},
	}

	p := tea.NewProgram(model, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error running program: %v", err)
	}
}