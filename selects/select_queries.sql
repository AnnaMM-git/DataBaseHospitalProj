--1  Выведем справочник МКБ-кодов основных диагнозов
select mkb_code, disease_name 
from hospital_department.mkb_codes
order by mkb_code

--2 Какие лекарства просрочатся в следующем месяце? Вывести id
SELECT m.medicine_id, m.series
FROM hospital_department.medicine m
where extract(month FROM expiration_date) = extract(month FROM CURRENT_DATE) + 1 and
	  extract(year from expiration_date) = extract(year from CURRENT_DATE)	
group by medicine_id




--3 Выведем последние активные госпитализации с ФИО пациента, датой поступления, 
-- названием диагноза и именем лечащего врача
select p.full_name as patient_name, h.hospitalization_date, e.full_name as doctor_name, mc.disease_name 
from hospital_department.hospitalizations h 
join hospital_department.patients p on p.patient_id = h.patient_id
join hospital_department.employees e on e.employee_id = h.doctor_id
join hospital_department.mkb_codes mc on mc.mkb_id = h.mkb_id
where patient_status = 'Госпитализирован'




--4 Посчитаем, сколько раз каждый пациент был госпитализирован. 
-- Покажем только тех, у кого больше 1 госпитализации, и отсортируем по количеству (от самых частых).
select p.full_name, COUNT(h.hospitalization_id) as hospitalizations_cnt
from hospital_department.patients p 
join hospital_department.hospitalizations h on h.patient_id  = p.patient_id 
group by p.patient_id
having COUNT(h.hospitalization_id) > 1
order by COUNT(h.hospitalization_id) desc



--5  ТОП 5 самых частых диагнозов
select mc.mkb_id, mc.disease_name, COUNT(*) AS hospitalizations_cnt
from hospital_department.hospitalizations h 
join hospital_department.mkb_codes mc on mc.mkb_id = h.mkb_id
group by mc.mkb_id
order by COUNT(*) desc
offset 0
limit 5





--6 Какие чаще всего используются иностранные или отечественные препараты?
-- под использоваться подразумевается использование в usage_in_surgeries, prescriptions
-- отчественные в моей таблице это те которые содержат 'Моск'
-- Сравнение частоты использования отечественных и иностранных препаратов
select 
    case 
        when mic.country_code = '643' then 'Отечественные'
        else 'Иностранные'
    end as origin,
    COUNT(distinct p.prescription_id) + COUNT(distinct uis.quantity_used) as total_usages,
    COUNT(distinct p.prescription_id) as prescriptions_count,
    COUNT(distinct uis.quantity_used ) as used_in_surgeries_count
from hospital_department.medicine m
join hospital_department.suppliers s on m.supplier_id = s.supplier_id
join hospital_department.medicine_in_country mic on mic.medicine_id = m.medicine_id 
join hospital_department.prescriptions p on p.medicine_id = m.medicine_id
join hospital_department.usage_in_surgeries uis on uis.medicine_id = m.medicine_id
group by origin
order by total_usages desc;





--7 Нумерация госпитализаций внутри каждого пациента по датам по возрастанию
-- вывеедем полное имя пациента, каждую из дат госпитализации, название болезни и пронумеруем госпитализации

select p.full_name, h.hospitalization_date, mc.disease_name,
    ROW_NUMBER() OVER (partition by h.patient_id order by h.hospitalization_date asc) AS hospitalization_number
from hospital_department.hospitalizations h
join hospital_department.patients p on p.patient_id = h.patient_id
join hospital_department.mkb_codes mc on mc.mkb_id = h.mkb_id
order by p.full_name, h.hospitalization_date asc;







--8 для каждого пацента выведем  как обычно: полное имя, дату госпитализации, диагноз и 
-- кол-во дней между госпитализациями (для тех паицентов у кого >= 2 госпитализации)

select p.full_name, h.hospitalization_date, mc.disease_name,
    h.hospitalization_date - lag(h.hospitalization_date) over (partition by h.patient_id order by h.hospitalization_date) as days_between
