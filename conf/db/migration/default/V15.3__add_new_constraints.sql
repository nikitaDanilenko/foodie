alter table meal
    add constraint meal_pk primary key (user_id, profile_id, id),
    add constraint meal_user_id_profile_id_fk foreign key (user_id, profile_id) references profile (user_id, id) on delete cascade;

alter table meal_entry
    add constraint meal_entry_pk primary key (user_id, profile_id, meal_id, id),
    add constraint meal_entry_user_id_profile_id_fk foreign key (user_id, profile_id) references profile (user_id, id) on delete cascade,
    add constraint meal_entry_user_id_profile_id_meal_id_fk foreign key (user_id, profile_id, meal_id) references meal (user_id, profile_id, id) on delete cascade;
