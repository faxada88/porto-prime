export default function RequirementAnswer({ value }: { value: string }) {
  let text = value;
  let photo: string | undefined;
  try {
    const parsed = JSON.parse(value);
    if (typeof parsed?.text === 'string') text = parsed.text;
    if (typeof parsed?.documentPhoto === 'string' && /^data:image\/(jpeg|png);base64,[A-Za-z0-9+/]+=*$/.test(parsed.documentPhoto)) photo = parsed.documentPhoto;
  } catch { /* Existing plain-text answers remain readable. */ }
  return <div style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere' }}>
    <p>{text}</p>
    {photo && <details><summary>Visualizar documento enviado</summary>
      {/* A private inline image; never sent to an external image optimizer. */}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={photo} alt="Documento enviado pelo motoboy para análise" style={{ maxWidth: '100%', height: 'auto', borderRadius: 12 }} />
      <a href={photo} download="documento-motoboy">Baixar documento</a>
    </details>}
  </div>;
}
