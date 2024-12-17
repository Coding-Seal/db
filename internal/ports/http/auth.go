package http

import (
	"fmt"
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

		return ctx.Redirect(http.StatusSeeOther, "/login")
	}

	err = bcrypt.CompareHashAndPassword(user.PassHash, []byte(pswd))
	if err != nil {
		s.e.Logger.Debug(err)

		return ctx.Redirect(http.StatusSeeOther, "/login")
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

func (s *Server) restrictAdmin(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		cookie, err := c.Cookie("auth_token")
		if err != nil {
			return c.Redirect(http.StatusSeeOther, "/login")
		}
		tokenStr := cookie.Value

		claims := &claims{}
		_, err = jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			// Return the secret key for validation (replace with your actual secret)
			return jwtSecret, nil
		})
		if err != nil {
			return c.Redirect(http.StatusSeeOther, "/login")
		}
		if claims.UserRole == domain.ADMIN {
			return next(c)
		}
		return c.Redirect(http.StatusSeeOther, "/login")
	}
}
func (s *Server) restrictUser(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		cookie, err := c.Cookie("auth_token")
		if err != nil {
			return c.Redirect(http.StatusSeeOther, "/login")
		}
		tokenStr := cookie.Value

		claims := &claims{}
		_, err = jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			// Return the secret key for validation (replace with your actual secret)
			return jwtSecret, nil
		})
		if err != nil {
			return c.Redirect(http.StatusSeeOther, "/login")
		}
		if claims.UserRole == domain.ADMIN || claims.UserRole == domain.USER {
			return next(c)
		}
		return c.Redirect(http.StatusSeeOther, "/login")
	}
}
