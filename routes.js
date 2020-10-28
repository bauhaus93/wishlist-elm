const path = require("path");
const {
  get_last_wishlist,
  get_newest_products,
  get_archived_products,
} = require("./service");

function success_handler(json_result, response) {
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

  app.get("/api/product/archive", (req, res) => {
    var page = req.query.page;
    var items_per_page = req.query.items;
    get_archived_products(page, items_per_page, (prods, max_page) => {
      success_handler(prods, res);
    });
  });

  app.get("*", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "index.html"));
  });
};
