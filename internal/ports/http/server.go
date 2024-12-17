package http

import (
	"context"
	"encoding/json"
	"text/template"

	"github.com/Coding-Seal/db-curs/internal/usecase"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"
)

type Server struct {
	e *echo.Echo
	r echo.Renderer

	userUC  *usecase.User
	goodUC  *usecase.Good
	salesUC *usecase.Sale
}

func NewServer(userUC *usecase.User, goodUC *usecase.Good, salesUC *usecase.Sale) *Server {
	e := echo.New()

	s := &Server{
		e:       e,
		userUC:  userUC,
		goodUC:  goodUC,
		salesUC: salesUC,
	}

	e.Logger.SetLevel(log.DEBUG)
	s.prepareTemplates()
	s.applyRootMiddleware()
	s.registerHandlers()

	return s
}

func (s *Server) Start() error {
	return s.e.Start("localhost:8080")
}

func (s *Server) Stop(ctx context.Context) error {
	return s.e.Shutdown(ctx)
}

func (s *Server) applyRootMiddleware() {
	s.e.Use(middleware.Logger())
	s.e.Use(middleware.Recover())
}

func (s *Server) registerHandlers() {
	anyone := s.e.Group("")
	anyone.GET("/home", s.homePage)
	anyone.GET("/login", s.loginPage)
	anyone.POST("/login", s.handleLogin)

	requireAuth := s.e.Group("")
	// requireAuth.Use(echojwt.WithConfig(echojwt.Config{}))

	adminOnly := requireAuth.Group("", s.restrictAdmin)
	adminOnly.GET("/create-user", s.createUserPage)
	adminOnly.POST("/create-user", s.createUserHandler)
	adminOnly.POST("/delete-user", s.deleteUserHandler)
	adminOnly.GET("/update-user", s.updateUsersPage)
	adminOnly.POST("/update-user", s.updateUserHandler)
	adminOnly.GET("/create-good", s.createGoodPage)
	adminOnly.POST("/create-good", s.createGoodHandler)
	adminOnly.POST("/delete-good", s.deleteGoodHandler)
	adminOnly.GET("/update-good", s.updateGoodPage)
	adminOnly.POST("/update-good", s.updateGoodHandler)
	adminOnly.GET("/create-sale", s.createSalePage)
	adminOnly.POST("/create-sale", s.createSaleHandler)
	adminOnly.POST("/delete-sale", s.deleteSaleHandler)

	anyUser := requireAuth.Group("", s.restrictUser)
	anyUser.GET("/users", s.usersPage)
	anyUser.GET("/goods", s.goodsPage)
	anyUser.GET("/get-demand", s.getDemandPage)
	anyUser.GET("/sales", s.salesPage)
	anyUser.GET("/demand", s.demandPage)
	anyUser.GET("/best-goods", s.bestGoodsPage)
	anyUser.GET("/download/pdf", s.getPDF)
	anyUser.GET("/download/txt", s.getTXT)
}

func (s *Server) prepareTemplates() {
	t := template.Must(template.New("").Funcs(template.FuncMap{"toJson": toJson}).ParseFS(html, "html/*.html"))
	s.r = &echo.TemplateRenderer{Template: t}
}

func toJson(data interface{}) string {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return "{}" // Return empty JSON on error
	}

	return string(jsonData)
}
