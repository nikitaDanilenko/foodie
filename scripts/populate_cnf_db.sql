\cd scripts;

\copy cnf.food_group from 'cnf/FOOD GROUP.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.food_source from 'cnf/FOOD SOURCE.csv' delimiter ',' csv header encoding 'ISO-8859-1'

\copy cnf.nutrient_source from 'cnf/NUTRIENT SOURCE.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.nutrient_name from 'cnf/NUTRIENT NAME.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.nutrient_amount from 'cnf/NUTRIENT AMOUNT.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.food_name from 'cnf/FOOD NAME.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.yield_name from 'cnf/YIELD NAME.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.yield_amount from 'cnf/YIELD AMOUNT.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.refuse_name from 'cnf/REFUSE NAME.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.refuse_amount from 'cnf/REFUSE AMOUNT.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.measure_name from 'cnf/MEASURE NAME.csv' delimiter ',' csv header encoding 'ISO-8859-1';

\copy cnf.conversion_factor from 'cnf/CONVERSION FACTOR.csv' delimiter ',' csv header encoding 'ISO-8859-1';
