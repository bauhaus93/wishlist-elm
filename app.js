require("dotenv").config();
const compression = require("compression");
const express = require("express");

const { get_last_wishlist } = require("./models");

const app = express();
const port = 8080;

const routes = require("./routes");
routes(app);

app.use(compression());
app.use(express.static("www"));

app.listen(port, () => {
  console.log(`Server running @ http://localhost:${port}`);
});
