/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

#Step1: Import dataset into MySQL:

CREATE DATABASE IF NOT EXISTS covid_eda_project;
USE covid_eda_project;

DROP TABLE IF EXISTS CovidVaccinations;
CREATE TABLE CovidVaccinations
(iso_code VARCHAR(250),
continent VARCHAR(250),
location VARCHAR(250),
date VARCHAR(250),
new_tests VARCHAR(250),
total_tests VARCHAR(250),
total_tests_per_thousand VARCHAR(250),
new_tests_per_thousand VARCHAR(250),
new_tests_smoothed VARCHAR(250),
new_tests_smoothed_per_thousand VARCHAR(250),
positive_rate VARCHAR(250),
tests_per_case VARCHAR(250),
tests_units VARCHAR(250),
total_vaccinations VARCHAR(250),
people_vaccinated VARCHAR(250),
people_fully_vaccinated VARCHAR(250),
new_vaccinations VARCHAR(250),
new_vaccinations_smoothed VARCHAR(250),
total_vaccinations_per_hundred VARCHAR(250),
people_vaccinated_per_hundred VARCHAR(250),
people_fully_vaccinated_per_hundred VARCHAR(250),
new_vaccinations_smoothed_per_million VARCHAR(250),
stringency_index VARCHAR(250),
population_density VARCHAR(250),
median_age VARCHAR(250),
aged_65_older VARCHAR(250),
aged_70_older VARCHAR(250),
gdp_per_capita VARCHAR(250),
extreme_poverty VARCHAR(250),
cardiovasc_death_rate VARCHAR(250),
diabetes_prevalence VARCHAR(250),
female_smokers VARCHAR(250),
male_smokers VARCHAR(250),
handwashing_facilities VARCHAR(250),
hospital_beds_per_thousand VARCHAR(250),
life_expectancy VARCHAR(250),
human_development_index VARCHAR(250)
);


DROP TABLE IF EXISTS CovidDeaths;
CREATE TABLE CovidDeaths
(iso_code VARCHAR(250),
continent VARCHAR(250),
location VARCHAR(250),
date VARCHAR(250),
total_cases VARCHAR(250),
new_cases VARCHAR(250),
new_cases_smoothed VARCHAR(250),
total_deaths VARCHAR(250),
new_deaths VARCHAR(250),
new_deaths_smoothed VARCHAR(250),
total_cases_per_million VARCHAR(250),
new_cases_per_million VARCHAR(250),
new_cases_smoothed_per_million VARCHAR(250),
total_deaths_per_million VARCHAR(250),
new_deaths_per_million VARCHAR(250),
new_deaths_smoothed_per_million VARCHAR(250),
reproduction_rate VARCHAR(250),
icu_patients VARCHAR(250),
icu_patients_per_million VARCHAR(250),
hosp_patients VARCHAR(250),
hosp_patients_per_million VARCHAR(250),
weekly_icu_admissions VARCHAR(250),
weekly_icu_admissions_per_million VARCHAR(250),
weekly_hosp_admissions VARCHAR(250),
weekly_hosp_admissions_per_million VARCHAR(250),
new_tests VARCHAR(250),
total_tests VARCHAR(250),
total_tests_per_thousand VARCHAR(250),
new_tests_per_thousand VARCHAR(250),
new_tests_smoothed VARCHAR(250),
new_tests_smoothed_per_thousand VARCHAR(250),
positive_rate VARCHAR(250),
tests_per_case VARCHAR(250),
tests_units VARCHAR(250),
total_vaccinations VARCHAR(250),
people_vaccinated VARCHAR(250),
people_fully_vaccinated VARCHAR(250),
new_vaccinations VARCHAR(250),
new_vaccinations_smoothed VARCHAR(250),
total_vaccinations_per_hundred VARCHAR(250),
people_vaccinated_per_hundred VARCHAR(250),
people_fully_vaccinated_per_hundred VARCHAR(250),
new_vaccinations_smoothed_per_million VARCHAR(250),
stringency_index VARCHAR(250),
population VARCHAR(250),
population_density VARCHAR(250),
median_age VARCHAR(250),
aged_65_older VARCHAR(250),
aged_70_older VARCHAR(250),
gdp_per_capita VARCHAR(250),
extreme_poverty VARCHAR(250),
cardiovasc_death_rate VARCHAR(250),
diabetes_prevalence VARCHAR(250),
female_smokers VARCHAR(250),
male_smokers VARCHAR(250),
handwashing_facilities VARCHAR(250),
hospital_beds_per_thousand VARCHAR(250),
life_expectancy VARCHAR(250),
human_development_index VARCHAR(250)
);

