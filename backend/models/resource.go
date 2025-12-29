package models

type PaginatedResponse struct {
	Pages        int
	TotalPages   int
	TotalResults int
	Result       any
}
