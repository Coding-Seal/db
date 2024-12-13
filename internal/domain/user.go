package domain

type Role string

const (
	USER  Role = "User"
	ADMIN Role = "Admin"
)

type User struct {
	ID       uint
	Login    string
	PassHash []byte
	Role     Role
}
