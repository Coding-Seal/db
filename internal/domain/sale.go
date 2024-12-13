package domain

import "time"

type Sale struct {
	ID         uint
	GoodID     uint
	GoodName   string
	GoodCount  uint
	CreateDate time.Time
}
