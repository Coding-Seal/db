package http

import (
	"fmt"
	"os"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/signintech/gopdf"
)

func str(a any) string {
	return fmt.Sprintf("%v", a)
}

func (s *Server) getPDF(ctx echo.Context) error {
	bestGoods, err := s.goodUC.BestPerformingGoods(ctx.Request().Context())
	if err != nil {
		return err
	}

	allGoods, err := s.goodUC.AllGoods(ctx.Request().Context())
	if err != nil {
		return err
	}

	allSales, err := s.salesUC.AllSales(ctx.Request().Context())
	if err != nil {
		return err
	}

	allUsers, err := s.userUC.AllUsers(ctx.Request().Context())
	if err != nil {
		return err
	}

	pdf := gopdf.GoPdf{}
	pdf.Start(gopdf.Config{PageSize: *gopdf.PageSizeA4})

	err = pdf.AddTTFFont("roboto", "Roboto.ttf")
	if err != nil {
		return err
	}

	pdf.SetFont("roboto", "", 14)

	pdf.AddPage()

	// Set font (you may need to download a TTF font file)
	// Title
	pdf.Cell(nil, "User Report")

	// Users Section
	pdf.Br(20)
	pdf.Cell(nil, "All Users:")
	pdf.Br(10)

	tableStartY := 100.0
	// Set the left margin for the table
	marginLeft := 10.0

	table := pdf.NewTableLayout(marginLeft, tableStartY, 25, len(allUsers))
	table.AddColumn("ID", 50, "right")
	table.AddColumn("Login", 100, "right")
	table.AddColumn("Role", 100, "right")
	for _, user := range allUsers {
		table.AddRow([]string{str(user.ID), user.Login, str(user.Role)})
	}
	err = table.DrawTable()
	if err != nil {
		return err
	}

	pdf.AddPage()
	// Best Goods Section
	pdf.Br(20)
	pdf.Cell(nil, "Best Performing Goods:")
	pdf.Br(10)

	table = pdf.NewTableLayout(marginLeft, tableStartY, 25, len(bestGoods))

	table.AddColumn("ID", 50, "right")
	table.AddColumn("Name", 100, "right")
	table.AddColumn("Demand", 100, "right")
	for _, good := range bestGoods {
		table.AddRow([]string{str(good.ID), good.Name, str(good.Demand)})
	}
	err = table.DrawTable()
	if err != nil {
		return err
	}
	pdf.AddPage()

	// All Goods Section
	pdf.Br(20)
	pdf.Cell(nil, "All Goods:")
	pdf.Br(10)

	table = pdf.NewTableLayout(marginLeft, tableStartY, 25, len(allGoods))

	table.AddColumn("ID", 50, "right")
	table.AddColumn("Name", 100, "right")
	table.AddColumn("Priority", 100, "right")
	table.AddColumn("AmountWH1", 100, "right")
	table.AddColumn("AmountWH2", 100, "right")
	for _, good := range allGoods {
		table.AddRow([]string{str(good.ID), good.Name, str(good.Priority), str(good.AmountWh1), str(good.AmountWh2)})
	}
	err = table.DrawTable()
	if err != nil {
		return err
	}

	pdf.AddPage()
	// All Sales Section
	pdf.Br(20)
	pdf.Cell(nil, "All Sales:")
	pdf.Br(10)
	table = pdf.NewTableLayout(marginLeft, tableStartY, 25, len(allSales))
	table.AddColumn("ID", 50, "right")
	table.AddColumn("Good ID", 100, "right")
	table.AddColumn("Good Name", 100, "right")
	table.AddColumn("Quantity Sold", 100, "right")
	table.AddColumn("CreateDate", 200, "right")

	for _, sale := range allSales {
		table.AddRow([]string{str(sale.ID), str(sale.GoodID), str(sale.GoodName), str(sale.GoodCount), sale.CreateDate.Format(time.DateOnly)})
		pdf.Br(5)
	}
	err = table.DrawTable()
	if err != nil {
		return err
	}
	// Save the PDF to a file
	file, err := os.CreateTemp("", "****.pdf")
	if err != nil {
		return err
	}

	defer file.Close()

	err = pdf.WritePdf(file.Name())
	if err != nil {
		return err
	}

	return ctx.Attachment(file.Name(), "report.pdf")
}

func (s *Server) getTXT(ctx echo.Context) error {
	bestGoods, err := s.goodUC.BestPerformingGoods(ctx.Request().Context())
	if err != nil {
		return err
	}

	allGoods, err := s.goodUC.AllGoods(ctx.Request().Context())
	if err != nil {
		return err
	}

	allSales, err := s.salesUC.AllSales(ctx.Request().Context())
	if err != nil {
		return err
	}

	allUsers, err := s.userUC.AllUsers(ctx.Request().Context())
	if err != nil {
		return err
	}

	file, err := os.CreateTemp("", "****.txt")
	if err != nil {
		return err
	}

	defer file.Close()

	_, err = fmt.Fprintln(file, "USERS:")
	if err != nil {
		return err
	}

	for _, user := range allUsers {
		_, err := fmt.Fprintf(file, "ID: %d, Name: %s, Role: %s\n", user.ID, user.Login, user.Role)
		if err != nil {
			return err
		}
	}
	_, err = fmt.Fprintln(file, "")
	if err != nil {
		return err
	}

	_, err = fmt.Fprintln(file, "TOP_GOODS:")
	if err != nil {
		return err
	}
	for _, good := range bestGoods {
		_, err := fmt.Fprintf(file, "ID: %d, Name: %s, Demand: %d\n", good.ID, good.Name, good.Demand)
		if err != nil {
			return err
		}
	}
	_, err = fmt.Fprintln(file, "")
	if err != nil {
		return err
	}

	_, err = fmt.Fprintln(file, "GOODS:")
	if err != nil {
		return err
	}
	for _, good := range allGoods {
		_, err := fmt.Fprintf(file, "ID: %d, Name: %s, Priority: %f, AmountWh1: %d, AmountWh1: %d\n",
			good.ID, good.Name, good.Priority, good.AmountWh1, good.AmountWh2)
		if err != nil {
			return err
		}
	}
	_, err = fmt.Fprintln(file, "")
	if err != nil {
		return err
	}
	_, err = fmt.Fprintln(file, "SALES:")
	if err != nil {
		return err
	}
	for _, sale := range allSales {
		_, err := fmt.Fprintf(file, "ID: %d, Good ID: %d, Good Name: %s, Quantity Sold: %d, Create Date: %s\n",
			sale.ID, sale.GoodID, sale.GoodName, sale.GoodCount, sale.CreateDate.Format(time.DateOnly))
		if err != nil {
			return err
		}
	}
	_, err = fmt.Fprintln(file, "")
	if err != nil {
		return err
	}

	return ctx.Attachment(file.Name(), "report.txt")
}
