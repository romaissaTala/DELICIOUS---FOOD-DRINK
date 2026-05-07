// src/models/Cart.js
//
// Strategy:
//   • Logged-in users  → cart stored here in MongoDB (synced across devices)
//   • Guest users      → cart stored in Hive on the device only; never hits this collection
//
const mongoose = require('mongoose');

// ── Embedded: a single line in the cart ──────────────────────────────────────

const CartItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: [true, 'productId is required'],
    },
    // Snapshot of product fields at time of adding — avoids a JOIN on every cart fetch
    // and protects the cart total if the product price changes mid-session.
    productName:      { type: String, required: true },
    productImageUrl:  { type: String, required: true },
    gradientColors:   { type: [String], default: [] }, // for mini cart UI theming
    variantId:        { type: mongoose.Schema.Types.ObjectId, default: null },
    variantLabel:     { type: String, default: null },  // e.g. "Large"
    unitPrice: {
      type: Number,
      required: [true, 'unitPrice is required'],
      min: [0, 'unitPrice cannot be negative'],
    },
    quantity: {
      type: Number,
      required: true,
      min: [1, 'Quantity must be at least 1'],
      max: [50, 'Quantity cannot exceed 50'],
      default: 1,
    },
  },
  {
    _id: true,
    toJSON:   { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtual: subtotal for this line item
CartItemSchema.virtual('subtotal').get(function () {
  return +(this.unitPrice * this.quantity).toFixed(2);
});

// ── Main schema ───────────────────────────────────────────────────────────────

const CartSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'userId is required'],
      unique: true, // one cart document per user at all times
    },

    items: {
      type: [CartItemSchema],
      default: [],
    },

    // Coupon / promo code applied to this cart
    couponCode:      { type: String, default: null },
    discountAmount:  { type: Number, default: 0, min: 0 },

    // Delivery details captured before checkout
    deliveryAddress: {
      wilaya:    { type: String },
      commune:   { type: String },
      street:    { type: String },
      apartment: { type: String },
      phone:     { type: String },
    },

    // TTL: auto-expire abandoned carts after 30 days of no activity
    updatedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
    toJSON:   { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ── Virtuals ──────────────────────────────────────────────────────────────────

CartSchema.virtual('itemCount').get(function () {
  return this.items.reduce((sum, item) => sum + item.quantity, 0);
});

CartSchema.virtual('subtotal').get(function () {
  return +this.items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0).toFixed(2);
});

CartSchema.virtual('totalPrice').get(function () {
  return +(this.subtotal - this.discountAmount).toFixed(2);
});

// ── Indexes ───────────────────────────────────────────────────────────────────
CartSchema.index({ userId: 1 });
// TTL index — auto-delete documents 30 days after last update
CartSchema.index({ updatedAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 30 });

// ── Instance methods ──────────────────────────────────────────────────────────

// Add or increment item. Pass productId + variantId to match the right line.
CartSchema.methods.upsertItem = function (itemData) {
  const idx = this.items.findIndex(
    (i) =>
      i.productId.toString() === itemData.productId.toString() &&
      String(i.variantId) === String(itemData.variantId ?? null)
  );
  if (idx > -1) {
    this.items[idx].quantity = Math.min(50, this.items[idx].quantity + (itemData.quantity ?? 1));
  } else {
    this.items.push(itemData);
  }
  this.updatedAt = new Date();
};

CartSchema.methods.removeItem = function (cartItemId) {
  this.items = this.items.filter((i) => i._id.toString() !== cartItemId.toString());
  this.updatedAt = new Date();
};

CartSchema.methods.updateQuantity = function (cartItemId, quantity) {
  const item = this.items.id(cartItemId);
  if (!item) throw new Error('Cart item not found');
  if (quantity < 1) return this.removeItem(cartItemId);
  item.quantity = Math.min(50, quantity);
  this.updatedAt = new Date();
};

CartSchema.methods.clear = function () {
  this.items          = [];
  this.couponCode     = null;
  this.discountAmount = 0;
  this.updatedAt      = new Date();
};

module.exports = mongoose.model('Cart', CartSchema);