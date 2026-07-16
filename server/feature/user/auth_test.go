package user_test

import (
	"errors"
	"strings"
	"testing"

	"github.com/fujidaiti/paperdoll/feature/user"
)

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name, p string
		wantErr bool
	}{
		{
			name:    "empty string",
			p:       "",
			wantErr: true,
		},
		{
			name:    "14 chars is too short",
			p:       strings.Repeat("a", 14),
			wantErr: true,
		},
		{
			name:    "15 chars is the minimum valid length",
			p:       strings.Repeat("a", 15),
			wantErr: false,
		},
		{
			name:    "64 chars is the maximum valid length",
			p:       strings.Repeat("a", 64),
			wantErr: false,
		},
		{
			name:    "65 chars is too long",
			p:       strings.Repeat("a", 65),
			wantErr: true,
		},
		{
			name:    "mixed printable ASCII",
			p:       `Ab1!@#$%^&*()_+`,
			wantErr: false,
		},
		{
			name:    "leading and trailing spaces are printable",
			p:       "  password123  ",
			wantErr: false,
		},
		{
			name:    "space (0x20) is the lowest valid char",
			p:       strings.Repeat(" ", 15),
			wantErr: false,
		},
		{
			name:    "tilde (0x7E) is the highest valid char",
			p:       strings.Repeat("~", 15),
			wantErr: false,
		},
		{
			name:    "unit separator (0x1F) is just below the valid range",
			p:       strings.Repeat("\x1f", 15) + "a",
			wantErr: true,
		},
		{
			name:    "DEL (0x7F) is just above the valid range",
			p:       strings.Repeat("a", 14) + "\x7f",
			wantErr: true,
		},
		{
			name:    "newline is a non-printable control char",
			p:       strings.Repeat("a", 14) + "\n",
			wantErr: true,
		},
		{
			name:    "tab is a non-printable control char",
			p:       strings.Repeat("a", 14) + "\t",
			wantErr: true,
		},
		{
			name:    "null byte is a non-printable control char",
			p:       strings.Repeat("a", 14) + "\x00",
			wantErr: true,
		},
		{
			name:    "non-ASCII unicode rune is rejected",
			p:       strings.Repeat("a", 14) + "é",
			wantErr: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
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
