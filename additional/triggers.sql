-- Как и одна из пердыдущих функций, будет изменять остаток лекарства по складу
create or replace function medicine_amount_left_trg()
returns trigger as $$
declare
	quantity_left INTEGER := 0;
begin
	update hospital_department.medicine_movement
	set quantity = quantity - NEW.quantity_used
	where medicine_id = NEW.medicine_id;

	select quantity into quantity_left
	from hospital_department.medicine_movement
	where medicine_id = NEW.medicine_id
	limit 1;
	

	if quantity_left <= 0 then
		raise warning 'Ой Ой Ой лекарство % не осталось! Надо дозаказать у поставщиков!', NEW.medicine_id;
	else
       raise notice 'Лекарство % успещно списано. Осталось на складе: %', NEW.medicine_id, quantity_left;
    end if;
	
	return new;
end;
$$ language plpgsql;


create trigger trigger_medicine_amount_upd
   	after insert on hospital_department.usage_in_surgeries
    for each row
    execute function medicine_amount_left_trg();


insert into hospital_department.usage_in_surgeries values (30, 32, 28, 25);



-- При назначении лекарства пациенту, проверим срок годности лекарства, чтоб не отравить
create or replace function check_expire_date_on_prescribe_trg()
returns trigger as $$
declare
	prescr_medicine_id INTEGER := 0;
	prescr_expiration_date DATE;
begin
	select medicine_id, expiration_date into prescr_medicine_id, prescr_expiration_date
	from hospital_department.medicine 
	where medicine_id = NEW.medicine_id;

	if prescr_expiration_date is null then
        raise exception 'Лекарство с ID % не найдено!', NEW.medicine_id;
    end if;
	

	if prescr_expiration_date < CURRENT_DATE then
		raise exception 'У этого лекарства закончен срок годности!!!
							Нельзя прописывать! Надо списать в утилизацию и перезаказать у поставщиков';
	end if;

	raise notice 'Лекарство еще годно до %, все ОК, можно прописать', prescr_expiration_date;
	return NEW; -- продолжаем вставку
end;
$$ language plpgsql;

create trigger trigger_medicine_exp_date
	before insert on hospital_department.prescriptions
	for each row
    execute function check_expire_date_on_prescribe_trg();

insert into hospital_department.prescriptions (medicine_id, hospitalization_id, prescribed_by, start_date, end_date, dosage, frequency, status)
values (1, 20, 59, '2026-04-30', '2026-05-01', '150 мг', 1, 'Назначен');

