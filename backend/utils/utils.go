package utils

import "math/rand"

func GetRandomString(length int) string {
	const input = "abdcefghijklmnopqrstuvwxyz1234567890"
	var res string

	for range length {
		index := rand.Intn(len(input))

		res += string(input[index])
	}

	return res
}
