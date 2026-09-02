-- VIEW --- это CTE на максималках, только CTE cуществует в рамках одного запроса,
-- а вот view хранится в памяти и можно сколько угодно много раз его использовать (как глобальная перемнная)

-- из SELECT query 11 переделала CTE на VIEW
create materialized view hospital_department.native_medicine as (
	select m.series as medicine,
	s.supplier_name as supplier,
	mm.quantity as amount, 
	mm.performed_by as accepted_to_storage_by,
	mc.country_code
	
	from hospital_department.medicine_movement mm 
	join hospital_department.medicine m ON m.medicine_id = mm.medicine_id
	join hospital_department.suppliers s ON s.supplier_id = mm.supplier_id
	join hospital_department.medicine_in_country mc on mc.medicine_id = mm.medicine_id
	where mc.country_code = '643' -- Россия (отечественные)
);

-- materialized ибо поставщики не так часто меняются, соответсвенно набор лекарств тоже, 
-- поэтому если новое лекарство изобрели или мы поставщика сменили можно и refresh сделать, зато храним на индексе,
-- не перекомпилируем каждый раз select, храним на диске => можно индексировать как и обычную таблицу

-- sleect query 3 переделан на view, ибо оно часто нам такое надо
create view hospital_department.active_hospitalizations as (
	select p.full_name as patient_name, h.hospitalization_date, e.full_name as doctor_name, mc.disease_name 
	from hospital_department.hospitalizations h 
	join hospital_department.patients p on p.patient_id = h.patient_id
	join hospital_department.employees e on e.employee_id = h.doctor_id
	join hospital_department.mkb_codes mc on mc.mkb_id = h.mkb_id
	where patient_status = 'Госпитализирован'
);

-- нематериально, не сгружаем на диск, при каждом обращении seect заново выполняется внутри view, всегда свежие даные, но надо ждать,
-- такое view, ибо пациенты приходят и уходят данные часто обновляется и они нам нужны всегда актуальные


--работают:
select *
from hospital_department.native_medicine

select *
from hospital_department.active_hospitalizations