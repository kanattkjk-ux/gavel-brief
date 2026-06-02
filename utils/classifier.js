export function classifyCase(text) {
  const lower = text.toLowerCase();

  let type = "Non-Criminal";
  let domain = "Non-Judicial";
  let category = "General";

  let flags = {
    requiresFIR: false,
    claimRejectedTwice: false,
    adrSuggested: false,
  };

  if (
    lower.includes("murder") ||
    lower.includes("theft") ||
    lower.includes("assault")
  ) {
    type = "Criminal";
    flags.requiresFIR = true;
  }

  if (lower.includes("court") || lower.includes("petition")) {
    domain = "Judicial";
  }

  if (lower.includes("rent") || lower.includes("eviction")) {
    category = "Tenant";
    flags.adrSuggested = true;
  }

  if (lower.includes("insurance") || lower.includes("claim")) {
    category = "Insurance";
  }

  return { type, domain, category, flags };
}
