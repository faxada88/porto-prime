/** Presentation only. Never changes the API error or the operation that raised it. */
export function displayMessage(value: unknown): string {
  const raw = String(value ?? "").trim();
  if (/SocketException|ClientException|failed to fetch|NetworkError|connection refused/i.test(raw)) {
    return "Não conseguimos conectar agora. Verifique sua conexão e tente novamente.";
  }
  if (/timeout|timed out/i.test(raw)) {
    return "A resposta demorou mais que o esperado. Tente novamente.";
  }
  if (/\b50\d\b/.test(raw)) {
    return "O serviço está temporariamente indisponível. Tente novamente em instantes.";
  }
  if (!raw || /^(null|undefined)$|TypeError|<html|<!doctype/i.test(raw)) {
    return "Não foi possível concluir esta ação agora. Tente novamente.";
  }
  return raw.replace(/^\w*Exception:\s*/, "");
}
