const mongoose = require("mongoose");
const NodeCache = require("node-cache");

if (!process.env.DB_URL) {
  console.error("No DB_URL environment variable supplied!");
  process.exit(1);
}

mongoose
  .connect(process.env.DB_URL, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .catch((err) => {
    console.log("Mongoose Error: ", err);
    process.exit(1);
  });

const SourceSchema = new mongoose.Schema(
  {
    _id: mongoose.Schema.Types.ObjectId,
    name: String,
    url: String,
  },
  { collection: "source" }
);

const ProductSchema = new mongoose.Schema(
  {
    _id: mongoose.Schema.Types.ObjectId,
    name: String,
    price: Number,
    quantity: Number,
    stars: Number,
    url: String,
    url_img: String,
    item_id: String,
    first_seen: Number,
    source: { type: mongoose.Schema.Types.ObjectId, ref: "source" },
  },
  { collection: "product" }
);

const WishlistSchema = new mongoose.Schema(
  {
    _id: mongoose.Schema.Types.ObjectId,
    timestamp: Number,
    value: Number,
    products: [{ type: mongoose.Schema.Types.ObjectId, ref: "product" }],
  },
  { collection: "wishlist" }
);

const Source = mongoose.model("source", SourceSchema);
const Product = mongoose.model("product", ProductSchema);
const Wishlist = mongoose.model("wishlist", WishlistSchema);

mongoose.connection.on("error", (err) => {
  console.error("Mongoose Error:", err);
  process.exit(1);
});

var cache = new NodeCache({ stdTTL: 60 });

function cached_request(name, on_hit_callback, fallback) {
  var cached_value = cache.get(name);
  if (cached_value) {
    console.log("Cache hit for '" + name + "'");
    on_hit_callback(cached_value);
  } else {
    console.log("Cache miss for '" + name + "'");
    fallback();
  }
}

module.exports.get_last_wishlist = (callback) => {
  cached_request("last_wishlist", callback, () => {
    Wishlist.find(null, "-_id")
      .sort({ timestamp: "desc" })
      .limit(1)
      .populate({
        path: "products",
        select: "-_id",
        populate: { path: "source", select: "-_id" },
      })
      .exec((err, res) => {
        if (err) {
          console.error(err);
          callback({ message: "Could not retrieve last wishlist" });
        } else {
          cache.set("last_wishlist", res[0]);
          callback(res[0]);
        }
      });
  });
};

module.exports.get_newest_products = (callback) => {
  cached_request("newest_products", callback, () => {
    Product.find(null, "-_id")
      .sort({ first_seen: "desc" })
      .limit(5)
      .populate({ path: "source", select: "-_id" })
      .exec((err, res) => {
        if (err) {
          console.error(err);
          callback({ message: "Could not retrieve newest products" });
        } else {
          cache.set("newest_products", res);
          callback(res);
        }
      });
  });
};

module.exports.get_archive_size = (callback) => {
  cached_request("archive_size", callback, () => {
    Wishlist.find(null)
      .sort({ timestamp: "desc" })
      .limit(1)
      .populate({ path: "products", select: "_id" })
      .exec((err, res) => {
        var active_products = [];
        if (res && res[0]) {
          active_products = res[0].products;
        }
        Product.find({ _id: { $nin: active_products } }, "-_id")
          .sort({ first_seen: "desc" })
          .count()
          .exec((err, res) => {
            if (err) {
              console.error(err);
              callback({ message: "Could not retrieve archive size" });
            } else {
              callback({ size: res });
            }
          });
      });
  });
};

module.exports.get_archived_products = (page, items_per_page, callback) => {
  cached_request(
    "product_archive_" + page.toString() + "_" + page.items_per_page.toString(),
    callback,
    () => {
      Wishlist.find(null)
        .sort({ timestamp: "desc" })
        .limit(1)
        .populate({ path: "products", select: "_id" })
        .exec((err, res) => {
          var active_products = [];
          if (res && res[0]) {
            active_products = res[0].products;
          }
          Product.find({ _id: { $nin: active_products } }, "-_id")
            .sort({ first_seen: "desc" })
            .skip((page - 1) * items_per_page)
            .limit(items_per_page)
            .populate({ path: "source", select: "-_id" })
            .exec((err, res) => {
              if (err) {
                console.error(err);
                callback({ message: "Could not retrieve archived products" });
              } else {
                callback(res);
              }
            });
        });
    }
  );
};
