package apperrors

type SomethingWentWrongError struct {
}

func (e SomethingWentWrongError) Error() string {
	return "Something went wrong"
}

type UserAlreadyRegisteredError struct {
}

func (e UserAlreadyRegisteredError) Error() string {
	return "User is already registered"
}

type InvalidInput struct {
	Err string
}

func (e InvalidInput) Error() string {
	return e.Err
}
