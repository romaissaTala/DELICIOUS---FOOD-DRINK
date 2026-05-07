// src/models/Category.js
const mongoose = require('mongoose');

// ── Category types available in the app ──────────────────────────────────────
const CATEGORY_TYPES = ['food', 'juice', 'coffee', 'sweets'];

const CategorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Category name is required'],
      trim: true,
      unique: true,
      maxlength: [60, 'Name cannot exceed 60 characters'],
    },

    // High-level type used for tab grouping in the UI
    type: {
      type: String,
      required: [true, 'Category type is required'],
      enum: {
        values: CATEGORY_TYPES,
        message: `Type must be one of: ${CATEGORY_TYPES.join(', ')}`,
      },
    },

    // Icon identifier (maps to a local Flutter asset or an icon font key)
    icon: {
      type: String,
      required: [true, 'Icon is required'],
      // e.g. "burger", "juice_glass", "coffee_cup", "cake"
    },

    // Controls display order in the categories rail
    sortOrder: {
      type: Number,
      default: 0,
    },

    // Soft-delete / hide without removing from DB
    isActive: {
      type: Boolean,
      default: true,
    },

    // Optional gradient for the category card in the UI
    gradientColors: {
      type: [String],
      default: ['#FF6B35', '#FF8C61'],
      validate: {
        validator: (v) => v.length === 2,
        message: 'gradientColors must contain exactly 2 hex colour strings',
      },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
CategorySchema.index({ type: 1, sortOrder: 1 });
CategorySchema.index({ isActive: 1 });

// ── Seed data helper ──────────────────────────────────────────────────────────
// Call Category.seed() in your DB seeder script.
CategorySchema.statics.seed = async function () {
  const defaults = [
    { name: 'Fast Food',           type: 'food',    icon: 'burger',       sortOrder: 1, gradientColors: ['#FF6B35', '#FF8C61'] },
    { name: 'Traditional Algerian',type: 'food',    icon: 'couscous',     sortOrder: 2, gradientColors: ['#C69B4A', '#E8C07A'] },
    { name: 'Foreign Cuisine',     type: 'food',    icon: 'fork_knife',   sortOrder: 3, gradientColors: ['#E84855', '#FF6B74'] },
    { name: 'Natural Juices',      type: 'juice',   icon: 'juice_glass',  sortOrder: 4, gradientColors: ['#FF9A00', '#FFC642'] },
    { name: 'Sodas',               type: 'juice',   icon: 'soda_can',     sortOrder: 5, gradientColors: ['#E63946', '#FF6B6B'] },
    { name: 'Coffee',              type: 'coffee',  icon: 'coffee_cup',   sortOrder: 6, gradientColors: ['#4A2C2A', '#8B5E52'] },
    { name: 'Sweets',              type: 'sweets',  icon: 'cake',         sortOrder: 7, gradientColors: ['#E91E8C', '#FF6BB5'] },
  ];
  for (const cat of defaults) {
    await this.findOneAndUpdate({ name: cat.name }, cat, { upsert: true, new: true });
  }
  console.log('✅ Categories seeded');
};

module.exports = mongoose.model('Category', CategorySchema);