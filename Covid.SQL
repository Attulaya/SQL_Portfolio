--selecting the data we are going to use
select location,date,total_cases,new_cases,total_deaths,population
from Portfolio_Project..covid_deaths
order by 1,2

--looking at total cases vd total deaths
--shows the likelyhood of dying when u contract covid
--select location,date,total_cases,total_deaths,(cast(total_deaths as float) / cast(total_cases as float))*100 as DeathPercentage,(cast(total_cases as float) / cast(population as float))*100 as affected_percentage
--from Portfolio_Project..covid_deaths
--order by 1,2

--select location,population,max(cast(total_cases as int))as max_cases,max(cast(total_cases as float) / cast(population as float))*100 as max_infected_population
--from Portfolio_Project..covid_deaths
--group by location,population
--order by max_infected_population desc

select location,max(cast(total_deaths as int))as total_death_count
from Portfolio_Project..covid_deaths
where continent is not null
group by location
order by total_death_count desc


--break things down by continent
with cte as
(select continent,location,max(cast(total_deaths as int))as total_death_count
from Portfolio_Project..covid_deaths
where continent is not null
group by location,continent
)select continent, sum(total_death_count)as td
from cte
group by continent
order by td

--different method
select location,max(cast(total_deaths as int))as total_death_count
from Portfolio_Project..covid_deaths
where continent is null
group by location
order by total_death_count desc

--showing continents with highest death count per population
select continent,max(cast(total_deaths as int))as total_death_count
from Portfolio_Project..covid_deaths
where continent is not null
group by continent
order by total_death_count desc

--global numbers

SELECT
    SUM(new_cases) AS cases,
    SUM(new_deaths) AS deaths,
    SUM(new_deaths) / SUM(new_cases) AS death_percentage
FROM
    Portfolio_Project..covid_deaths
WHERE
    continent IS NOT NULL

--use vaccination
select *
from Portfolio_Project..covid_vaccinations
order by iso_code,continent,date

--looking at total population vs vacination
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null and vac.location like '%India%'
order by 1,2,3

--considering overall vaccination in india
select SUM(cast(vac.new_vaccinations as int))
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null and vac.location like '%India%'

--considering overall vaccination in world
select SUM(cast(vac.new_vaccinations as bigint))
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null 

--roll over vaccine count
create view roll_over_vaccination_count as
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(cast(vac.new_vaccinations as bigint))
over(partition by dea.location  order by dea.location,dea.date)as roll_over_vaccination_count
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null and dea.location like '%India%' 
--order by 2,3

--when india reached a roll over vaccine count of 1 crore
with cte_1 as
(
select dea.continent as conti,dea.location as loc,dea.date as date_,dea.population as pop,vac.new_vaccinations as new_vac,SUM(cast(vac.new_vaccinations as bigint))
over(partition by dea.location  order by dea.location,dea.date)as roll_over_vaccination_count
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null and dea.location like '%India%' 

)
select conti, loc, date_, pop, new_vac, roll_over_vaccination_count
from cte_1
group by conti, loc, date_, pop, new_vac, roll_over_vaccination_count
having roll_over_vaccination_count > 10000000 and roll_over_vaccination_count < 10400000
order by 2,3 

--percentage of people vaccinated over the time
with popvsvac as
(
select dea.continent as conti,dea.location as loc,dea.date as date_,dea.population as pop,vac.new_vaccinations as new_vac,SUM(cast(vac.new_vaccinations as bigint))
over(partition by dea.location  order by dea.location,dea.date)as roll_over_vaccination_count
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null 
)
select conti, loc, date_, pop, new_vac, roll_over_vaccination_count,(roll_over_vaccination_count/pop)*100 as percentage_of_people_vacinated
from popvsvac
order by 2,3 

--view for visualization
create view population_vaccinated_percentage as
with popvsvac as
(
select dea.continent as conti,dea.location as loc,dea.date as date_,dea.population as pop,vac.new_vaccinations as new_vac,SUM(cast(vac.new_vaccinations as bigint))
over(partition by dea.location  order by dea.location,dea.date)as roll_over_vaccination_count
from Portfolio_Project..covid_deaths dea
join Portfolio_Project..covid_vaccinations vac
on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null 
)
select conti, loc, date_, pop, new_vac, roll_over_vaccination_count,(roll_over_vaccination_count/pop)*100 as percentage_of_people_vacinated
from popvsvac
--order by 2,3 
