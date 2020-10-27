require("dotenv").config();
const compression = require("compression");
const express = require("express");
const path = require("path");
const { get_last_wishlist } = require("./models");

const port = process.env.PORT;
const app = express();

app.use(compression());
app.use((req, res, next) => {
  const now = new Date();
  console.log(`${req.method} ${req.url}`);
  next();
});

app.use(express.static(path.join(__dirname, "public")));
const routes = require(path.join(__dirname, "routes"));
routes(app);

app.listen(port, () => {
  console.log(`Server running @ http://localhost:${port}`);
});
