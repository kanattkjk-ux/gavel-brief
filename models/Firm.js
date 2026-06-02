import mongoose from "mongoose";

const firmSchema = new mongoose.Schema({
  name: String,
  email: String,
  location: String,
});

export default mongoose.model("Firm", firmSchema);
