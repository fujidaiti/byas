package user

import (
	"errors"
	"strings"
	"testing"
)

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name, p string
		wantErr bool
	}{
		{name: "min length (15 chars)", p: strings.Repeat("a", 15)},
		{name: "max length (64 chars)", p: strings.Repeat("a", 64)},
		{name: "too short (14 chars)", p: strings.Repeat("a", 14), wantErr: true},
		{name: "too long (65 chars)", p: strings.Repeat("a", 65), wantErr: true},
		{name: "mixed symbols", p: `Ab1!@#$%^&*()_+`},
		{name: "leading and trailing spaces", p: "  password123  "},
		{name: "all spaces", p: "               "},
		{name: "empty", p: "", wantErr: true},
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
				if want := ErrPswdInvalid; !errors.Is(err, want) {
					t.Fatalf("got %v, want %v", err, want)
				}
				if got != (ValidPassword{}) {
					t.Errorf("got %v, want zero value on error", got)
				}
			} else if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}

func TestParseEmail(t *testing.T) {
	tests := []struct {
		name, addr, want string
		wantErr          bool
	}{
		{name: "simple address", addr: "user@example.com"},
		{name: "uppercase", addr: "USER@EXAMPLE.CO.JP", want: "user@example.co.jp"},
		{name: "plus tag", addr: "user+tag@example.com", want: "user+tag@example.com"},
		{
			name: "dotted local part",
			addr: "first.middle.last@example.com",
			want: "first.middle.last@example.com",
		},
		{name: "localhost domain", addr: "user@localhost", want: "user@localhost"},
		{name: "empty", addr: "", wantErr: true},
		{name: "no @", addr: "user", wantErr: true},
		{name: "just @", addr: "@", wantErr: true},
		{name: "missing @", addr: "userexample.com", wantErr: true},
		{name: "missing local part", addr: "@example.com", wantErr: true},
		{name: "missing domain", addr: "user@", wantErr: true},
		{name: "double @", addr: "user@@example.com", wantErr: true},
		{name: "space in local part", addr: "user name@example.com", wantErr: true},
		{name: "space in domain", addr: "user@exa mple.com", wantErr: true},
		{name: "display name wrapper", addr: "Name <user@example.com>", wantErr: true},
		{name: "leading space", addr: " user@example.com", wantErr: true},
		{name: "trailing space", addr: "user@example.com ", wantErr: true},
		{name: "accented character", addr: "üser@example.com", wantErr: true},
		{name: "non-ASCII domain", addr: "user@ｅｘａｍｐｌｅ.ｃｏ.ｊｐ", wantErr: true},
		{name: "non-ASCII local part", addr: "日本語😀@example.com", wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
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
