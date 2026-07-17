package user

import (
	"errors"
	"strings"
	"testing"
)

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name    string
		p       string
		wantErr bool
	}{
		{name: "empty", p: "", wantErr: true},
		{name: "too short (14 chars)", p: strings.Repeat("a", 14), wantErr: true},
		{name: "min length (15 chars)", p: strings.Repeat("a", 15), wantErr: false},
		{name: "max length (64 chars)", p: strings.Repeat("a", 64), wantErr: false},
		{name: "too long (65 chars)", p: strings.Repeat("a", 65), wantErr: true},
		{name: "mixed symbols", p: `Ab1!@#$%^&*()_+`, wantErr: false},
		{name: "leading and trailing spaces", p: "  password123  ", wantErr: false},
		{name: "all spaces", p: "               ", wantErr: false},
		{name: "DEL character", p: "aaaaaaaaaaaaaa\x7f", wantErr: true},
		{name: "newline", p: "aaaaaaaaaaaaaa\n", wantErr: true},
		{name: "tab", p: "aaaaaaaaaaaaaa\t", wantErr: true},
		{name: "null byte", p: "aaaaaaaaaaaaaa\x00", wantErr: true},
		{name: "non-ASCII character", p: "aaaaaaaaaaaaaaé", wantErr: true},
		{name: "non-ASCII character 2", p: "パスワードパスワード", wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ValidatePassword(tt.p)
			if tt.wantErr {
				if !errors.Is(err, ErrPswdInvalid) {
					t.Fatalf("f(%q) error = %v, want %v", tt.p, err, ErrPswdInvalid)
				}
				if got != (ValidPassword{}) {
					t.Errorf("f(%q) = %+v, want zero value on error", tt.p, got)
				}
			} else if err != nil {
				t.Fatalf("f(%q) unexpected error: %v", tt.p, err)
			}
		})
	}
}

func TestParseEmail(t *testing.T) {
	tests := map[string]struct {
		addr, want string
		wantErr    bool
	}{
		"simple address":       {addr: "user@example.com"},
		"uppercase":            {addr: "USER@EXAMPLE.CO.JP", want: "user@example.co.jp"},
		"plus tag":             {addr: "user+tag@example.com", want: "user+tag@example.com"},
		"dotted local part":    {addr: "first.middle.last@example.com", want: "first.middle.last@example.com"},
		"localhost domain":     {addr: "user@localhost", want: "user@localhost"},
		"empty":                {addr: "", wantErr: true},
		"no @":                 {addr: "user", wantErr: true},
		"just @":               {addr: "@", wantErr: true},
		"missing @":            {addr: "userexample.com", wantErr: true},
		"missing local part":   {addr: "@example.com", wantErr: true},
		"missing domain":       {addr: "user@", wantErr: true},
		"double @":             {addr: "user@@example.com", wantErr: true},
		"space in local part":  {addr: "user name@example.com", wantErr: true},
		"space in domain":      {addr: "user@exa mple.com", wantErr: true},
		"display name wrapper": {addr: "Name <user@example.com>", wantErr: true},
		"leading space":        {addr: " user@example.com", wantErr: true},
		"trailing space":       {addr: "user@example.com ", wantErr: true},
		"accented character":   {addr: "üser@example.com", wantErr: true},
		"non-ASCII domain":     {addr: "user@ｅｘａｍｐｌｅ.ｃｏ.ｊｐ", wantErr: true},
		"non-ASCII local part": {addr: "日本語😀@example.com", wantErr: true},
	}
	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			got, err := ParseEmail(tt.addr)
			if tt.wantErr {
				if !errors.Is(err, ErrEmailInvalid) {
					t.Errorf("got %v, want %v", err, ErrEmailInvalid)
				}
				if got != (CanonicalEmail{}) {
					t.Errorf("got %v, want zero value on error", got)
				}
			} else if err != nil {
				t.Errorf("unexpected error: %v", err)
			}

			if tt.want != "" && got.value != tt.want {
				t.Errorf("got %q, want to be normalized to %q", got.value, tt.want)
			}
		})
	}
}
