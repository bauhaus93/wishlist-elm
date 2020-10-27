const models = require("./models");

module.exports.get_last_wishlist = (callback) => {
  models.get_last_wishlist(callback);
};

module.exports.get_newest_products = (callback) => {
  models.get_newest_products(callback);
};
