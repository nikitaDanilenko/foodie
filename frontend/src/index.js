import { Elm } from './Main.elm';

Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    backendURL: process.env.ELM_APP_BACKEND_URL,
    mainPageURL: process.env.ELM_APP_MAIN_PAGE_URL,
  }
});