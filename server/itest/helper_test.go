package itest

import "testing"

func TestIsDistinct(t *testing.T) {
	test := map[string]struct {
		input []int
		want  bool
	}{
		"empty":          {input: []int{}, want: true},
		"single element": {input: []int{1}, want: true},
		"all distinct":   {input: []int{1, 2, 3}, want: true},
		"duplicate":      {input: []int{1, 2, 1}, want: false},
		"all same":       {input: []int{1, 1, 1}, want: false},
	}

	for name, tt := range test {
		t.Run(name, func(t *testing.T) {
			if got := isDistinct(tt.input); got != tt.want {
				t.Errorf("input=%v:\ngot %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}

func TestIsDistinct_String(t *testing.T) {
	test := map[string]struct {
		input []string
		want  bool
	}{
		"empty":                   {input: []string{}, want: true},
		"all distinct":            {input: []string{"a", "b", "c"}, want: true},
		"duplicate":               {input: []string{"a", "b", "a"}, want: false},
		"empty strings duplicate": {input: []string{"", ""}, want: false},
	}

	for name, tt := range test {
		t.Run(name, func(t *testing.T) {
			if got := isDistinct(tt.input); got != tt.want {
				t.Errorf("input=%v:\ngot %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}

func TestIsDistinct_Struct(t *testing.T) {
	type point struct{ x, y int }

	test := map[string]struct {
		input []point
		want  bool
	}{
		"all distinct": {input: []point{{1, 2}, {2, 1}, {1, 1}}, want: true},
		"duplicate":    {input: []point{{1, 2}, {3, 4}, {1, 2}}, want: false},
	}

	for name, tt := range test {
		t.Run(name, func(t *testing.T) {
			if got := isDistinct(tt.input); got != tt.want {
				t.Errorf("input=%v:\ngot %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}
