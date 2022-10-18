create table reference_map
(
    id      uuid not null,
    name    text not null,
    user_id uuid not null
);

alter table reference_map
    add constraint reference_map_pk primary key (id),
    add constraint reference_map_user_id_fk foreign key (user_id) references "user"(id) on delete cascade;

create table reference_entry
(
    reference_map_id uuid    not null,
    nutrient_code    integer not null,
    amount           decimal not null
);

alter table reference_entry
    add constraint reference_entry_pk primary key (reference_map_id, nutrient_code),
    add constraint reference_entry_reference_map_id_fk foreign key (reference_map_id) references reference_map(id) on delete cascade,
    add constraint reference_entry_nutrient_code_fk foreign key (nutrient_code) references cnf.nutrient_name(nutrient_code) on delete cascade;

create extension if not exists "uuid-ossp";

insert into reference_map (id, name, user_id)
select distinct on (user_id) uuid_generate_v4(), 'References', user_id
from reference_nutrient;

insert into reference_entry (reference_map_id, nutrient_code, amount)
select reference_map.id, reference_nutrient.nutrient_code, reference_nutrient.amount
from reference_map
         inner join reference_nutrient on reference_map.user_id = reference_nutrient.user_id;

drop table reference_nutrient;