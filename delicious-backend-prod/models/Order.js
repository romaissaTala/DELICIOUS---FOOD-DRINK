// models/Order.js
import mongoose from 'mongoose';

const ORDER_STATUSES = ['placed', 'confirmed', 'preparing', 'on_the_way', 'delivered', 'cancelled'];
const PAYMENT_METHODS = ['CCP', 'DZMobPay', 'Eldahabiya', 'cash_on_delivery'];

const OrderItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
    },
    productName: { type: String, required: true },
    productImageUrl: { type: String, required: true },
    gradientColors: { type: [String], default: [] },
    variantId: { type: mongoose.Schema.Types.ObjectId, default: null },
    variantLabel: { type: String, default: null },
    unitPrice: {
      type: Number,
      required: true,
      min: 0,
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
    },
  },
  {
    _id: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

OrderItemSchema.virtual('subtotal').get(function () {
  return +(this.unitPrice * this.quantity).toFixed(2);
});

const DeliveryAddressSchema = new mongoose.Schema(
  {
    wilaya: { type: String, required: true },
    commune: { type: String, required: true },
    street: { type: String, required: true },
    apartment: { type: String },
    phone: { type: String, required: true },
    label: { type: String, default: 'Home' },
  },
  { _id: false }
);

const StatusEventSchema = new mongoose.Schema(
  {
    status: { type: String, enum: ORDER_STATUSES, required: true },
    timestamp: { type: Date, default: Date.now },
    note: { type: String },
  },
  { _id: false }
);

const PaymentInfoSchema = new mongoose.Schema(
  {
    method: {
      type: String,
      enum: {
        values: PAYMENT_METHODS,
        message: `Payment method must be one of: ${PAYMENT_METHODS.join(', ')}`,
      },
      required: true,
    },
    transactionId: { type: String, default: null },
    paidAt: { type: Date, default: null },
    isPaid: { type: Boolean, default: false },
  },
  { _id: false }
);

const OrderSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'userId is required'],
    },
    orderNumber: {
      type: String,
      unique: true,
    },
    items: {
      type: [OrderItemSchema],
      required: true,
      validate: {
        validator: (v) => v.length > 0,
        message: 'Order must have at least one item',
      },
    },
    subtotal: { type: Number, required: true, min: 0 },
    discountAmount: { type: Number, default: 0, min: 0 },
    deliveryFee: { type: Number, default: 0, min: 0 },
    total: {
      type: Number,
      required: true,
      min: 0,
    },
    couponCode: { type: String, default: null },
    payment: { type: PaymentInfoSchema, required: true },
    status: {
      type: String,
      enum: ORDER_STATUSES,
      default: 'placed',
    },
    statusHistory: {
      type: [StatusEventSchema],
      default: [],
    },
    deliveryAddress: { type: DeliveryAddressSchema, required: true },
    estimatedDeliveryMin: { type: Number, default: 30 },
    deliveredAt: { type: Date, default: null },
    customerNote: { type: String, maxlength: 300 },
    adminNote: { type: String, select: false },
    cancelledAt: { type: Date, default: null },
    cancellationReason: { type: String, default: null },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

OrderSchema.virtual('itemCount').get(function () {
  return this.items.reduce((sum, i) => sum + i.quantity, 0);
});

OrderSchema.virtual('isCancellable').get(function () {
  return ['placed', 'confirmed'].includes(this.status);
});

OrderSchema.virtual('progressPercent').get(function () {
  const steps = { placed: 10, confirmed: 30, preparing: 55, on_the_way: 80, delivered: 100, cancelled: 0 };
  return steps[this.status] ?? 0;
});

OrderSchema.pre('save', async function (next) {
  if (this.isNew) {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const count = await mongoose.model('Order').countDocuments() + 1;
    this.orderNumber = `DLX-${today}-${String(count).padStart(4, '0')}`;
    this.statusHistory.push({ status: 'placed', timestamp: new Date() });
  }
  next();
});

OrderSchema.methods.advanceStatus = function (newStatus, note = '') {
  const validTransitions = {
    placed: ['confirmed', 'cancelled'],
    confirmed: ['preparing', 'cancelled'],
    preparing: ['on_the_way'],
    on_the_way: ['delivered'],
    delivered: [],
    cancelled: [],
  };
  if (!validTransitions[this.status]?.includes(newStatus)) {
    throw new Error(`Cannot transition from "${this.status}" to "${newStatus}"`);
  }
  this.status = newStatus;
  this.statusHistory.push({ status: newStatus, timestamp: new Date(), note });
  if (newStatus === 'delivered') this.deliveredAt = new Date();
  if (newStatus === 'cancelled') this.cancelledAt = new Date();
};

OrderSchema.index({ userId: 1, createdAt: -1 });
OrderSchema.index({ status: 1 });
OrderSchema.index({ orderNumber: 1 }, { unique: true });

const Order = mongoose.model('Order', OrderSchema);
export default Order;