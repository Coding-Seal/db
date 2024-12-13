package db

import (
	"context"
	"database/sql"
	"embed"
	"errors"
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	pgx_mgr "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
)

//go:embed migrations
var migrations embed.FS

func MigrateUp(ctx context.Context, db *sql.DB) error {
	src, err := iofs.New(migrations, "migrations")
	if err != nil {
		return fmt.Errorf("error creating migration src: %w", err)
	}

	driver, err := pgx_mgr.WithInstance(db, &pgx_mgr.Config{})
	if err != nil {
		return fmt.Errorf("error creating driver: %w", err)
	}

	mgr, err := migrate.NewWithInstance("iofs", src, "pgx5", driver)
	if err != nil {
		return fmt.Errorf("error creating migrate: %w", err)
	}

	stopMgr := mgr.GracefulStop

	go func() {
		<-ctx.Done()
		stopMgr <- true
	}()

	// err = mgr.Drop()
	// if err != nil && !errors.Is(err, migrate.ErrNoChange) {
	// 	return fmt.Errorf("error dropping db : %w", err)
	// }

	err = mgr.Up()
	if err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return fmt.Errorf("error running migrations : %w", err)
	}

	return nil
}
