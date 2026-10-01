/*

Queries used for Tableau

*/



-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From SQL_Project..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 

-- We take these out as they are not inCluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From SQL_Project..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From SQL_Project..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From SQL_Project..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc


-- 5.


Select dea.location, dea.population,
       MAX(cast(vac.people_vaccinated as bigint)) as PeopleVaccinated,
       MAX(cast(vac.people_fully_vaccinated as bigint)) as PeopleFullyVaccinated,
       MAX(cast(vac.people_vaccinated as bigint)) * 1.0 / dea.population * 100 as PercentVaccinated,
       MAX(cast(vac.people_fully_vaccinated as bigint)) * 1.0 / dea.population * 100 as PercentFullyVaccinated
From SQL_Project..CovidDeaths dea
Join SQL_Project..CovidVaccinations vac
  On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null
Group by dea.location, dea.population
order by PercentFullyVaccinated desc


-- 6.


Select dea.continent, dea.location,
       DATEFROMPARTS(YEAR(dea.date), MONTH(dea.date), 1) as MonthStart,
       SUM(cast(dea.new_deaths as int)) as MonthlyDeaths,
       SUM(dea.new_cases) as MonthlyCases,
       MAX(vac.people_fully_vaccinated) as FullyVaccinated
From SQL_Project..CovidDeaths dea
Join SQL_Project..CovidVaccinations vac
  On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null
Group by dea.continent, dea.location, DATEFROMPARTS(YEAR(dea.date), MONTH(dea.date), 1)
order by dea.location, MonthStart


-- 7.


Select dea.location,
       dea.population,
       MAX(dea.total_cases_per_million) as CasesPerMillion,
       MAX(dea.total_deaths_per_million) as DeathsPerMillion,
       MAX(vac.people_fully_vaccinated_per_hundred) as FullyVaccinatedPer100,
       MAX(cast(vac.people_fully_vaccinated as bigint))/dea.population*100 as PercentFullyVaccinated
From SQL_Project..CovidDeaths dea
Join SQL_Project..CovidVaccinations vac
  On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null
Group by dea.location, dea.population
order by DeathsPerMillion desc


-- 8.


Select dea.location, dea.population,
       MAX(vac.median_age) as MedianAge,
       MAX(vac.aged_65_older) as Aged65Plus,
       MAX(vac.gdp_per_capita) as GDPperCapita,
       MAX(vac.life_expectancy) as LifeExpectancy,
       MAX(cast(dea.total_deaths as int)) as TotalDeaths,
       MAX(cast(dea.total_deaths as int))/dea.population*1000000 as DeathsPerMillion
From SQL_Project..CovidDeaths dea
Join SQL_Project..CovidVaccinations vac
  On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null
Group by dea.location, dea.population
Having MAX(vac.median_age) is not null
order by DeathsPerMillion desc


--