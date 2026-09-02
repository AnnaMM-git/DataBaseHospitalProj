-- Создание схемы
create schema hospital_department

-- Создание таблицы в схеме
create table hospital_department.positions (
	position_id serial primary key,
	position varchar(30) not null unique  check(position in ('врач', 'хирург', 'медсестра', 'ассистирующая медсестра', 'анестезиолог'))
);

create table hospital_department.employees (
	employee_id serial primary key,
	full_name varchar(100) not null,
	email varchar(100) not null unique,
	phone varchar(30) not null unique check(phone ~ '^\+7 \([0-9]{3}\) [0-9]{3}-[0-9]{2}-[0-9]{2}$'),
	salary integer not null,
	resign_date date default null check(resign_date is null or resign_date <= CURRENT_DATE)
);

-- Создание таблицы в схеме
create table hospital_department.employees_positions (
	employee_id integer references hospital_department.employees(employee_id) on delete restrict,
	position_id integer references hospital_department.positions(position_id) on delete restrict,
	primary key(position_id, employee_id)
);

-- Создание таблицы в схеме
create table hospital_department.patients (
    patient_id serial primary key,
    full_name VARCHAR(100) not null,
    birth_date DATE not null check(birth_date <= CURRENT_DATE),
    snils VARCHAR(20) not null unique check(snils ~ '^\d{3}-\d{3}-\d{3} \d{2}$'),
    polis VARCHAR(20) not null unique check (polis ~ '^\d{16}$'),
    medical_card_id VARCHAR(100) unique not null
);


create table hospital_department.boxes (
	box_id serial primary key,
	responsible_nurse_id integer references hospital_department.employees(employee_id) on delete restrict,
	cnt_bed_id integer not null default 0
);

create table hospital_department.mkb_codes (
	mkb_id serial primary key,
	mkb_code varchar(30) not null unique check(mkb_code ~ '^[A-Z][0-9]{2}(\.[0-9]{1,2})?$'),
	disease_name varchar(200) not null
);


create table hospital_department.hospitalizations (
	hospitalization_id serial primary key,
	patient_id integer references hospital_department.patients(patient_id) on delete restrict,
	hospitalization_date DATE not null check(hospitalization_date <= CURRENT_DATE),
	discharge_date DATE not null check(hospitalization_date <= discharge_date and discharge_date <= CURRENT_DATE),
	patient_status VARCHAR(20) not null check(patient_status in ('Выписан', 'Переведён', 'Госпитализирован')),
	box_id integer references hospital_department.boxes(box_id) on delete restrict,
	mkb_id integer references hospital_department.mkb_codes(mkb_id) on delete restrict,
	doctor_id integer references hospital_department.employees(employee_id) on delete restrict
);

create table hospital_department.surgeries (
	surgery_id serial primary key,
	hospitalization_id integer references hospital_department.hospitalizations(hospitalization_id) on delete restrict,
	surgery_date DATE not null check(surgery_date <= CURRENT_DATE),
	surgeon_id integer references hospital_department.employees(employee_id) on delete restrict,
	anesthetist_id integer references hospital_department.employees(employee_id) on delete restrict,
	surgical_nurse_id integer references hospital_department.employees(employee_id) on delete restrict
);

create table hospital_department.suppliers (
	supplier_id serial primary key,
	supplier_name varchar(200) not null unique,
	address varchar(200) not null unique,
	email varchar(200) not null unique,
	phone varchar(200) not null unique check(phone ~ '^\+7 \([0-9]{3}\) [0-9]{3}-[0-9]{2}-[0-9]{2}$'),
	inn varchar(200) not null unique check(inn ~ '^[A-Z0-9]{5,20}$'),
	bik varchar(200) not null unique check(bik ~ '^[0-9]{9}$'),
	raschetniy_schet varchar(200) not null unique check(raschetniy_schet ~ '^[0-9]{20}$'),
	cor_schet varchar(200) not null unique check(cor_schet ~ '^[0-9]{20}$'),
	contract_end_date date default null check(contract_end_date is null or contract_end_date <= CURRENT_DATE)
);

create table hospital_department.medicine (
	medicine_id serial primary key,
	supplier_id integer references hospital_department.suppliers(supplier_id) on delete restrict,
	series varchar(200) not null unique,
	storage_temp_min integer not null,
	storage_temp_max integer not null,
	is_life_vital bool not null,
	accepted_by_mdlp bool not null,
	expiration_date date not null
);

create table hospital_department.countries (
	country_code integer primary key,
	country_name varchar(100) not null unique
);


create table hospital_department.medicine_in_country (
	country_code integer references hospital_department.countries(country_code),
	medicine_id integer references hospital_department.medicine(medicine_id) on delete restrict,
	primary key (country_code, medicine_id)
);


create table hospital_department.prescriptions(
	prescription_id serial primary key,
	medicine_id integer references hospital_department.medicine(medicine_id) on delete cascade,
	hospitalization_id integer references hospital_department.hospitalizations(hospitalization_id) on delete cascade,
	prescribed_by integer references hospital_department.employees(employee_id) on delete restrict,
	start_date date not null,
	end_date date default null, check(end_date is null or end_date <= CURRENT_DATE),
	dosage varchar(100) not null,
	frequency integer not null,
	status varchar(100) not null check(status in ('Назначен', 'Отменен', 'Прием окончен'))
);


create table hospital_department.usage_in_surgeries(
	surgery_id integer,
	administered_by integer references hospital_department.employees(employee_id) on delete restrict,
	medicine_id integer references hospital_department.medicine(medicine_id) on delete restrict,
	quantity_used integer not null,
	primary key(surgery_id, administered_by, medicine_id)
);


create table hospital_department.medicine_movement(
	operation_id serial primary key,
	medicine_id integer references hospital_department.medicine(medicine_id) on delete restrict,
	quantity integer not null,
	operation_date date not null,
	performed_by integer references hospital_department.employees(employee_id) on delete restrict,
	supplier_id integer references hospital_department.suppliers(supplier_id) on delete cascade
);


