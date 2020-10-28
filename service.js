const models = require("./models");

module.exports.get_last_wishlist = (callback) => {
  models.get_last_wishlist(callback);
};

module.exports.get_newest_products = (callback) => {
  models.get_newest_products(callback);
};

module.exports.get_archived_products = (page, items_per_page, callback) => {
  if (page == null || page <= 0) {
    page = 1;
  }
  if (items_per_page == null || items_per_page <= 0) {
    items_per_page = 5;
  }
  models.get_archived_products(page, items_per_page, callback);
};
