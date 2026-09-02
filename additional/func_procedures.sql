create function how_many_days_hospitalized(func_patient_id INT)
-- Возвращает число - кол-во дней сколько пациент лежал в нашем отделении (в последнюю свою госпитализацию)
returns integer as $$ 
declare
	cnt_days integer;
begin
	select
		case
			when h.discharge_date is not null
				then h.discharge_date - h.hospitalization_date -- разность уже в днях
			else
				CURRENT_DATE - h.hospitalization_date
		end
	into cnt_days
	from hospital_department.hospitalizations h
	where h.patient_id = func_patient_id
	order by h.hospitalization_date desc
	limit 1; -- в последнюю (самую новую) свою госпитализацию
	
	IF cnt_days IS NULL THEN
        RAISE NOTICE 'Пациент с ID % никогда не был госпитализирован в нашем отделении.', func_patient_id;
        RETURN 0;
    END IF;

	return cnt_days;
end;
$$ language plpgsql;


select *
from how_many_days_hospitalized(1) -- см табл hospitalizations, patients (Морозова Надежда Петровна)
-- ее последняя самая нижняя госпитализация , там как раз 19 дней



create procedure discharge_patient(func_patient_id INT)
	-- Выписывает пациента сегодняшним числом (вчерашним не получится) с обновлением статуса
language plpgsql
as $$
declare
    current_active_hospit_id INT;
begin
	-- Находим текущую активную госпитализацию пациента
    select hospitalization_id into current_active_hospit_id
    from hospital_department.hospitalizations
    where patient_id = func_patient_id and patient_status = 'Госпитализирован'
	order by hospitalization_date desc -- самые последние госпитализации нужны! как обычно
    limit 1;

    if current_active_hospit_id is null then
        raise exception 'Текущая активная госпитализация для пациента с id = % не найдена!', func_patient_id;
    end if;
	
	raise notice 'для пациента с id = %', func_patient_id;

    update hospital_department.hospitalizations
    set patient_status = 'Выписан'
    where hospitalization_id = current_active_hospit_id;
	raise notice 'Установлен статус ВЫПИСАН';

	update hospital_department.hospitalizations
    set discharge_date = CURRENT_DATE
    where hospitalization_id = current_active_hospit_id;
	raise notice 'Установлена сегодняшняя дата % выписки', CURRENT_DATE;
end;
$$;

call discharge_patient(4) -- по таблице это Сидоров, он был госпитализирован, пора выписать!




create procedure medicine_remove_amount_used_in_surgery(func_medicine_id INT)
	-- Списать использованное лекарство во время операции (с проверкой остатков)
language plpgsql
as $$
declare
	total_used_in_surgeries INTEGER := 0;
	quantity_left INTEGER := 0;
begin
	select COALESCE(SUM(u.quantity_used), 0) into total_used_in_surgeries
	from hospital_department.usage_in_surgeries u
	where u.medicine_id = func_medicine_id;

	if total_used_in_surgeries = 0 THEN
        raise notice 'Препарат с ID % не использовался в операциях', func_medicine_id;
        return;
    end if;

	update hospital_department.medicine_movement
	set quantity = quantity - total_used_in_surgeries
	where medicine_id = func_medicine_id;

	select m.quantity into quantity_left
	from hospital_department.medicine_movement m
	where m.medicine_id = func_medicine_id;
	

	if quantity_left <= 0 then
		raise notice 'Ой Ой Ой лекарство % не осталось! Надо дозаказать у поставщиков!', func_medicine_id;
	else
       raise notice 'Лекарство % успещно списано. Осталось на складе: %', func_medicine_id, quantity_left;
    end if;
	
end;
$$;

call medicine_remove_amount_used_in_surgery(1);
-- проверяем по таблице used_in_surgeries, и таблице medicine_movement