from hospital_department.hospitalizations h
join hospital_department.patients p on p.patient_id = h.patient_id
join hospital_department.mkb_codes mc on mc.mkb_id = h.mkb_id
where h.patient_id in (
    select patient_id 
    from hospital_department.hospitalizations 
    group by patient_id 
    having COUNT(*) >= 2
)
order by p.full_name, h.hospitalization_date asc;




--9 Покажем всех сотрудников с ФИО, должностью и количеством пациентов, которых они сейчас ведут (только активные госпитализации).
-- distinct on Королев у меня и врач и хирург, но мне это не особо интересно
select distinct on (e.full_name) e.full_name as doctor, p.position, COUNT(distinct p2.patient_id) as cnt_active_patients
from hospital_department.employees e 
-- для получения позиции
join hospital_department.employees_positions ep on e.employee_id = ep.employee_id 
join hospital_department.positions p on ep.position_id = p.position_id
-- для получения пациентов
join hospital_department.hospitalizations h on h.doctor_id = e.employee_id 
join hospital_department.patients p2 on p2.patient_id = h.patient_id 
where h.patient_status = 'Госпитализирован'
group by e.full_name, p.position
order by e.full_name




--10 Найдем сотрудников, которые одновременно работают и как (лечащий) врач, и как хирург
select e.full_name as doctor, STRING_AGG(distinct p.position, ', ' order by p.position) as all_positions
from hospital_department.employees e
join hospital_department.employees_positions ep on e.employee_id = ep.employee_id
join hospital_department.positions p on ep.position_id = p.position_id
where exists (
    select 1
    from hospital_department.employees_positions ep2 
    where ep2.employee_id = e.employee_id and ep2.position_id = 1 -- id позиции врач (см табл posititons)
)
and exists (
    select 1
    from hospital_department.employees_positions ep2 
    where ep2.employee_id = e.employee_id and ep2.position_id = 2 -- id позиции хирург (см табл posititons)
)
group by e.full_name;





--11 Показать кол-во поставленных отечетсвенными поставщиками лекарств по дате
with native_medicine as (
	select mm.*
	from hospital_department.medicine_movement mm 
	join hospital_department.suppliers s on s.supplier_id = mm.supplier_id
	join hospital_department.medicine_in_country mc on mc.medicine_id = mm.medicine_id
	where mc.country_code = '643' -- Россия (отечественные)
)

select distinct on (operation_date) operation_date,
	   SUM(quantity) over (partition by operation_date order by operation_date) as accepted_amount
from native_medicine
order by operation_date;




--12 Найдем отечественные препараты, которые поставлялись в количестве больше среднего за все поставки (тоже только отечественных).
with native_medicine as (
	select mm.*
	from hospital_department.medicine_movement mm 
	join hospital_department.suppliers s on s.supplier_id = mm.supplier_id
	join hospital_department.medicine_in_country mc on mc.medicine_id = mm.medicine_id
	where mc.country_code = '643' -- Россия (отечественные)
),

-- общее кол-во поставок для каждого отеч препарата
medicine_supply_times as (
	select medicine_id, COUNT(*) as cnt_supplies
	from native_medicine
	group by medicine_id 
),
-- среднее кол-во поставок по всем отеч препаратам
avg_supllies as (
	select AVG(cnt_supplies) as avg
	from medicine_supply_times
)

select 
    mst.medicine_id,
    mst.cnt_supplies,
    ROUND(avs.avg, 2) as average_all,
    case 
        when mst.cnt_supplies > avs.avg then 'выше среднего'
        else 'ниже среднего'
    end as comparison
from medicine_supply_times mst -- тут k строк
cross join avg_supllies avs     -- тут 1 строка avg 
-- после cross join (декартово произведение) полчим k x 1 = k строк
where mst.cnt_supplies > avs.avg
order by mst.cnt_supplies desc;





--13 Выведем имена сотрудников, которые пользуются почтой gmal.com
select e.full_name, e.email
from hospital_department.employees e 
where email LIKE '%gmail.com'
order by e.full_name; 
--"%" - 0 или более символов




