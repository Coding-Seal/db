package postgres

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/Coding-Seal/db-curs/internal/domain"
)

type SalesRepo struct {
	db *sql.DB
}

func NewSalesRepo(db *sql.DB) *SalesRepo {
	return &SalesRepo{db: db}
}

func (r *SalesRepo) CreateSale(ctx context.Context, sale *domain.Sale) error {
	row := r.db.QueryRowContext(ctx, "SELECT * FROM insert_sale($1, $2)", sale.GoodID, sale.GoodCount)

	err := row.Scan(&sale.ID)
	if err != nil {
		return fmt.Errorf("failed to create sale: %w", err)
	}

	return nil
}

func (r *SalesRepo) AllSales(ctx context.Context) ([]*domain.Sale, error) {
	var sales []*domain.Sale

	rows, err := r.db.QueryContext(ctx, "SELECT * FROM get_all_sales_with_names();")
	if err != nil {
		return sales, fmt.Errorf("failed to get all sales: %w", err)
	}

	for rows.Next() {
		sale := &domain.Sale{}

		err := rows.Scan(&sale.ID, &sale.GoodID, &sale.GoodName, &sale.GoodCount, &sale.CreateDate)
		if err != nil {
			return sales, fmt.Errorf("failed to get all sales: %w", err)
		}

		sales = append(sales, sale)
	}

	if err := rows.Err(); err != nil {
		return sales, fmt.Errorf("failed to get all sales: %w", err)
	}

	return sales, nil
}

func (r *SalesRepo) SaleByID(ctx context.Context, saleID uint) (*domain.Sale, error) {
	var sale domain.Sale

	row := r.db.QueryRowContext(ctx, "SELECT * FROM get_sale_by_id($1);", saleID)

	err := row.Scan(&sale.ID, &sale.GoodID, &sale.GoodName, &sale.GoodCount, &sale.CreateDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get sale by id: %w", err)
	}

	return &sale, nil
}

func (r *SalesRepo) DeleteSale(ctx context.Context, saleID uint) error {
	_, err := r.db.ExecContext(ctx, "CALL delete_sale($1)", saleID)
	if err != nil {
		return fmt.Errorf("failed to delete sale: %w", err)
	}

	return nil
}