#---------------------------------------------------------------------------
#Step2: change string to date format on column "date":
UPDATE covid_eda_project.covidvaccinations
SET date = STR_TO_DATE(date,'%m/%d/%Y');

Select date
from covid_eda_project.covidvaccinations;


UPDATE covid_eda_project.coviddeaths
SET date = STR_TO_DATE(date,'%m/%d/%Y');

Select date
from covid_eda_project.coviddeaths;

#---------------------------------------------------------------------------
#Step3: Starting EDA on Dataset:
#Questions we want to answer:
#1: what is the death percentage of each country?
#2: what is the infection rate of each country?
#3: Countries with Highest Death Count per Population?
#4: Percentage of Population that has recieved at least one Covid Vaccine?
#5: Let's break things down by continent
#6: How to use current data to build a covid dashboard?

-- Take a look on the coviddeaths dataset
Select *
From coviddeaths
Where continent is not null 
order by 3,4;


-- Select variables that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
Where continent is not null 
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
-- Take a look at the death percentage of United States by date:
-- Overall, the death percentage is decreasing in the United States from the beginning of 2020 to April, 2021.

Select Location, date, total_cases,total_deaths, Round((total_deaths/total_cases)*100,2) as DeathPercentage
From CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid by location by date
-- Until 2021-04-30, the infection rate of United States population has reached 9.77%.

Select Location, date, Population, total_cases,  Round((total_cases/population)*100,2) as PercentPopulationInfected
From CovidDeaths
Where location like '%states%'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population
-- The country has the highest infection rate is Andorra, which has 17.13% of infection compared to population.
Select Location, Population, MAX(total_cases) as HighestInfectionCount, Round(Max((total_cases/population))*100,2) as PercentPopulationInfected
From CovidDeaths
#Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population
-- Note that when the continent is NULL or empty, the location column shows the continent info instead;
-- In results, we can see that the country has the highest death count per population is United States;
Select Location, MAX(CAST(coviddeaths.total_cases AS UNSIGNED)) as TotalDeathCount
From CovidDeaths
WHERE coviddeaths.continent IS NOT NULL
AND coviddeaths.continent <> ""
Group by Location
order by TotalDeathCount desc;




-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
-- In results, we can see that the continent has the highest death count per population is North America;
Select continent, MAX(CAST(coviddeaths.total_cases AS UNSIGNED)) as TotalDeathCount
From CovidDeaths
WHERE coviddeaths.continent IS NOT NULL
AND coviddeaths.continent <> ""
Group by continent
order by TotalDeathCount desc;



-- GLOBAL NUMBERS: 2.11% death percentage across world

# This does not work is because if we select multiple things, we can not only group by one thing;
# The soluntion is do aggregate function on evey single variable that we selected;
/*Select total_cases, total_deaths, ROUND(total_cases/total_deaths*100, 2) as DeathPercentage
From CovidDeaths
WHERE coviddeaths.continent IS NOT NULL
AND coviddeaths.continent <> ""
group by date
order by 1,2;
*/

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, ROUND(SUM(new_deaths)/SUM(new_Cases)*100, 2) as DeathPercentage
From CovidDeaths
WHERE coviddeaths.continent IS NOT NULL
AND coviddeaths.continent <> ""
order by 1,2;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
AND dea.continent <> ""
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
AND dea.continent <> ""
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query
-- using string data type for new_vaccination and population because two columns contain empty values:
DROP Table if exists PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent VARCHAR(255),
Location VARCHAR(255),
Date datetime,
Population VARCHAR(255),
New_vaccinations VARCHAR(255),
RollingPeopleVaccinated decimal(43,0)
);


INSERT INTO PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
AND dea.continent <> "";

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated;




-- Creating View to store data for later visualizations

CREATE VIEW PercentageVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS unsigned)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
AND dea.continent <> "";

/*

Queries used for Tableau Project

*/



-- 1. golobal number 

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, ROUND(SUM(new_deaths)/SUM(new_Cases)*100, 2) as DeathPercentage
From CovidDeaths
WHERE coviddeaths.continent IS NOT NULL
AND coviddeaths.continent <> ""
order by 1,2;



-- 2. Total death count by continent
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, MAX(CAST(coviddeaths.total_deaths AS UNSIGNED)) as TotalDeathCount
From coviddeaths
Where coviddeaths.continent = ""
and coviddeaths.location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc;

-- 3. percentage of people infected by country

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
WHERE continent <> ""
Group by Location, Population
order by PercentPopulationInfected desc;


-- 4. percentage of people infected by country by date
Select Location, Population, date, MAX(total_cases) as HighestInfectionCount,  
Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
WHERE continent <> "" 
Group by Location, Population, date
order by PercentPopulationInfected desc;





















