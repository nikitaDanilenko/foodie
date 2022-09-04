import { Elm } from './Main.elm';

var app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    backendURL: process.env.ELM_APP_BACKEND_URL,
    mainPageURL: process.env.ELM_APP_MAIN_PAGE_URL,
  }
});

var tokenKey = 'foodie-user-token';
var foodsKey = 'foodie-foods-list';
var measuresKey = 'foodie-measures-list';

app.ports.storeToken.subscribe(function(token) {
    localStorage.setItem(tokenKey, token);
});

app.ports.doFetchToken.subscribe(function() {
    var storedToken = localStorage.getItem(tokenKey);
    var tokenOrEmpty = storedToken ? storedToken : '';
    app.ports.fetchToken.send(tokenOrEmpty);
});

app.ports.storeFoods.subscribe(function(foods) {
    localStorage.setItem(foodsKey, foods)
});

app.ports.doFetchFoods.subscribe(function() {
    var storedFoods = localStorage.getItem(foodsKey);
    var foodsOrEmpty = storedFoods ? storedFoods : '[]';
    app.ports.fetchFoods.send(foodsOrEmpty);
});

app.ports.storeMeasures.subscribe(function(measures) {
    localStorage.setItem(measuresKey, measures)
});

app.ports.doFetchMeasures.subscribe(function() {
    var storedMeasures = localStorage.getItem(measuresKey);
    var measuresOrEmpty = storedMeasures ? storedMeasures : '[]';
    app.ports.fetchMeasures.send(measuresOrEmpty);
});