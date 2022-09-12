alter table recipe
    add column number_of_servings decimal;

update recipe
    set number_of_servings = 1;

alter table recipe
    alter column number_of_servings set not null;

alter table meal_entry
    rename column factor to number_of_servings;