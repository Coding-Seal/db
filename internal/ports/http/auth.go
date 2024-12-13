package http

import (
	"net/http"
	"time"

	"github.com/Coding-Seal/db-curs/internal/domain"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

var jwtSecret = []byte("your_secret_key")

func (s *Server) handleLogin(ctx echo.Context) error {
	login := ctx.FormValue("username")
	pswd := ctx.FormValue("password")

	user, err := s.userUC.UserByLogin(ctx.Request().Context(), login)
	if err != nil {
		s.e.Logger.Debug(err)

		return ctx.Redirect(http.StatusSeeOther, "")
	}

	err = bcrypt.CompareHashAndPassword(user.PassHash, []byte(pswd))
	if err != nil {
		s.e.Logger.Debug(err)

		return ctx.Redirect(http.StatusSeeOther, "")
	}

	token := userToJWT(user)

	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		s.e.Logger.Error(err)

		return echo.ErrInternalServerError.SetInternal(err)
	}

	ctx.SetCookie(getCookie(tokenString))

	return ctx.Redirect(http.StatusSeeOther, "/home")
}

type claims struct {
	UserID   uint        `json:"userId"`
	UserRole domain.Role `json:"userRole"`
	jwt.RegisteredClaims
}

func userToJWT(user *domain.User) *jwt.Token {
	claims := &claims{
		UserID:   user.ID,
		UserRole: user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
		},
	}

	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
}

func getCookie(token string) *http.Cookie {
	return &http.Cookie{
		Name:     "auth_token",
		Value:    token,
		Expires:  time.Now().Add(time.Hour),
		Secure:   true,
		HttpOnly: true,
	}
}
