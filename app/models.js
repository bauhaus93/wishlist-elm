const mongoose = require("mongoose");

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

module.exports.get_last_wishlist = async () => {
  return (
    await Wishlist.find(null, "-_id")
      .sort({ timestamp: "desc" })
      .limit(1)
      .populate({
        path: "products",
        select: "-_id -item_id",
        populate: { path: "source", select: "-_id" },
      })
  )[0];
};

module.exports.get_newest_products = async () => {
  return await Product.find(null, "-_id")
    .sort({ first_seen: "desc" })
    .limit(10)
    .populate({ path: "source", select: "-_id" });
};

module.exports.get_archive_size = async () => {
  var last_wishlist_result = await Wishlist.find(null, { products: true })
    .sort({ timestamp: "desc" })
    .limit(1)
    .populate({ path: "products", select: "_id" });
  return await Product.find({
    _id: { $nin: last_wishlist_result[0].products },
  }).countDocuments();
};

module.exports.get_archived_products = async (page, items_per_page) => {
  var last_wishlist_result = (
    await Wishlist.find(null)
      .sort({ timestamp: "desc" })
      .limit(1)
      .populate({ path: "products", select: "_id" })
  )[0];

  return await Product.find(
    { _id: { $nin: last_wishlist_result.products } },
    "-_id"
  )
    .sort({ last_seen: "desc" })
    .skip((page - 1) * items_per_page)
    .limit(items_per_page)
    .populate({ path: "source", select: "-_id" });
};

module.exports.get_timeline_datapoints = async (from_timestamp, count) => {
  const now_timestamp = Math.floor(Date.now() / 1000 / 3600) * 3600;
  const bucket_size = Math.ceil((now_timestamp - from_timestamp) / count);
  const boundaries = [...Array(count).keys()].map((i) => {
    return from_timestamp + bucket_size * i;
  });
  const datapoints = await Wishlist.aggregate([
    {
      $match: {
        timestamp: { $gte: from_timestamp, $lte: now_timestamp },
      },
    },
    {
      $lookup: {
        from: "product",
        localField: "products",
        foreignField: "_id",
        as: "full_products",
      },
    },
    {
      $set: {
        value: {
          $reduce: {
            input: "$full_products",
            initialValue: 0,
            in: {
              $add: [
                "$$value",
                { $multiply: ["$$this.price", "$$this.quantity"] },
              ],
            },
          },
        },
      },
    },
    {
      $bucket: {
        groupBy: "$timestamp",
        boundaries: boundaries,
        default: boundaries[boundaries.length - 1],
        output: {
          value: { $avg: "$value" },
        },
      },
    },
    {
      $project: {
        slice: "$_id",
        value: { $floor: "$value" },
        _id: 0,
      },
    },
  ]);
  if (datapoints.length > 0) {
    datapoints.push({
      slice: now_timestamp,
      value: datapoints[datapoints.length - 1].value,
    });
  } else {
    const last = await Wishlist.find(
      { timestamp: { $lte: from_timestamp } },
      "-_id products"
    )
      .sort({ timestamp: "desc" })
      .limit(1)
      .populate({ path: "products", select: "price quantity -_id" });
    if (last && last.length > 0) {
      const sum = last[0].products.reduce(
        (acc, p) => acc + p.price * p.quantity,
        0
      );
      return [
        { slice: from_timestamp, value: sum },
        { slice: now_timestamp, value: sum },
      ];
    } else {
      return [];
    }
  }
  return datapoints;
};