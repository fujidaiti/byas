package paper

import (
	"testing"
	"time"
)

func Test_findScheduleSegment(t *testing.T) {
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
			got1, got2 := findScheduleSegment(tt.now, tt.ss)
			if !got1.Equal(tt.last) {
				t.Errorf("Expected last: %s, got: %s", tt.last, got1)
			}
			if !got2.Equal(tt.next) {
				t.Errorf("Expected next: %s, got: %s", tt.next, got2)
			}
		})
	}
}
