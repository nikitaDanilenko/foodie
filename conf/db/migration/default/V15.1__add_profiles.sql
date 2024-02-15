create table profile
(
    id      uuid        not null,
    user_id uuid        not null,
    name    text unique not null
);

alter table profile
    add constraint profile_pk primary key (user_id, id),
    add constraint profile_user_id_fk foreign key (user_id) references "user" (id);

-- Create a default profile for each user with the same name as their nickname.
insert into profile (id, user_id, name)
select distinct on (id) uuid_generate_v4(), id, nickname
from "user";

alter table meal
    add column profile_id uuid;

update meal
set profile_id = profile.id
from profile
where meal.user_id = profile.user_id;

alter table meal
    alter column profile_id set not null;

alter table meal_entry
    add column profile_id uuid;

update meal_entry
set profile_id = profile.id
from profile
where meal_entry.user_id = profile.user_id;

alter table meal_entry
    alter column profile_id set not null;
