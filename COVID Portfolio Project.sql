select *
from PortfolioProject..Covid_Deaths$
where continent is not null
order by 3,4 

--select *
--from PortfolioProject..Covid_Vacinations$
--order by 3,4 

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..Covid_Deaths$
order by 1,2
 
 --looking total cases vs total deaths

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeatPrecentage
from PortfolioProject..Covid_Deaths$
Where location like '%Brunei%'
order by 1,2

--shows likelihood of dying f contact with covid in your country

--looking at total cases vs population

select Location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
from PortfolioProject..Covid_Deaths$
--Where location like '%asia%'
order by 1,2


--looking at country with highest infection rate to population

select Location, population, max(total_cases) as HighestInnfectionCount, max((total_cases/population))*100 as PercentagePopulationInfected
from PortfolioProject..Covid_Deaths$
--Where location like '%asia%'
Group by  Location, population
order by PercentagePopulationInfected desc

--showing countries with highest Death Count per Population

select Location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..Covid_Deaths$
--Where location like '%asia%'
where continent is not null
Group by  Location
order by TotalDeathCount desc


--Let's Break things down by continent

-- showing the continent with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..Covid_Deaths$
--Where location like '%asia%'
where continent is not null
Group by continent
order by TotalDeathCount desc


-- Global Numbers

select sum(new_cases) as total_cases , sum(cast(new_deaths as int)) as total_deaths , sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPrecentage
from PortfolioProject..Covid_Deaths$
--Where location like '%Brunei%'
where continent is not null
--Group by date
order by 1,2


-- looking at total population vs vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..Covid_Deaths$ dea
join PortfolioProject..Covid_Vacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- total new_vaccination

-- use CTE

with PopvsVac (continent, Location, Date, Population,new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Covid_Deaths$ dea
join PortfolioProject..Covid_Vacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- use temp table

Drop table if exists #PercentagePopulationVaccinated 
create table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Covid_Deaths$ dea
join PortfolioProject..Covid_Vacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
From #PercentagePopulationVaccinated


--creating view to store data for later visualizations

create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Covid_Deaths$ dea
join PortfolioProject..Covid_Vacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3



select *
from PercentagePopulationVaccinated