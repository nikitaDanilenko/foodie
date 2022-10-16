import { Elm } from './Main.elm';
import './main.css';

const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {
        backendURL: process.env.ELM_APP_BACKEND_URL,
        mainPageURL: process.env.ELM_APP_MAIN_PAGE_URL
    }
});

const tokenKey = 'foodie-user-token';
const foodsKey = 'foodie-foods-list';
const measuresKey = 'foodie-measures-list';
const nutrientsKey = 'foodie-nutrients-list';

app.ports.storeToken.subscribe(function(token) {
    localStorage.setItem(tokenKey, token);
    app.ports.fetchToken.send(token);
});

app.ports.doFetchToken.subscribe(function() {
    const storedToken = localStorage.getItem(tokenKey);
    const tokenOrEmpty = storedToken ? storedToken : '';
    app.ports.fetchToken.send(tokenOrEmpty);
});

app.ports.doDeleteToken.subscribe(function() {
    localStorage.removeItem(tokenKey);
    app.ports.deleteToken.send(null);
});

app.ports.storeFoods.subscribe(function(foods) {
    localStorage.setItem(foodsKey, foods)
});

app.ports.doFetchFoods.subscribe(function() {
    const storedFoods = localStorage.getItem(foodsKey);
    const foodsOrEmpty = storedFoods ? storedFoods : '[]';
    app.ports.fetchFoods.send(foodsOrEmpty);
});

app.ports.storeMeasures.subscribe(function(measures) {
    localStorage.setItem(measuresKey, measures)
});

app.ports.doFetchMeasures.subscribe(function() {
    const storedMeasures = localStorage.getItem(measuresKey);
    const measuresOrEmpty = storedMeasures ? storedMeasures : '[]';
    app.ports.fetchMeasures.send(measuresOrEmpty);
});

app.ports.storeNutrients.subscribe(function(nutrients) {
    localStorage.setItem(nutrientsKey, nutrients)
});

app.ports.doFetchNutrients.subscribe(function() {
    const storedNutrients = localStorage.getItem(nutrientsKey);
    const nutrientsOrEmpty = storedNutrients ? storedNutrients : '[]';
    app.ports.fetchNutrients.send(nutrientsOrEmpty);
});