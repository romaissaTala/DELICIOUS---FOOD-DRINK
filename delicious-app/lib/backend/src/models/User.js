const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// ── Embedded sub-schemas ──────────────────────────────────────────────────────

const AddressSchema = new mongoose.Schema(
  {
    label: { type: String, default: 'Home' },
    wilaya: { type: String, required: true },
    commune: { type: String, required: true },
    street: { type: String, required: true },
    apartment: { type: String },
    phone: { type: String, required: true },
    isDefault: { type: Boolean, default: false },
  },
  { _id: true }
);

// ── Main schema ───────────────────────────────────────────────────────────────

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      maxlength: [80, 'Name cannot exceed 80 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    passwordHash: {
      type: String,
      required: function () {
        return !this.isGuest;
      },
      select: false,
    },
    faceVector: {
      type: [Number],
      default: undefined,
      validate: {
        validator: (v) => !v || v.length === 128,
        message: 'faceVector must be exactly 128 numbers',
      },
      select: false,
    },
    hasFaceAuth: { type: Boolean, default: false },
    role: {
      type: String,
      enum: ['customer', 'admin'],
      default: 'customer',
    },
    isGuest: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    phone: {
      type: String,
      match: [/^0[567]\d{8}$/, 'Enter a valid Algerian phone number'],
    },
    avatarUrl: { type: String },
    savedAddresses: { type: [AddressSchema], default: [] },
    refreshToken: { type: String, select: false },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
UserSchema.index({ email: 1 });
UserSchema.index({ isGuest: 1 });

// ── Hooks ─────────────────────────────────────────────────────────────────────

// SOLUTION 1: Use async/await with bcryptjs (RECOMMENDED)
UserSchema.pre('save', async function(next) {
  try {
    // Only hash if password is modified
    if (!this.isModified('passwordHash')) {
      return next();
    }
    
    // Generate salt and hash using bcryptjs (which supports promises)
    const salt = await bcrypt.genSalt(10);
    this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// ── Instance methods ──────────────────────────────────────────────────────────

UserSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.passwordHash);
};

UserSchema.methods.compareFaceVector = function(inputVector) {
  if (!this.faceVector || this.faceVector.length !== 128) return 0;
  const dot = this.faceVector.reduce((sum, v, i) => sum + v * inputVector[i], 0);
  const magA = Math.sqrt(this.faceVector.reduce((s, v) => s + v * v, 0));
  const magB = Math.sqrt(inputVector.reduce((s, v) => s + v * v, 0));
  return dot / (magA * magB);
};

module.exports = mongoose.model('User', UserSchema);