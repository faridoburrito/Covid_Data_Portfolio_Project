SELECT *
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
ORDER BY 3,4
----------------------------------------------------------------------------------------------------------------

--Select data that we are going to be using
SELECT location, date, total_deaths, population
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
ORDER BY 1,2
----------------------------------------------------------------------------------------------------------------

--Looking at total cases vs total deaths
--Shows likelihood of dying if you contract covid in any country
--Used NULLIF function to avoid "Arithmetic overflow error" since there is some total_cases that equal to 0 and we can't divide by 0
SELECT [location], [date], total_cases, total_deaths, (total_deaths/NULLIF(total_cases,0))*100 AS DeathPercentage
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
ORDER BY 1,2
----------------------------------------------------------------------------------------------------------------


-- #1 for Tableau
--Showing global numbers for new cases, new deaths
SELECT  SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, CAST(SUM(new_deaths)AS float)/NULLIF(CAST(SUM(new_cases)AS float),0)*100 AS DeathPercentage
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
--GROUP BY date
ORDER BY 1,2
----------------------------------------------------------------------------------------------------------------

--#2 for Tableau
--Showing continents with the highest death count per population
SELECT [continent], MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
GROUP BY [continent]
ORDER BY TotalDeathCount DESC
----------------------------------------------------------------------------------------------------------------

-- #3 for Tableau
--Looking at total cases vs population
--Shows what percentage of each country got Covid
SELECT [location], population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX(total_cases/NULLIF(population,0))*100,4) AS PercentPopulationInfected
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
GROUP BY [location], population
ORDER BY PercentPopulationInfected DESC 
----------------------------------------------------------------------------------------------------------------

-- #4 for Tableau
--Looking at total cases vs population vs date
--Shows what percentage of each country got Covid and in which date
SELECT [location], population, date, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX(total_cases/NULLIF(population,0))*100,4) AS PercentPopulationInfected
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
GROUP BY [location], population,[date]
ORDER BY PercentPopulationInfected DESC 
----------------------------------------------------------------------------------------------------------------

--Showing countries with the highest death count per population
SELECT [location], MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM Covid_Project_Database..CovidDeaths2
WHERE continent <> 'NULL'
GROUP BY [location]
ORDER BY TotalDeathCount DESC
----------------------------------------------------------------------------------------------------------------

--Looking at  Population vs Max Total Vaccinations for each country
--Use CTE (Common Table Expression)
WITH PopvsVac (continent, location, date, population, new_vaccinations, Total_New_Vaccinations)
AS
(
SELECT death.continent, death.[location], death.[date], death.population, vaccination.new_vaccinations
, SUM(vaccination.new_vaccinations) OVER (Partition by death.location Order by death.location, death.date) AS Total_New_Vaccinations 
FROM Covid_Project_Database..CovidDeaths2 death
JOIN Covid_Project_Database..CovidVaccinations2 vaccination
    ON death.[location] = vaccination.[location]
    AND death.[date] = vaccination.[date]
WHERE death.continent <> 'NULL'
)
SELECT [location], population, MAX(Total_New_Vaccinations/Population* 100) AS Vac_Percentage
FROM PopvsVac
GROUP BY [location], population
Order by 1,2
----------------------------------------------------------------------------------------------------------------
--Temporary table to calculate the total of new vaccinations for each country by using Partition By function and ordering them by their location and date
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
   Continent NVARCHAR(255),
   Location NVARCHAR(255),
   Date DATETIME,
   Population NUMERIC,
   New_Vaccinations NUMERIC,
   Total_New_Vaccinations NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.[location], death.[date], death.population, vaccination.new_vaccinations
, SUM(vaccination.new_vaccinations) OVER (Partition by death.location Order by death.location, death.date) AS Total_New_Vaccinations 
FROM Covid_Project_Database..CovidDeaths2 death
JOIN Covid_Project_Database..CovidVaccinations2 vaccination
    ON death.[location] = vaccination.[location]
    AND death.[date] = vaccination.[date]
WHERE death.continent <> 'NULL'

SELECT *, (Total_New_Vaccinations/Population)*100 AS Vac_Percentage
FROM #PercentPopulationVaccinated
----------------------------------------------------------------------------------------------------------------

--Creating View to store data for later visualization
IF OBJECT_ID('dbo.PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW dbo.PercentPopulationVaccinated
GO -- add this keyword to separate the IF statement from the CREATE VIEW statement

CREATE VIEW dbo.PercentPopulationVaccinated AS
    SELECT death.continent, death.[location], death.[date], death.population, vaccination.new_vaccinations
    ,SUM(vaccination.new_vaccinations) OVER (Partition by death.location Order by death.location, death.date) AS Total_New_Vaccinations 
    FROM Covid_Project_Database..CovidDeaths2 death
    JOIN Covid_Project_Database..CovidVaccinations2 vaccination
        ON death.[location] = vaccination.[location]
        AND death.[date] = vaccination.[date]
    WHERE death.continent <> 'NULL'

GO
    
SELECT *
FROM dbo.PercentPopulationVaccinated
WHERE Total_New_Vaccinations IS NOT NULL;

