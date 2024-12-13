package http

import (
	"embed"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
)

//go:embed html
var html embed.FS

func (s *Server) loginPage(ctx echo.Context) error {
	return s.r.Render(ctx.Response(), "login.html", nil, ctx)
}

func (s *Server) homePage(ctx echo.Context) error {
	return s.r.Render(ctx.Response(), "home.html", nil, ctx)
}

func (s *Server) createUserPage(ctx echo.Context) error {
	return s.r.Render(ctx.Response(), "create-user.html", nil, ctx)
}

func (s *Server) usersPage(ctx echo.Context) error {
	users, err := s.userUC.AllUsers(ctx.Request().Context())
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "users.html", users, ctx)
}

func (s *Server) updateUsersPage(ctx echo.Context) error {
	userID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	user, err := s.userUC.UserByID(ctx.Request().Context(), uint(userID))
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "update-user.html", user, ctx)
}

func (s *Server) goodsPage(ctx echo.Context) error {
	goods, err := s.goodUC.AllGoods(ctx.Request().Context())
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "goods.html", goods, ctx)
}

func (s *Server) createGoodPage(ctx echo.Context) error {
	return s.r.Render(ctx.Response(), "create-good.html", nil, ctx)
}

func (s *Server) updateGoodPage(ctx echo.Context) error {
	goodID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	user, err := s.goodUC.GoodByID(ctx.Request().Context(), uint(goodID))
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "update-good.html", user, ctx)
}

func (s *Server) getDemandPage(ctx echo.Context) error {
	goodID, err := strconv.ParseUint(ctx.QueryParam("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "get-demand.html", goodID, ctx)
}

func (s *Server) salesPage(ctx echo.Context) error {
	sales, err := s.salesUC.AllSales(ctx.Request().Context())
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "sales.html", sales, ctx)
}

func (s *Server) createSalePage(ctx echo.Context) error {
	goods, err := s.goodUC.AllGoods(ctx.Request().Context())
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	return s.r.Render(ctx.Response(), "create-sale.html", goods, ctx)
}

type demandRequest struct {
	GoodID uint   `query:"id"`
	Start  string `query:"start_date"`
	End    string `query:"end_date"`
}

func (s *Server) demandPage(ctx echo.Context) error {
	dto := demandRequest{}
	if err := ctx.Bind(&dto); err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}
	start, err := time.Parse(time.DateOnly, dto.Start)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}
	end, err := time.Parse(time.DateOnly, dto.End)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	demandPoints, err := s.goodUC.GoodDemand(ctx.Request().Context(), dto.GoodID, start, end)
	if err != nil {
		s.e.Logger.Debugf("failed to get demand: %v", err)
		return ctx.Redirect(http.StatusSeeOther, fmt.Sprintf("/get-demand?id=%d", dto.GoodID))
	}

	demandValues := make([]uint, 0, len(demandPoints))
	demandTime := make([]time.Time, 0, len(demandPoints))

	for _, point := range demandPoints {
		demandValues = append(demandValues, point.Demand)
		demandTime = append(demandTime, point.Time)
	}

	return s.r.Render(ctx.Response(), "demand.html", map[string]interface{}{
		"Labels":       demandTime,
		"DataPoints":   demandValues,
		"DemandPoints": demandPoints,
	}, ctx)
}

func (s *Server) bestGoodsPage(ctx echo.Context) error {
	goods, err := s.goodUC.BestPerformingGoods(ctx.Request().Context())
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}
	return s.r.Render(ctx.Response(), "best-goods.html", goods, ctx)
}
