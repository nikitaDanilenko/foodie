create table complex_food
(
    recipe_id uuid    not null,
    amount    decimal not null,
    unit      text    not null
);

alter table complex_food
    add constraint complex_food_pk primary key (recipe_id),
    add constraint complex_food_recipe_id_fk foreign key (recipe_id) references recipe (id) on delete cascade,
    add constraint amount_positive check (amount > 0),
    add constraint unit_enumeration check ( unit = 'G' or unit = 'ML' );

create table complex_ingredient
(
    recipe_id       uuid    not null,
    complex_food_id uuid    not null,
    factor          decimal not null
);

alter table complex_ingredient
    add constraint complex_ingredient_pk primary key (recipe_id, complex_food_id),
    add constraint complex_ingredient_recipe_id_fk foreign key (recipe_id) references recipe (id) on delete cascade,
    add constraint complex_ingredient_complex_food_id_fk foreign key (complex_food_id) references complex_food (recipe_id) on delete cascade,
    add constraint complex_ingredient_positive_factor check ( factor > 0 );
