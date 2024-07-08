--Describe Columns
EXEC sp_columns 'CovidDeaths';
EXEC sp_columns 'CovidVaccinations';

--Select the table
Select * 
From msplayground..CovidDeaths Order By 3,4;

Select * 
From msplayground..CovidVaccinations Order By 3,4;

--Data standardization
UPDATE msplayground..CovidDeaths
SET date = CONVERT(DATE, date , 103);

UPDATE msplayground..CovidVaccinations
SET date = CONVERT(DATE, date , 103);

ALTER TABLE msplayground..CovidDeaths
ALTER COLUMN date date;

ALTER TABLE msplayground..CovidVaccinations
ALTER COLUMN date date;

--Table has continents in location column and these rows are total numbers by continent, their continents are null
--I will fill their continent column with Earth
UPDATE msplayground..CovidDeaths
Set continent ='Earth'
Where continent = ' ';

UPDATE msplayground..CovidVaccinations
Set continent ='Earth'
Where continent = ' ';

UPDATE msplayground..CovidVaccinations
Set total_tests =0
Where total_tests = ' ';

--Quick look
Select Location, date, total_cases, new_cases, total_deaths, population
From msplayground..CovidDeaths
Where continent != 'Earth'
order by Location, date;

--Number of total countries
Select  Distinct location from msplayground..CovidDeaths
Where continent !='Earth';

--Period of data
Select min(date) as min_date, max(date) as max_date, DATEDIFF(day,min(date), max(date)) as date_diff
From msplayground..CovidDeaths;

--Global Cases vs Global Death
	Select 	max(population) as world_population,
	(Select max(people_vaccinated) From msplayground..CovidVaccinations) as people_vaccinated,
	max(total_cases) as global_cases,
	(CAST(max(total_cases) AS FLOAT) / max(population))*100 as case_rate_to_world_population,
	max(total_deaths) as global_deaths,
	(CAST(max(total_deaths) AS FLOAT) / max(population)) * 100 as death_rate_to_world_population,
	(CAST(max(total_deaths) AS FLOAT) / max(total_cases))*100 as covid_death_rate
	From msplayground..CovidDeaths 
	Where location = 'World'

--Total Deaths, Cases By Continent
Select cd.continent,
	max(cd.population) as continent_population,
	max(cd.total_cases) as continent_total_cases,
	max(cd.total_deaths) as continent_total_deaths,
	(max(CAST(cd.total_cases AS FLOAT)) / max(cd.population))*100 as continent_case_rate,
	(max(CAST(cd.total_deaths AS FLOAT)) / max(cd.population))*100 as continent_death_rate,
	(max(cv.people_vaccinated)) as people_vaccinated
From msplayground..CovidDeaths as cd
JOIN msplayground..CovidVaccinations as cv
	ON  cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent != 'Earth'
Group By cd.continent Order By continent_total_deaths desc;

--Data ordered by country and date
Select cd.continent, cd.location, cd.date, cd.total_cases, cd.new_cases, cd.total_deaths, cd.new_deaths,
cv.total_tests, cv.people_vaccinated, cv.people_fully_vaccinated, cd.population
From msplayground..CovidDeaths cd
JOIN msplayground..CovidVaccinations cv
	ON cd.location = cv.location
	and cd.date = cv.date
Where cd.continent != 'Earth'
Order By cd.location, cd.date;

--Cases and Deaths By Country
--Creating view to store data for visualizations
--CREATE VIEW CovidStatsByCountry AS
WITH CTE AS (
	Select 
		cd.location,
		max(cd.total_cases) as total_case,
		max(cd.total_deaths) as total_death,
		max(cv.total_tests) as total_tests,
		max(cv.people_vaccinated) as people_vaccinated,
		max(cv.people_fully_vaccinated) as people_fully_vaccinated,
		max(cd.population) as country_population
	From msplayground..CovidDeaths cd
	JOIN msplayground..CovidVaccinations cv
		ON  cd.location = cv.location
		and cd.date = cv.date
	Where cd.continent != 'Earth'
	Group By cd.location 
),
CTE2 AS(
	Select *,
		CASE
			WHEN total_death = 0
			THEN  0
			ELSE ((total_death) / CAST(total_case AS FLOAT))*100
		END as death_to_case_ratio,
		CASE
			WHEN people_fully_vaccinated = 0 or  country_population = 0
			THEN  0
			ELSE (CAST(people_fully_vaccinated AS FLOAT) / country_population) *100
		END as fully_vaccinated_to_population,
		CASE
			WHEN total_death = 0 or  country_population = 0
			THEN  0
			ELSE (CAST(total_death AS FLOAT) / country_population) *100
		END as death_to_population_ratio
	From CTE
)
Select * From CTE2;

--Checking if view is works
Select * From CovidStatsByCountry;



