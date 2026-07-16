package integration_test

// isDistinct checks if all comparable elements in v are uniqueue.
func isDistinct[T comparable](v []T) bool {
	seen := make(map[T]struct{}, len(v))
	for _, x := range v {
		if _, exists := seen[x]; exists {
			return false
		}
		seen[x] = struct{}{}
	}
	return true
}
