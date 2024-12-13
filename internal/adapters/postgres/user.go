package postgres

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/Coding-Seal/db-curs/internal/domain"
)

type UserRepo struct {
	db *sql.DB
}

func NewUserRepo(db *sql.DB) *UserRepo {
	return &UserRepo{
		db: db,
	}
}

func (r *UserRepo) UserByLogin(ctx context.Context, login string) (*domain.User, error) {
	var user domain.User

	row := r.db.QueryRowContext(ctx, "SELECT * FROM get_user_by_login($1);", login)

	err := row.Scan(&user.ID, &user.Login, &user.PassHash, &user.Role)
	if err != nil {
		return nil, fmt.Errorf("failed to get user by login: %w", err)
	}

	return &user, nil
}

func (r *UserRepo) UserByID(ctx context.Context, userID uint) (*domain.User, error) {
	var user domain.User

	row := r.db.QueryRowContext(ctx, "SELECT * FROM get_user_by_id($1);", userID)

	err := row.Scan(&user.ID, &user.Login, &user.PassHash, &user.Role)
	if err != nil {
		return nil, fmt.Errorf("failed to get user by id: %w", err)
	}

	return &user, nil
}

func (r *UserRepo) CreateUser(ctx context.Context, user *domain.User) error {
	row := r.db.QueryRowContext(ctx, "SELECT insert_user($1, $2, $3)", user.Login, user.PassHash, user.Role)

	err := row.Scan(&user.ID)
	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

func (r *UserRepo) UpdateUser(ctx context.Context, user *domain.User) error {
	_, err := r.db.ExecContext(ctx, "CALL update_user($1, $2, $3, $4)", user.ID, user.Login, user.PassHash, user.Role)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

func (r *UserRepo) AllUsers(ctx context.Context) ([]*domain.User, error) {
	var users []*domain.User

	rows, err := r.db.QueryContext(ctx, "SELECT * FROM get_all_users();")
	if err != nil {
		return users, fmt.Errorf("failed to get all users: %w", err)
	}

	for rows.Next() {
		user := &domain.User{}

		err := rows.Scan(&user.ID, &user.Login, &user.PassHash, &user.Role)
		if err != nil {
			return users, fmt.Errorf("failed to get all users: %w", err)
		}

		users = append(users, user)
	}

	if err := rows.Err(); err != nil {
		return users, fmt.Errorf("failed to get all users: %w", err)
	}

	return users, nil
}

func (r *UserRepo) DeleteUser(ctx context.Context, userID uint) error {
	_, err := r.db.ExecContext(ctx, "CALL delete_user($1)", userID)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	return nil
}
