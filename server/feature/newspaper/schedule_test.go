package newspaper

import (
	"testing"
	"time"
)

func TestEditorialInterval_Valid(t *testing.T) {
	fday := func(h, m, s int) time.Time {
		return time.Date(2000, 4, 1, h, m, s, 0, time.UTC)
	}

	tests := map[string]struct {
		ei   EditorialInterval
		want bool
	}{
		"valid: next after last": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			want: true,
		},
		"invalid: next equals last": {
			ei:   EditorialInterval{Next: fday(6, 0, 0), Last: fday(6, 0, 0)},
			want: false,
		},
		"invalid: next before last": {
			ei:   EditorialInterval{Next: fday(6, 0, 0), Last: fday(13, 0, 0)},
			want: false,
		},
		"invalid: next is zero": {
			ei:   EditorialInterval{Last: fday(6, 0, 0)},
			want: false,
		},
		"invalid: last is zero": {
			ei:   EditorialInterval{Next: fday(13, 0, 0)},
			want: false,
		},
		"invalid: both zero": {
			ei:   EditorialInterval{},
			want: false,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := tt.ei.Valid(); got != tt.want {
				t.Errorf("Valid() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestEditorialInterval_Contains(t *testing.T) {
	fday := func(h, m, s int) time.Time {
		return time.Date(2000, 4, 1, h, m, s, 0, time.UTC)
	}

	tests := map[string]struct {
		ei   EditorialInterval
		t    time.Time
		want bool
	}{
		"inside the interval": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(9, 30, 0),
			want: true,
		},
		"just after last": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(6, 0, 1),
			want: true,
		},
		"just before next": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(12, 59, 59),
			want: true,
		},
		"exactly at last (exclusive)": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(6, 0, 0),
			want: false,
		},
		"exactly at next (exclusive)": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(13, 0, 0),
			want: false,
		},
		"before last": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(5, 0, 0),
			want: false,
		},
		"after next": {
			ei:   EditorialInterval{Next: fday(13, 0, 0), Last: fday(6, 0, 0)},
			t:    fday(14, 0, 0),
			want: false,
		},
		"invalid interval": {
			ei:   EditorialInterval{Next: fday(23, 0, 0), Last: time.Time{}},
			t:    fday(12, 0, 0),
			want: false,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := tt.ei.Contains(tt.t); got != tt.want {
				t.Errorf("Contains(%s) = %v, want %v", tt.t, got, tt.want)
			}
		})
	}
}

func Test_findEditorialInterval(t *testing.T) {
	fday := func(h, m, s int) time.Time {
		return time.Date(2000, 4, 1, h, m, s, 0, time.UTC)
	}

	tests := map[string]struct {
		now  time.Time
		ss   []time.Time
		last time.Time
		next time.Time
	}{
		"within section 1": {
			now:  fday(9, 35, 42),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(6, 0, 0),
			next: fday(13, 0, 0),
		},
		"within section 2": {
			now:  fday(15, 0, 12),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(13, 0, 0),
			next: fday(19, 0, 0),
		},
		"before first schedule in the day": {
			now:  fday(2, 50, 0),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(19, 0, 0).AddDate(0, 0, -1),
			next: fday(6, 0, 0),
		},
		"after last schedule in the day": {
			now:  fday(23, 10, 56),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(19, 0, 0),
			next: fday(6, 0, 0).AddDate(0, 0, 1),
		},
		"exactly at the first schedule point": {
			now:  fday(6, 0, 0),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(6, 0, 0),
			next: fday(13, 0, 0),
		},
		"exactly at the middle schedule point": {
			now:  fday(13, 0, 0),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(13, 0, 0),
			next: fday(19, 0, 0),
		},
		"exactly at the last schedule point": {
			now:  fday(19, 0, 0),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(19, 0, 0),
			next: fday(6, 0, 0).AddDate(0, 0, 1),
		},
		"at midnight": {
			now:  fday(0, 0, 0),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(19, 0, 0).AddDate(0, 0, -1),
			next: fday(6, 0, 0),
		},
		"at midnight and first schedule point": {
			now:  fday(0, 0, 0),
			ss:   []time.Time{fday(0, 0, 0), fday(6, 0, 0), fday(13, 0, 0)},
			last: fday(0, 0, 0),
			next: fday(6, 0, 0),
		},
		"end of the day": {
			now:  fday(23, 59, 59),
			ss:   []time.Time{fday(6, 0, 0), fday(13, 0, 0), fday(19, 0, 0)},
			last: fday(19, 0, 0),
			next: fday(6, 0, 0).AddDate(0, 0, 1),
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			got := findEditorialInterval(tt.now, tt.ss)
			if !got.Last.Equal(tt.last) {
				t.Errorf("Expected last: %s, got: %s", tt.last, got.Last)
			}
			if !got.Next.Equal(tt.next) {
				t.Errorf("Expected next: %s, got: %s", tt.next, got.Next)
			}
		})
	}
}
