const { get_last_wishlist } = require("./service");

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
};
