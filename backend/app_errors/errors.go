package apperrors

type SomethingWentWrongError struct {
}

func (e SomethingWentWrongError) Error() string {
	return "Something went wrong"
}
