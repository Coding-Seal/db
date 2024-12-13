package domain

import "time"

type Good struct {
	ID        uint
	Name      string
	Priority  float64
	AmountWh1 uint
	AmountWh2 uint
}

type DemandPoint struct {
	Time   time.Time
	Demand uint
}

type PerformingGood struct {
	ID     uint
	Name   string
	Demand uint
}
