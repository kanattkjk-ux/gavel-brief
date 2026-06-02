import mongoose from "mongoose";

const legalWriterSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true },
  earnings: { type: Number, default: 0 },
});

export default mongoose.model("LegalWriter", legalWriterSchema);
