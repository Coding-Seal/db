package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/Coding-Seal/db-curs/internal/domain"
)

type GoodsRepo struct {
	db *sql.DB
}

func NewGoodsRepo(db *sql.DB) *GoodsRepo {
	return &GoodsRepo{
		db: db,
	}
}

func (r *GoodsRepo) AllGoods(ctx context.Context) ([]*domain.Good, error) {
	var goods []*domain.Good

	rows, err := r.db.QueryContext(ctx, "SELECT * FROM get_all_goods_with_amounts();")
	if err != nil {
		return goods, fmt.Errorf("failed to get all goods: %w", err)
	}

	for rows.Next() {
		good := &domain.Good{}

		err := rows.Scan(&good.ID, &good.Name, &good.Priority, &good.AmountWh1, &good.AmountWh2)
		if err != nil {
			return goods, fmt.Errorf("failed to get all goods: %w", err)
		}

		goods = append(goods, good)
	}

	if err := rows.Err(); err != nil {
		return goods, fmt.Errorf("failed to get all goods: %w", err)
	}

	return goods, nil
}

func (r *GoodsRepo) GoodByID(ctx context.Context, good_id uint) (*domain.Good, error) {
	var good domain.Good

	row := r.db.QueryRowContext(ctx, "SELECT * FROM get_good_by_id($1);", good_id)

	err := row.Scan(&good.ID, &good.Name, &good.Priority, &good.AmountWh1, &good.AmountWh2)
	if err != nil {
		return nil, fmt.Errorf("failed to get good by id: %w", err)
	}

	return &good, nil
}

func (r *GoodsRepo) CreateGood(ctx context.Context, good *domain.Good) error {
	row := r.db.QueryRowContext(ctx,
		"SELECT * FROM insert_good($1, $2, $3, $4);",
		good.Name, good.Priority, good.AmountWh1, good.AmountWh2)

	err := row.Scan(&good.ID)
	if err != nil {
		return fmt.Errorf("failed to get insert good: %w", err)
	}

	return nil
}

func (r *GoodsRepo) GoodDemand(ctx context.Context, goodID uint, start, end time.Time) ([]domain.DemandPoint, error) {
	var demand []domain.DemandPoint

	rows, err := r.db.QueryContext(ctx, "SELECT * FROM get_good_demand($1, $2, $3);", goodID, start, end)
	if err != nil {
		return demand, fmt.Errorf("failed to get all goods: %w", err)
	}

	for rows.Next() {
		demandPoint := domain.DemandPoint{}

		err := rows.Scan(&demandPoint.Time, &demandPoint.Demand)
		if err != nil {
			return demand, fmt.Errorf("failed to get all goods: %w", err)
		}

		demand = append(demand, demandPoint)
	}

	if err := rows.Err(); err != nil {
		return demand, fmt.Errorf("failed to get all goods: %w", err)
	}

	return demand, nil
}

func (r *GoodsRepo) DeleteGood(ctx context.Context, goodID uint) error {
	_, err := r.db.ExecContext(ctx, "CALL delete_good($1)", goodID)
	if err != nil {
		return fmt.Errorf("failed to delete good: %w", err)
	}

	return nil
}

func (r *GoodsRepo) UpdateGood(ctx context.Context, good *domain.Good) error {
	_, err := r.db.ExecContext(ctx,
		"CALL update_good($1, $2, $3, $4, $5)",
		good.ID, good.Name, good.Priority, good.AmountWh1, good.AmountWh2)
	if err != nil {
		return fmt.Errorf("failed to update good: %w", err)
	}

	return nil
}

func (r *GoodsRepo) BestPerformingGoods(ctx context.Context) ([]*domain.PerformingGood, error) {
	var bestGoods []*domain.PerformingGood

	rows, err := r.db.QueryContext(ctx, "SELECT * FROM get_best_performing_goods();")
	if err != nil {
		return bestGoods, fmt.Errorf("failed to get best goods: %w", err)
	}

	for rows.Next() {
		good := domain.PerformingGood{}

		err := rows.Scan(&good.ID, &good.Name, &good.Demand)
		if err != nil {
			return bestGoods, fmt.Errorf("failed to get best goods: %w", err)
		}

		bestGoods = append(bestGoods, &good)
	}

	if err := rows.Err(); err != nil {
		return bestGoods, fmt.Errorf("failed to get best goods: %w", err)
	}

	return bestGoods, nil
}
