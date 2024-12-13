package http

import (
	"bytes"
	"os"

	"github.com/SebastiaanKlippert/go-wkhtmltopdf"
	"github.com/labstack/echo/v4"
)

func (s *Server) getPDF(ctx echo.Context) error {
	pdf, err := wkhtmltopdf.NewPDFGenerator()
	if err != nil {
		return err
	}

	pages := make(map[string]any, 4)

	bestGoods, err := s.goodUC.BestPerformingGoods(ctx.Request().Context())
	if err != nil {
		return err
	}
	pages["best-goods.html"] = bestGoods
	allGoods, err := s.goodUC.AllGoods(ctx.Request().Context())
	if err != nil {
		return err
	}
	pages["goods.html"] = allGoods
	allSales, err := s.salesUC.AllSales(ctx.Request().Context())
	if err != nil {
		return err
	}
	pages["sales.html"] = allSales
	allUsers, err := s.userUC.AllUsers(ctx.Request().Context())
	if err != nil {
		return err
	}
	pages["users.html"] = allUsers

	for page, data := range pages {
		buff := bytes.NewBuffer(nil)
		err := s.r.Render(buff, page, data, ctx)
		if err != nil {
			return err
		}
		pdf.AddPage(wkhtmltopdf.NewPageReader(buff))
	}
	err = pdf.CreateContext(ctx.Request().Context())
	if err != nil {
		return err
	}

	file, err := os.CreateTemp("", "****.pdf")
	if err != nil {
		return err
	}
	defer file.Close()
	err = ctx.File(file.Name())
	if err != nil {
		return err
	}

	return ctx.Attachment(file.Name(), "doc.pdf")
}
