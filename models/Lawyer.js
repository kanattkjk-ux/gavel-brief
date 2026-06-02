import mongoose from "mongoose";

/**
 * Lawyers are stored in the same `users` collection as other accounts (role: "lawyer").
 * strict: false preserves existing user fields (bio, availability, etc.).
 */
const lawyerSchema = new mongoose.Schema(
  {
    name: String,
    email: String,
    password_hash: String,
    role: String,
    specialization: String,
    location: String,
    rating: Number,
    firmId: { type: mongoose.Schema.Types.ObjectId, ref: "Firm", default: null },
  },
  { collection: "users", strict: false },
);

export default mongoose.models.Lawyer || mongoose.model("Lawyer", lawyerSchema);
const testVariable = 10;
// `@coderabbitai` how can I improve this schema?
