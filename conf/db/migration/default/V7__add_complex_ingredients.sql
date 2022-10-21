create table complex_ingredient
(
    recipe_id uuid    not null,
    factor    decimal not null,
    unit      text    not null
);

alter table complex_ingredient
    add constraint complex_ingredient_pk primary key (recipe_id),
    add constraint complex_ingredient_recipe_id foreign key (recipe_id) references recipe (id),
    add constraint unit_enumeration check ( unit = 'G' or unit = 'ML' );