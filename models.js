const mongoose = require("mongoose");

mongoose.connect(process.env.DB_URL, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
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

mongoose.connection;

module.exports.get_last_wishlist = (callback) => {
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
        callback(res[0]);
      }
    });
};
