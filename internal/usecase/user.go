package usecase

import (
	"context"

	"github.com/Coding-Seal/db-curs/internal/adapters/postgres"
	"github.com/Coding-Seal/db-curs/internal/domain"
)

type User struct {
	*postgres.UserRepo
}

func NewUser(userRepo *postgres.UserRepo) *User {
	return &User{UserRepo: userRepo}
}

func (u *User) UpdateUser(ctx context.Context, user *domain.User, shouldUpdatePassword bool) error {
	oldUser, err := u.UserRepo.UserByID(ctx, user.ID)
	if err != nil {
		return err
	}

	if !shouldUpdatePassword {
		user.PassHash = oldUser.PassHash
	}

	return u.UserRepo.UpdateUser(ctx, user)
}
