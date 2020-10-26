const models = require("./models");

module.exports.get_last_wishlist = (callback) => {
  console.log("Getting last wishlist");
  models.get_last_wishlist(callback);
};
