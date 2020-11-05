const path = require("path");
const {
  get_last_wishlist,
  get_newest_products,
  get_archive_size,
  get_archived_products,
  get_timeline_datapoints,
} = require("./service");

function success_handler(json_result, response) {
  response.set("Content-Type", "application/json");
  response.send(JSON.stringify(json_result));
  response.end();
}

module.exports = (app) => {
  app.get("/api/wishlist/last", async (req, res) => {
    success_handler(await get_last_wishlist(), res);
  });

  app.get("/api/product/newest", async (req, res) => {
    success_handler(await get_newest_products(), res);
  });

  app.get("/api/product/archive", async (req, res) => {
    var page = req.query.page;
    var items_per_page = req.query.per_page;
    var total_items = await get_archive_size();
    res.set("X-Paging-TotalRecordCount", total_items.toString());
    success_handler(await get_archived_products(page, items_per_page), res);
  });

  app.get("/api/wishlist/values", async (req, res) => {
    var resolution = req.query.from_timestamp;
    var count = req.query.count;
    success_handler(await get_timeline_datapoints(resolution, count), res);
  });

  app.get("*", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "index.html"));
  });
};
