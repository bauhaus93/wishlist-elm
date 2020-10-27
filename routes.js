const { get_last_wishlist, get_newest_products } = require("./service");

function success_handler(json_result, response) {
  response.set("Content-Type", "application/json");
  response.send(JSON.stringify(json_result));
  response.end();
}

module.exports = (app) => {
  app.get("/api/wishlist/last", (req, res) => {
    get_last_wishlist((wl) => {
      success_handler(wl, res);
    });
  });

  app.get("/api/product/newest", (req, res) => {
    get_newest_products((prods) => {
      success_handler(prods, res);
    });
  });
};
