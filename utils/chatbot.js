export function getBotResponse(message, caseData) {
  const msg = message.toLowerCase();

  if (msg.includes("explain")) {
    return `This case is about: ${caseData.caseDescription}`;
  }

  if (msg.includes("what should i do")) {
    return "You may consult a lawyer or proceed with filing.";
  }

  if (msg.includes("draft")) {
    return "Ensure facts, parties, and relief are clearly written.";
  }

  return "Please provide more details.";
}
