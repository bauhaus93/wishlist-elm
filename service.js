const models = require("./models");
const NodeCache = require("node-cache");

var cache = new NodeCache({ stdTTL: 60 });

async function cached_request(name, fallback) {
  var cached_value = cache.get(name);
  if (cached_value) {
    console.log("Cache hit for '" + name + "'");
    return cached_value;
  } else {
    console.log("Cache miss for '" + name + "'");
    var new_value = await fallback();
    cache.set(name, new_value);
    return new_value;
  }
}

module.exports.get_last_wishlist = async () => {
  return await cached_request("last_wishlist", models.get_last_wishlist);
};

module.exports.get_newest_products = async () => {
  return await cached_request("newest_products", models.get_newest_products);
};

module.exports.get_archive_size = async () => {
  return await cached_request("archive_size", models.get_archive_size);
};

module.exports.get_archived_products = async (
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
  return await cached_request(
    "product_archive_" + page.toString() + "_" + items_per_page.toString(),
    () => models.get_archived_products(page, items_per_page)
  );
};
