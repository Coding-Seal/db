package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	"github.com/Coding-Seal/db-curs/internal/adapters/postgres"
	"github.com/Coding-Seal/db-curs/internal/ports/http"
	"github.com/Coding-Seal/db-curs/internal/usecase"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatalln(err)
	}

	dbHost := os.Getenv("DB_HOST")
	dbName := os.Getenv("DB_NAME")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")

	//nolint:nosprintfhostport
	dbUrl := fmt.Sprintf("postgres://%s:%s@%s:5432/%s?sslmode=disable", dbUser, dbPassword, dbHost, dbName)

	conn, err := sql.Open("pgx", dbUrl)
	if err != nil {
		log.Fatal(err)
	}

	userRepo := postgres.NewUserRepo(conn)
	userUc := usecase.NewUser(userRepo)

	goodRepo := postgres.NewGoodsRepo(conn)
	goodUc := usecase.NewGood(goodRepo)

	salesRepo := postgres.NewSalesRepo(conn)
	salesUc := usecase.NewSale(salesRepo)

	s := http.NewServer(userUc, goodUc, salesUc)

	// err = addAdmin(userRepo)
	// if err != nil {
	// 	log.Fatalln(err)
	// }

	s.Start()
}

// func addAdmin(repo *postgres.UserRepo) error {
// 	adminLogin := os.Getenv("ADMIN_LOGIN")
// 	adminPassword := os.Getenv("ADMIN_PASSWORD")

// 	hashPass, err := bcrypt.GenerateFromPassword([]byte(adminPassword), bcrypt.DefaultCost)
// 	if err != nil {
// 		return err
// 	}

// 	admin := &domain.User{Login: adminLogin, PassHash: hashPass, Role: domain.ADMIN}

// 	return repo.CreateUser(context.TODO(), admin)
// }
