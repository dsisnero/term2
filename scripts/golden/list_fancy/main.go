package main

import (
	"flag"
	"math/rand"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/list"
	"charm.land/lipgloss/v2"
)

var sgrRE = regexp.MustCompile(`\x1b\[[0-9;]*m`)

type styles struct {
	app           lipgloss.Style
	title         lipgloss.Style
	statusMessage lipgloss.Style
}

func newStyles(darkBG bool) styles {
	lightDark := lipgloss.LightDark(darkBG)
	return styles{
		app: lipgloss.NewStyle().Padding(1, 2),
		title: lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFDF5")).
			Background(lipgloss.Color("#25A065")).
			Padding(0, 1),
		statusMessage: lipgloss.NewStyle().
			Foreground(lightDark(lipgloss.Color("#04B575"), lipgloss.Color("#04B575"))),
	}
}

type item struct {
	title       string
	description string
}

func (i item) Title() string       { return i.title }
func (i item) Description() string { return i.description }
func (i item) FilterValue() string { return i.title }

type delegateKeyMap struct {
	choose key.Binding
	remove key.Binding
}

func newDelegateKeyMap() *delegateKeyMap {
	return &delegateKeyMap{
		choose: key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "choose")),
		remove: key.NewBinding(key.WithKeys("x", "backspace"), key.WithHelp("x", "delete")),
	}
}

func newItemDelegate(keys *delegateKeyMap, styles *styles) list.DefaultDelegate {
	d := list.NewDefaultDelegate()
	help := []key.Binding{keys.choose, keys.remove}
	d.ShortHelpFunc = func() []key.Binding { return help }
	d.FullHelpFunc = func() [][]key.Binding { return [][]key.Binding{help} }
	return d
}

type randomItemGenerator struct {
	titles     []string
	descs      []string
	titleIndex int
	descIndex  int
	mtx        *sync.Mutex
	shuffle    *sync.Once
}

func (r *randomItemGenerator) reset() {
	r.mtx = &sync.Mutex{}
	r.shuffle = &sync.Once{}
	r.titles = []string{
		"Artichoke", "Baking Flour", "Bananas", "Barley", "Bean Sprouts", "Bitter Melon", "Black Cod", "Blood Orange", "Brown Sugar", "Cashew Apple",
		"Cashews", "Cat Food", "Coconut Milk", "Cucumber", "Curry Paste", "Currywurst", "Dill", "Dragonfruit", "Dried Shrimp", "Eggs",
		"Fish Cake", "Furikake", "Garlic", "Gherkin", "Ginger", "Granulated Sugar", "Grapefruit", "Green Onion", "Hazelnuts", "Heavy whipping cream",
		"Honey Dew", "Horseradish", "Jicama", "Kohlrabi", "Leeks", "Lentils", "Licorice Root", "Meyer Lemons", "Milk", "Molasses",
		"Muesli", "Nectarine", "Niagamo Root", "Nopal", "Nutella", "Oat Milk", "Oatmeal", "Olives", "Papaya", "Party Gherkin",
		"Peppers", "Persian Lemons", "Pickle", "Pineapple", "Plantains", "Pocky", "Powdered Sugar", "Quince", "Radish", "Ramps",
		"Star Anise", "Sweet Potato", "Tamarind", "Unsalted Butter", "Watermelon", "Weißwurst", "Yams", "Yeast", "Yuzu", "Snow Peas",
	}
	r.descs = []string{
		"A little weird", "Bold flavor", "Can’t get enough", "Delectable", "Expensive", "Expired", "Exquisite", "Fresh", "Gimme", "In season",
		"Kind of spicy", "Looks fresh", "Looks good to me", "Maybe not", "My favorite", "Oh my", "On sale", "Organic", "Questionable", "Really fresh",
		"Refreshing", "Salty", "Scrumptious", "Delectable", "Slightly sweet", "Smells great", "Tasty", "Too ripe", "At last", "What?",
		"Wow", "Yum", "Maybe", "Sure, why not?",
	}
	r.shuffle.Do(func() {
		shuf := func(x []string) { rand.Shuffle(len(x), func(i, j int) { x[i], x[j] = x[j], x[i] }) }
		shuf(r.titles)
		shuf(r.descs)
	})
}

func (r *randomItemGenerator) next() item {
	if r.mtx == nil {
		r.reset()
	}
	r.mtx.Lock()
	defer r.mtx.Unlock()
	it := item{title: r.titles[r.titleIndex], description: r.descs[r.descIndex]}
	r.titleIndex = (r.titleIndex + 1) % len(r.titles)
	r.descIndex = (r.descIndex + 1) % len(r.descs)
	return it
}

func renderListFancy(width, height int) string {
	rand.Seed(1)
	st := newStyles(false)
	delegateKeys := newDelegateKeyMap()
	delegate := newItemDelegate(delegateKeys, &st)

	var gen randomItemGenerator
	items := make([]list.Item, 24)
	for i := range 24 {
		items[i] = gen.next()
	}

	l := list.New(items, delegate, 0, 0)
	l.Title = "Groceries"
	l.Styles.Title = st.title
	l.AdditionalFullHelpKeys = func() []key.Binding { return nil }

	hFrame, vFrame := st.app.GetFrameSize()
	l.SetSize(width-hFrame, height-vFrame)

	out := st.app.Render(l.View())
	out = strings.ReplaceAll(out, "\r\n", "\n")
	out = strings.ReplaceAll(out, "\r", "\n")
	out = sgrRE.ReplaceAllString(out, "")
	return out
}

func main() {
	outPath := flag.String("out", "", "output golden file path")
	width := flag.Int("width", 80, "window width")
	height := flag.Int("height", 24, "window height")
	flag.Parse()
	if *outPath == "" {
		panic("missing -out")
	}
	out := renderListFancy(*width, *height)
	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(out), 0o644); err != nil {
		panic(err)
	}
}

