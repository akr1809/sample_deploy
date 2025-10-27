const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters long'],
    maxlength: [50, 'Name cannot exceed 50 characters']
  }
}, {
  timestamps: true // Automatically adds createdAt and updatedAt fields
});

// Add a method to get user info without sensitive data
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  return {
    _id: user._id,
    name: user.name,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };
};

const User = mongoose.model('User', userSchema);

module.exports = User;