package http

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/Coding-Seal/db-curs/internal/domain"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

type userDTO struct {
	Login    string `form:"login"`
	Password string `form:"password"`
	Role     string `form:"role"`
}

func (s *Server) createUserHandler(ctx echo.Context) error {
	var dto userDTO
	if err := ctx.Bind(&dto); err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	hashPass, err := bcrypt.GenerateFromPassword([]byte(dto.Password), bcrypt.DefaultCost)
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	user := &domain.User{Login: dto.Login, PassHash: hashPass, Role: domain.Role(dto.Role)}

	err = s.userUC.CreateUser(ctx.Request().Context(), user)
	if err != nil {
		s.e.Logger.Debugf("failed create user: %v", err)

		return ctx.Redirect(http.StatusSeeOther, "/create-user")
	}

	return ctx.Redirect(http.StatusSeeOther, "/users")
}

func (s *Server) deleteUserHandler(ctx echo.Context) error {
	userID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	err = s.userUC.DeleteUser(ctx.Request().Context(), uint(userID))
	if err != nil {
		s.e.Logger.Debugf("failed delete user: %v", err)
	}

	return ctx.Redirect(http.StatusSeeOther, "/users")
}

func (s *Server) updateUserHandler(ctx echo.Context) error {
	var dto userDTO
	if err := ctx.Bind(&dto); err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	userID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	hashPass, err := bcrypt.GenerateFromPassword([]byte(dto.Password), bcrypt.DefaultCost)
	if err != nil {
		return echo.ErrInternalServerError.SetInternal(err)
	}

	user := &domain.User{ID: uint(userID), Login: dto.Login, PassHash: hashPass, Role: domain.Role(dto.Role)}

	shouldUpdatePassword := len(dto.Password) != 0

	err = s.userUC.UpdateUser(ctx.Request().Context(), user, shouldUpdatePassword)
	if err != nil {
		s.e.Logger.Debugf("failed update user: %v", err)

		return ctx.Redirect(http.StatusSeeOther, fmt.Sprintf("/update-user?id=%d", userID))
	}

	return ctx.Redirect(http.StatusSeeOther, "/users")
}

type goodDTO struct {
	Name      string  `form:"name"`
	Priority  float64 `form:"priority"`
	AmountWh1 uint    `form:"amountWh1"`
	AmountWh2 uint    `form:"amountWh2"`
}

func (s *Server) createGoodHandler(ctx echo.Context) error {
	var dto goodDTO
	if err := ctx.Bind(&dto); err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	good := &domain.Good{
		Name:      dto.Name,
		Priority:  dto.Priority,
		AmountWh1: dto.AmountWh1,
		AmountWh2: dto.AmountWh2,
	}

	err := s.goodUC.CreateGood(ctx.Request().Context(), good)
	if err != nil {
		s.e.Logger.Debugf("failed create good: %v", err)

		return ctx.Redirect(http.StatusSeeOther, "/create-good")
	}

	return ctx.Redirect(http.StatusSeeOther, "/goods")
}

func (s *Server) deleteGoodHandler(ctx echo.Context) error {
	goodID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	err = s.goodUC.DeleteGood(ctx.Request().Context(), uint(goodID))
	if err != nil {
		s.e.Logger.Debugf("failed delete good: %v", err)
	}

	return ctx.Redirect(http.StatusSeeOther, "/goods")
}

func (s *Server) updateGoodHandler(ctx echo.Context) error {
	var dto goodDTO
	if err := ctx.Bind(&dto); err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	goodID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	good := &domain.Good{
		ID:        uint(goodID),
		Name:      dto.Name,
		Priority:  dto.Priority,
		AmountWh1: dto.AmountWh1,
		AmountWh2: dto.AmountWh2,
	}

	err = s.goodUC.UpdateGood(ctx.Request().Context(), good)
	if err != nil {
		s.e.Logger.Debugf("failed update good: %v", err)
		ctx.Redirect(http.StatusSeeOther, fmt.Sprintf("/update-good?id=%d", goodID))
	}

	return ctx.Redirect(http.StatusSeeOther, "/goods")
}

type saleDTO struct {
	GoodID    uint `form:"good_id"`
	GoodCount uint `form:"good_count"`
}

func (s *Server) createSaleHandler(ctx echo.Context) error {
	var dto saleDTO
	if err := ctx.Bind(&dto); err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	sale := &domain.Sale{GoodID: dto.GoodID, GoodCount: dto.GoodCount}

	err := s.salesUC.CreateSale(ctx.Request().Context(), sale)
	if err != nil {
		s.e.Logger.Debugf("failed update good: %v", err)
		ctx.Redirect(http.StatusSeeOther, "/create-sale")
	}

	return ctx.Redirect(http.StatusSeeOther, "/sales")
}

func (s *Server) deleteSaleHandler(ctx echo.Context) error {
	saleID, err := strconv.ParseUint(ctx.FormValue("id"), 10, 32)
	if err != nil {
		return echo.ErrBadRequest.SetInternal(err)
	}

	err = s.salesUC.DeleteSale(ctx.Request().Context(), uint(saleID))
	if err != nil {
		s.e.Logger.Debugf("failed delete sale: %v", err)
	}

	return ctx.Redirect(http.StatusSeeOther, "/sales")
}
