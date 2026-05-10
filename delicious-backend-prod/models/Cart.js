// models/Cart.js
import mongoose from 'mongoose';

const CartItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: [true, 'productId is required'],
    },
    productName: { type: String, required: true },
    productImageUrl: { type: String, required: true },
    gradientColors: { type: [String], default: [] },
    variantId: { type: mongoose.Schema.Types.ObjectId, default: null },
    variantLabel: { type: String, default: null },
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
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

CartItemSchema.virtual('subtotal').get(function () {
  return +(this.unitPrice * this.quantity).toFixed(2);
});

const CartSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'userId is required'],
      unique: true,
    },
    items: {
      type: [CartItemSchema],
      default: [],
    },
    couponCode: { type: String, default: null },
    discountAmount: { type: Number, default: 0, min: 0 },
    deliveryAddress: {
      wilaya: { type: String },
      commune: { type: String },
      street: { type: String },
      apartment: { type: String },
      phone: { type: String },
    },
    updatedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

CartSchema.virtual('itemCount').get(function () {
  return this.items.reduce((sum, item) => sum + item.quantity, 0);
});

CartSchema.virtual('subtotal').get(function () {
  return +this.items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0).toFixed(2);
});

CartSchema.virtual('totalPrice').get(function () {
  return +(this.subtotal - this.discountAmount).toFixed(2);
});

CartSchema.index({ userId: 1 });
CartSchema.index({ updatedAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 30 });

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
  this.items = [];
  this.couponCode = null;
  this.discountAmount = 0;
  this.updatedAt = new Date();
};

const Cart = mongoose.model('Cart', CartSchema);
export default Cart;