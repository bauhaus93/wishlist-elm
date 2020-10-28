const models = require("./models");

module.exports.get_last_wishlist = (callback) => {
  models.get_last_wishlist(callback);
};

module.exports.get_newest_products = (callback) => {
  models.get_newest_products(callback);
};

module.exports.get_archived_products = (
  page_str,
  items_per_page_str,
  callback
) => {
  var page = parseInt(page_str);
  if (isNaN(page) || page < 1) {
    page = 1;
  }
  var items_per_page = parseInt(items_per_page_str);
  if (isNaN(items_per_page) || items_per_page < 5) {
    items_per_page = 5;
  }
  models.get_archived_products(page, items_per_page, callback);
};
