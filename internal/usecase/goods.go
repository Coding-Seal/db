package usecase

import "github.com/Coding-Seal/db-curs/internal/adapters/postgres"

type Good struct {
	*postgres.GoodsRepo
}

func NewGood(goodRepo *postgres.GoodsRepo) *Good {
	return &Good{GoodsRepo: goodRepo}
}
