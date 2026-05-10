// models/Product.js
import mongoose from 'mongoose';

const MOOD_TAGS = ['hot', 'cold', 'sweet', 'salty', 'spicy', 'fresh', 'energising', 'comforting'];

const NutritionSchema = new mongoose.Schema(
  {
    calories: { type: Number },
    protein: { type: Number },
    carbs: { type: Number },
    fat: { type: Number },
    sugar: { type: Number },
    servingSize: { type: String },
  },
  { _id: false }
);

const VariantSchema = new mongoose.Schema(
  {
    label: { type: String, required: true },
    price: { type: Number, required: true },
    stock: { type: Number, default: 0 },
  },
  { _id: true }
);

const ProductSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
      maxlength: [120, 'Name cannot exceed 120 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [800, 'Description cannot exceed 800 characters'],
    },
    brand: { type: String, trim: true },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [0, 'Price cannot be negative'],
    },
    discountPercent: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Category is required'],
    },
    gradientColors: {
      type: [String],
      required: [true, 'gradientColors is required'],
      validate: {
        validator: (v) => v.length === 2 && v.every(c => /^#[0-9A-Fa-f]{6}$/.test(c)),
        message: 'gradientColors must be exactly 2 valid hex colour strings',
      },
    },
    mood: {
      type: [String],
      enum: {
        values: MOOD_TAGS,
        message: `Mood must be one of: ${MOOD_TAGS.join(', ')}`,
      },
      default: [],
    },
    imageUrl: {
      type: String,
      required: [true, 'Product image is required'],
    },
    thumbnailUrl: { type: String },
    imageGallery: { type: [String], default: [] },
    variants: { type: [VariantSchema], default: [] },
    nutrition: { type: NutritionSchema },
    isAvailable: { type: Boolean, default: true },
    stock: {
      type: Number,
      default: 0,
      min: [0, 'Stock cannot be negative'],
    },
    preparationTimeMin: {
      type: Number,
      default: 10,
    },
    isFeatured: { type: Boolean, default: false },
    rating: {
      average: { type: Number, default: 0, min: 0, max: 5 },
      count: { type: Number, default: 0 },
    },
    tags: { type: [String], default: [] },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

ProductSchema.virtual('finalPrice').get(function () {
  return +(this.price * (1 - this.discountPercent / 100)).toFixed(2);
});

ProductSchema.virtual('hasDiscount').get(function () {
  return this.discountPercent > 0;
});

ProductSchema.index({ categoryId: 1 });
ProductSchema.index({ mood: 1 });
ProductSchema.index({ isAvailable: 1 });
ProductSchema.index({ isFeatured: 1 });
ProductSchema.index({ name: 'text', description: 'text', brand: 'text', tags: 'text' });

const Product = mongoose.model('Product', ProductSchema);
export default Product;