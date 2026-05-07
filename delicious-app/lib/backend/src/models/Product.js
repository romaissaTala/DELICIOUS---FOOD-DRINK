// src/models/Product.js
const mongoose = require('mongoose');

// ── Mood tags — drive the "mood-based ordering" feature ───────────────────────
const MOOD_TAGS = ['hot', 'cold', 'sweet', 'salty', 'spicy', 'fresh', 'energising', 'comforting'];

// ── Embedded: nutritional info (optional, shown on product detail page) ───────
const NutritionSchema = new mongoose.Schema(
  {
    calories:     { type: Number },
    protein:      { type: Number },  // grams
    carbs:        { type: Number },  // grams
    fat:          { type: Number },  // grams
    sugar:        { type: Number },  // grams
    servingSize:  { type: String },  // e.g. "330ml", "250g"
  },
  { _id: false }
);

// ── Embedded: product variant (size / flavour) ────────────────────────────────
const VariantSchema = new mongoose.Schema(
  {
    label:  { type: String, required: true },  // "Small", "Medium", "Large"
    price:  { type: Number, required: true },  // DZD
    stock:  { type: Number, default: 0 },
  },
  { _id: true }
);

// ── Main schema ───────────────────────────────────────────────────────────────

const ProductSchema = new mongoose.Schema(
  {
    // ── Core identity ─────────────────────────────────────────────────────────
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
    brand: {
      type: String,
      trim: true,
      // e.g. "Coca-Cola", "Pepsi", "Ifri", null for homemade dishes
    },

    // ── Pricing ───────────────────────────────────────────────────────────────
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
    // Virtual: finalPrice = price * (1 - discountPercent/100)

    // ── Categorisation ────────────────────────────────────────────────────────
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Category is required'],
    },

    // ── UI / theming ──────────────────────────────────────────────────────────
    // The two gradient stop colours shown in the product carousel and background.
    // e.g. Coca-Cola: ["#CC0000","#FF4444"], Pepsi: ["#004B93","#0070CC"]
    gradientColors: {
      type: [String],
      required: [true, 'gradientColors is required'],
      validate: {
        validator: (v) => v.length === 2 && v.every(c => /^#[0-9A-Fa-f]{6}$/.test(c)),
        message: 'gradientColors must be exactly 2 valid hex colour strings, e.g. ["#FF0000","#FF8888"]',
      },
    },

    // ── Mood system ───────────────────────────────────────────────────────────
    // Tags that power "I want something cold/sweet/hot" filtering.
    mood: {
      type: [String],
      enum: {
        values: MOOD_TAGS,
        message: `Mood must be one of: ${MOOD_TAGS.join(', ')}`,
      },
      default: [],
    },

    // ── Media ─────────────────────────────────────────────────────────────────
    imageUrl: {
      type: String,
      required: [true, 'Product image is required'],
    },
    thumbnailUrl: { type: String },  // smaller version for carousel
    imageGallery: { type: [String], default: [] },

    // ── Variants (size / flavour options) ────────────────────────────────────
    variants: { type: [VariantSchema], default: [] },

    // ── Nutrition ─────────────────────────────────────────────────────────────
    nutrition: { type: NutritionSchema },

    // ── Availability & stock ──────────────────────────────────────────────────
    isAvailable: { type: Boolean, default: true },
    stock: {
      type: Number,
      default: 0,
      min: [0, 'Stock cannot be negative'],
    },
    preparationTimeMin: {
      type: Number,
      default: 10,  // minutes
    },

    // ── Metadata ──────────────────────────────────────────────────────────────
    isFeatured: { type: Boolean, default: false },
    rating: {
      average: { type: Number, default: 0, min: 0, max: 5 },
      count:   { type: Number, default: 0 },
    },
    tags: { type: [String], default: [] }, // free-form search tags
  },
  {
    timestamps: true,
    toJSON:   { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ── Virtuals ──────────────────────────────────────────────────────────────────

ProductSchema.virtual('finalPrice').get(function () {
  return +(this.price * (1 - this.discountPercent / 100)).toFixed(2);
});

ProductSchema.virtual('hasDiscount').get(function () {
  return this.discountPercent > 0;
});

// ── Indexes ───────────────────────────────────────────────────────────────────
ProductSchema.index({ categoryId: 1 });
ProductSchema.index({ mood: 1 });
ProductSchema.index({ isAvailable: 1 });
ProductSchema.index({ isFeatured: 1 });
ProductSchema.index({ name: 'text', description: 'text', brand: 'text', tags: 'text' }); // full-text search

module.exports = mongoose.model('Product', ProductSchema);