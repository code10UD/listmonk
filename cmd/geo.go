package main

import (
	"net/http"
	"strings"

	"github.com/knadh/listmonk/models"
	"github.com/labstack/echo/v4"
)

// handleGetRegions retourne la liste des régions françaises
func (app *App) handleGetRegions(c echo.Context) error {
	var regions []models.DepartementRegion

	if err := app.queries.GetGeoRegions.Select(&regions); err != nil {
		app.log.Printf("error fetching regions: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	return c.JSON(http.StatusOK, okResp{Data: regions})
}

// handleGetDepartements retourne la liste des départements avec leurs régions
func (app *App) handleGetDepartements(c echo.Context) error {
	var departements []models.DepartementRegion

	if err := app.queries.GetGeoDepartements.Select(&departements); err != nil {
		app.log.Printf("error fetching departements: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	return c.JSON(http.StatusOK, okResp{Data: departements})
}

// handleGetCommunes recherche les communes par nom et/ou département
func (app *App) handleGetCommunes(c echo.Context) error {
	var (
		communes []models.CommuneInfo
		search   = strings.TrimSpace(c.QueryParam("search"))
		dept     = strings.TrimSpace(c.QueryParam("departement"))
	)

	// Validation des paramètres
	if search != "" && len(search) < 2 {
		return echo.NewHTTPError(http.StatusBadRequest, "Search term must be at least 2 characters")
	}

	if err := app.queries.GetGeoCommunes.Select(&communes, search, dept); err != nil {
		app.log.Printf("error fetching communes: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	return c.JSON(http.StatusOK, okResp{Data: communes})
}

// handleGetCSPs retourne les CSP disponibles avec leur nombre d'abonnés
func (app *App) handleGetCSPs(c echo.Context) error {
	var csps []models.CSPInfo

	if err := app.queries.GetGeoCSPs.Select(&csps); err != nil {
		app.log.Printf("error fetching CSPs: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	return c.JSON(http.StatusOK, okResp{Data: csps})
}

// handleGeoQuery traite les requêtes géographiques complexes pour compter les abonnés
func (app *App) handleGeoQuery(c echo.Context) error {
	var (
		req models.GeoQueryParams
		out struct {
			Count int `json:"count"`
		}
	)

	// Bind et validation des paramètres
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, app.i18n.T("globals.messages.invalidData"))
	}

	// Préparation des paramètres pour la requête SQL
	var (
		regions     = req.Regions
		departements = req.Departements
		codesINSEE  = req.CodesINSEE
		csps        = req.CSPs
		popMin      = 0
		popMax      = 0
	)

	// Gestion des filtres de population
	if req.UsePopulation {
		if req.PopulationMin != nil {
			popMin = *req.PopulationMin
		}
		if req.PopulationMax != nil {
			popMax = *req.PopulationMax
		}
	}

	// Conversion des slices en format PostgreSQL array
	regionsArray := "{}"
	if len(regions) > 0 {
		regionsArray = "{" + strings.Join(regions, ",") + "}"
	}

	departementsArray := "{}"
	if len(departements) > 0 {
		departementsArray = "{" + strings.Join(departements, ",") + "}"
	}

	codesINSEEArray := "{}"
	if len(codesINSEE) > 0 {
		codesINSEEArray = "{" + strings.Join(codesINSEE, ",") + "}"
	}

	cspsArray := "{}"
	if len(csps) > 0 {
		cspsArray = "{" + strings.Join(csps, ",") + "}"
	}

	// Exécution de la requête de comptage
	if err := app.queries.QuerySubscribersGeo.Get(&out.Count, 
		regionsArray, departementsArray, codesINSEEArray, cspsArray, popMin, popMax); err != nil {
		app.log.Printf("error executing geo query: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	return c.JSON(http.StatusOK, okResp{Data: out})
}

// handleGetGeoStats retourne les statistiques géographiques des abonnés
func (app *App) handleGetGeoStats(c echo.Context) error {
	var stats models.GeoStats

	// Récupération des statistiques par région
	var regionStats []struct {
		RegionNom string `db:"region_nom"`
		Count     int    `db:"count"`
	}

	if err := app.queries.GetGeoStatsByRegion.Select(&regionStats); err != nil {
		app.log.Printf("error fetching region stats: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	// Récupération des statistiques par département
	var deptStats []struct {
		DepartementNumero string `db:"departement_numero"`
		Count             int    `db:"count"`
	}

	if err := app.queries.GetGeoStatsByDepartement.Select(&deptStats); err != nil {
		app.log.Printf("error fetching departement stats: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	// Récupération des statistiques par CSP
	var cspStats []struct {
		CSP   string `db:"csp"`
		Count int    `db:"count"`
	}

	if err := app.queries.GetGeoStatsByCSP.Select(&cspStats); err != nil {
		app.log.Printf("error fetching CSP stats: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, app.i18n.T("globals.messages.errorFetching"))
	}

	// Construction de la réponse
	stats.ByRegion = make(map[string]int)
	for _, r := range regionStats {
		stats.ByRegion[r.RegionNom] = r.Count
		stats.TotalSubscribers += r.Count
	}

	stats.ByDepartement = make(map[string]int)
	for _, d := range deptStats {
		stats.ByDepartement[d.DepartementNumero] = d.Count
	}

	stats.ByCSP = make(map[string]int)
	for _, c := range cspStats {
		stats.ByCSP[c.CSP] = c.Count
	}

	// Récupération des statistiques de population
	var popStats models.PopulationStats
	if err := app.queries.GetGeoPopulationStats.Get(&popStats); err != nil {
		app.log.Printf("error fetching population stats: %v", err)
		// Ne pas faire échouer la requête pour les stats de population
		popStats = models.PopulationStats{}
	}
	stats.PopulationStats = popStats

	return c.JSON(http.StatusOK, okResp{Data: stats})
}