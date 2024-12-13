package usecase

import (
	"github.com/Coding-Seal/db-curs/internal/adapters/postgres"
)

type Sale struct {
	*postgres.SalesRepo
}

func NewSale(salesRepo *postgres.SalesRepo) *Sale {
	return &Sale{SalesRepo: salesRepo}
}
