package feed

import (
	"testing"

	"github.com/mmcdole/gofeed"
)

func TestNormalizeEntry_DedupKey(t *testing.T) {
	tests := map[string]struct {
		entry *gofeed.Item
		want  string
	}{
		"GUID present": {
			entry: &gofeed.Item{GUID: "guid-123", Link: "http://articles.test/a"},
			want:  "guid-123",
		},
		"GUID missing falls back to link": {
			entry: &gofeed.Item{Link: "http://articles.test/a"},
			want:  "http://articles.test/a",
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			got := normalizeEntry(tt.entry, 1)
			if got.dedupKey != tt.want {
				t.Errorf("got dedupKey %q, want %q", got.dedupKey, tt.want)
			}
		})
	}
}
