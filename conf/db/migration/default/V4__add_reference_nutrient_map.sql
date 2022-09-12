create table reference_nutrient(
    user_id uuid not null,
    nutrient_code integer not null,
    amount decimal not null
);

alter table reference_nutrient
    add constraint reference_nutrient_pk primary key (user_id, nutrient_code),
    add constraint reference_nutrient_nutrient_code_fk foreign key (nutrient_code) references cnf.nutrient_name(nutrient_code);