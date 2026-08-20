-- Full Data

SELECT * 
FROM SQL_Project..CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 3 , 4

SELECT *
FROM SQL_Project..CovidVaccinations
ORDER BY 3 , 4

-- Data Used in this Project

SELECT 
	location ,
	date ,
	total_cases ,
	new_cases ,
	total_deaths ,
	population
FROM SQL_Project..CovidDeaths
ORDER BY 1 , 2

-- Total Cases vs Total Deaths (In India)

SELECT 
	location ,
	date ,
	total_cases ,
	total_deaths ,
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM SQL_Project..CovidDeaths
WHERE location = 'India'
ORDER BY 1 , 2

-- Total Cases vs Population (In India)

SELECT 
	location ,
	date ,
	population ,
	total_cases ,
	(total_cases/population)*100 AS InfectionRate
FROM SQL_Project..CovidDeaths
WHERE location = 'India' AND continent IS NOT NULL
ORDER BY 1 , 2

-- Countries with highest infection rate compared to population

SELECT 
	location ,
	population ,
	MAX(total_cases) AS HighestInfectionCount ,
	MAX((total_cases/population)*100) AS HighestInfectionRate
FROM SQL_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location , population
ORDER BY HighestInfectionRate DESC

-- Countries with highest death count per population

SELECT 
	location ,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM SQL_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continents with highest death count per population

SELECT 
	continent ,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM SQL_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers(By Date)

SELECT 
	date,
	SUM(new_cases) AS TotalCases,
	SUM(CAST(new_deaths AS int)) AS TotalDeaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM SQL_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations

SELECT 
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingPeopleVaccinated
FROM SQL_Project..CovidDeaths dea
JOIN SQL_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to show Percentage Population that has recieved Covid Vaccine

WITH PvsV (continent , location ,date ,population ,new_vaccinations ,RollingPeopleVaccinated ) 
AS (
SELECT 
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingPeopleVaccinated
FROM SQL_Project..CovidDeaths dea
JOIN SQL_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
) 
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PvsV

-- Using TEMP TABLE to show Percentage Population that has recieved Covid Vaccine

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingPeopleVaccinated
FROM SQL_Project..CovidDeaths dea
JOIN SQL_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date

SELECT *,(RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
From #PercentPopulationVaccinated
ORDER BY 2,3

-- Creating View for future references
DROP VIEW PPV
GO

CREATE VIEW
PPV AS
SELECT 
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingPeopleVaccinated
FROM SQL_Project..CovidDeaths dea
JOIN SQL_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO 

SELECT *
FROM PPV

-- ICU/Hospitalization burden

SELECT 
	location,
	SUM(CAST(icu_patients AS int)) AS ICUPatients,
    SUM(CAST(hosp_patients AS int)) AS HospPatients
FROM SQL_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY ICUPatients DESC , HospPatients DESC

-- Percentage of people fully vaccinated

SELECT 
	dea.location,
	dea.date,
	dea.population,
    vac.people_fully_vaccinated,
    (people_fully_vaccinated/population)*100 AS PercentageFullyVaccinated
FROM SQL_Project..CovidDeaths dea
JOIN SQL_Project..CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

-- Ranking/Continent of Total Deaths

SELECT 
	continent,
	location,
	TotalDeathCount,
    RANK() OVER (PARTITION BY continent ORDER BY TotalDeathCount DESC) AS RankInContinent
FROM (
    SELECT
		continent,
		location,
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount
    FROM SQL_Project..CovidDeaths
    WHERE continent IS NOT NULL
    GROUP BY continent, location
) t

-- Labeling countries as Early or Late vaccine adopters

SELECT 
	location ,
	MIN(date) AS FirstVaccinationDate ,
	CASE 
		WHEN MIN(date) <= '2021-01-31' THEN 'Early Adopter'
		ELSE 'Late Adopter'
	END AS AdoptionSpeed
FROM SQL_Project..CovidVaccinations
WHERE continent IS NOT NULL AND new_vaccinations IS NOT NULL
GROUP BY location
ORDER BY FirstVaccinationDate