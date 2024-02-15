alter table meal_entry
    drop constraint meal_entry_pk,
    drop constraint meal_entry_user_id_meal_id_fk;

alter table meal
    drop constraint meal_pk;
