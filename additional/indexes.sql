-- По сроку годности лекарств
create index medicine_expiration_date_idx on hospital_department.medicine using btree(expiration_date)
	with fillfactor(90) -- для редких делений листа на 2 при вставке (снижение I/O)
	include (medicine_id, series, supplier_id, is_life_vital) -- include для Index Only Scan
    where is_life_vital = true; -- частичный (чаще интересуемся именно life vital medicine)
    -- where чтобы поймать tradeoff между размером индекса и уменьшением I/O (Seq Scan / Index Scan)

-- колонки подаю в том порядке как они в creation_script у меня написаны

-- ИСТОРИЯ ЛЕЧЕНИЯ (в запросах 7 и 8)
-- в запросах (см примеры ранее) мы часто хотим знать, сколько госпитализированных пациентов и когда они были госпитализированы
-- для дат могут быть так же запросы на диапазон 
-- (сколько человек лежала в больнице в январе 01.01 <= date <= 31.01)
create index hospitalizations_dates_idx on hospital_department.hospitalizations
	using btree(patient_id, hospitalization_date desc) -- составной
	-- если в order by ASC, то просто в обратном порядке для индекса это ОК
	include (doctor_id, patient_status);

-- Движение лекарств
create index medicine_movement_date_idx on hospital_department.medicine_movement 
    using btree(medicine_id, operation_date DESC); -- desc чтобы от самых новых к самым старым

    
-- большинство остальных столбцов у меня id-чего-то-там - это primary_key или unique (типа документы: снилс инн...)
-- для них автоматически создаются индексы
	
-- SPOILER ALERT: на самом деле БД использует B+ Tree, поэтому include -- OK

