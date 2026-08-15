// Package server exposes metadata about this build of the server app.
package server

import (
	_ "embed"
	"encoding/json"
)

//go:embed version.json
var versionFile []byte

// Version is the version name this build ships as, baked in from
// server/version.json at build time. See DEPLOY.md.
var Version = func() string {
	var v struct {
		VersionName string `json:"versionName"`
	}
	if err := json.Unmarshal(versionFile, &v); err != nil {
		panic(err)
	}
	return v.VersionName
}()
