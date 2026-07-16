package user_test

import (
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/fujidaiti/paperdoll/feature/user"
)

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		p       string
		wantErr bool
	}{
		{p: "", wantErr: true},
		{p: strings.Repeat("a", 14), wantErr: true},
		{p: strings.Repeat("a", 15), wantErr: false},
		{p: strings.Repeat("a", 64), wantErr: false},
		{p: strings.Repeat("a", 65), wantErr: true},
		{p: `Ab1!@#$%^&*()_+`, wantErr: false},
		{p: "  password123  ", wantErr: false},
		{p: strings.Repeat(" ", 15), wantErr: false},
		{p: strings.Repeat("~", 15), wantErr: false},
		{p: strings.Repeat("\x1f", 15) + "a", wantErr: true},
		{p: strings.Repeat("a", 14) + "\x7f", wantErr: true},
		{p: strings.Repeat("a", 14) + "\n", wantErr: true},
		{p: strings.Repeat("a", 14) + "\t", wantErr: true},
		{p: strings.Repeat("a", 14) + "\x00", wantErr: true},
		{p: strings.Repeat("a", 14) + "é", wantErr: true},
		{p: strings.Repeat("パスワード", 4), wantErr: true},
	}
	for _, tt := range tests {
		t.Run(fmt.Sprintf(`"%s"`, tt.p), func(t *testing.T) {
			got, err := user.ValidatePassword(tt.p)
			if tt.wantErr {
				if !errors.Is(err, user.ErrPswdInvalid) {
					t.Fatalf("f(%q) error = %v, want %v", tt.p, err, user.ErrPswdInvalid)
				}
				if got != (user.ValidPassword{}) {
					t.Errorf("f(%q) = %+v, want zero value on error", tt.p, got)
				}
			} else if err != nil {
				t.Fatalf("f(%q) unexpected error: %v", tt.p, err)
			}
		})
	}
}

func TestValidateEmail(t *testing.T) {
	tests := []struct {
		addr    string
		wantErr bool
	}{
		{addr: "", wantErr: true},
		{addr: "user", wantErr: true},
		{addr: "@", wantErr: true},
		{addr: "user@example.com", wantErr: false},
		{addr: "USER@EXAMPLE.CO.JP", wantErr: false},
		{addr: "user+tag@example.com", wantErr: false},
		{addr: "first.middle.last@example.com", wantErr: false},
		{addr: "user@localhost", wantErr: false},
		{addr: "userexample.com", wantErr: true},
		{addr: "@example.com", wantErr: true},
		{addr: "user@", wantErr: true},
		{addr: "user@@example.com", wantErr: true},
		{addr: "user name@example.com", wantErr: true},
		{addr: "user@exa mple.com", wantErr: true},
		{addr: "Name <user@example.com>", wantErr: true},
		{addr: " user@example.com", wantErr: true},
		{addr: "user@example.com ", wantErr: true},
		{addr: "üser@example.com", wantErr: true},
		{addr: "user@ｅｘａｍｐｌｅ.ｃｏ.ｊｐ", wantErr: true},
		{addr: "user@度メイン.co.jp", wantErr: true},
		{addr: "日本語@example.com", wantErr: true},
		{addr: "😀@example.com", wantErr: true},
	}
	for _, tt := range tests {
		t.Run(fmt.Sprintf(`"%s"`, tt.addr), func(t *testing.T) {
			got, err := user.ValidateEmail(tt.addr)
			if tt.wantErr {
				if !errors.Is(err, user.ErrEmailInvalid) {
					t.Fatalf("f(%q) error = %v, want %v", tt.addr, err, user.ErrEmailInvalid)
				}
				if got != (user.ValidEmail{}) {
					t.Errorf("f(%q) = %+v, want zero value on error", tt.addr, got)
				}
			} else if err != nil {
				t.Fatalf("f(%q) unexpected error: %v", tt.addr, err)
			}
		})
	}
}
