// models/PaymentMethod.js
import mongoose from 'mongoose';

const PaymentMethodSchema = new mongoose.Schema(
  {
    methodName: {
      type: String,
      required: true,
      unique: true,
      enum: ['CCP', 'DZMobPay', 'Eldahabiya', 'cash_on_delivery'],
    },
    displayName: { type: String, required: true },
    instructions: { type: String, required: true },
    iconUrl: { type: String },
    isActive: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

PaymentMethodSchema.index({ isActive: 1, sortOrder: 1 });

PaymentMethodSchema.statics.seed = async function () {
  const defaults = [
    {
      methodName: 'CCP',
      displayName: 'CCP — Clé CCP',
      instructions: 'Transfer to CCP account 1234567 key 89. Send your receipt photo after ordering.',
      sortOrder: 1,
    },
    {
      methodName: 'DZMobPay',
      displayName: 'DZMobPay',
      instructions: 'Pay via the DZMobPay app using merchant ID: DELICIOUS01.',
      sortOrder: 2,
    },
    {
      methodName: 'Eldahabiya',
      displayName: 'Eldahabiya Gold Card',
      instructions: 'Enter your Eldahabiya card number at checkout.',
      sortOrder: 3,
    },
    {
      methodName: 'cash_on_delivery',
      displayName: 'Cash on Delivery',
      instructions: 'Pay in cash when your order arrives.',
      sortOrder: 4,
    },
  ];
  for (const pm of defaults) {
    await this.findOneAndUpdate({ methodName: pm.methodName }, pm, { upsert: true, new: true });
  }
  console.log('✅ PaymentMethods seeded');
};

const PaymentMethod = mongoose.model('PaymentMethod', PaymentMethodSchema);
export default PaymentMethod;