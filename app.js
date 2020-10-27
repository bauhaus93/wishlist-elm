require("dotenv").config();
const compression = require("compression");
const express = require("express");

const { get_last_wishlist } = require("./models");

const app = express();
const port = 8080;

app.use(compression());
app.use((req, res, next) => {
  const now = new Date();
  console.log(`${req.method} ${req.url}`);
  next();
});

app.use(express.static("public"));
const routes = require("./routes");
routes(app);

app.listen(port, () => {
  console.log(`Server running @ http://localhost:${port}`);
});
