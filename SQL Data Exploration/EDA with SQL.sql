select *
from master..CovidDeaths
order by 3, 4

select location, date, total_cases, new_cases, total_deaths, population
from master..CovidDeaths
order by 1, 2

-- total cases vs total_deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from master..CovidDeaths
where location like '%state%'
order by 1, 2

-- total cases vs populations
select location, date, total_cases, population, (total_cases/population)*100 as InfectedPercentage
from master..CovidDeaths
where location like '%state%'
order by 1, 2

--Country with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population) *100) as
InfectedPercentage
from master..CovidDeaths
group by location, population
order by InfectedPercentage desc


-- Country or continent with highest death count
select location, max(cast(total_deaths as int)) as TotalDeathCount
from master..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from master..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- showing continent with highest death count per  population
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from master..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount

--Global number
select sum(new_cases) as NewCases, sum(cast(new_deaths as int)) as NewDeath, 
	(sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage--total_cases, total_deaths, (total_deaths/total_cases)*100 as	DeathPercentage
from master..CovidDeaths
where continent is not null
--group by date --, total_cases, total_deaths
order  by 1, 2

-- Join 2 tables

select dea.continent, dea.location, dea.date, dea.population
from master..CovidDeaths dea 
	join master..CovidVacinations vac 
		on dea.location = dea.location
		and dea.date = vac.date
where dea.continent is not null
order by 1, 2

-- total population vs vacinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from master..CovidDeaths dea
	join master..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

--  use cte
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from master..CovidDeaths dea
	join master..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)

Select * , (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage
From PopVsVac
-- Create Temp table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from master..CovidDeaths dea
	join master..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select * , (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage
From #PercentPopulationVaccinated

-- Creating view to store data for later visualization
Create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from master..CovidDeaths dea
	join master..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


select *
from PercentPopulationVaccinated