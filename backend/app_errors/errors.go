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

type NoResourcesFound struct {
}

func (e NoResourcesFound) Error() string {
	return "No resources found"
}


type MaxProfileReachedErorr struct {
}

func (e MaxProfileReachedErorr) Error() string {
	return "Maximum no of profile for a user reached"
}
