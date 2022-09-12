alter table recipe
    add column number_of_servings int;

update recipe
    set number_of_servings = 1;

alter table recipe
    alter column number_of_servings set not null;