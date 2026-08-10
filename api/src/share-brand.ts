/** Official INTERNSAFE AI logo — served as PNG from worker static assets. */
export function internsafeLogoImg(host: string, sizePx = 48): string {
  const src = `https://${host}/brand/internsafe_ai_logo.png`;
  const s = Math.max(24, Math.min(256, sizePx));
  return `<img src="${src}" width="${s}" height="${s}" alt="INTERNSAFE AI" class="brand-logo" loading="eager" decoding="async" style="display:block;object-fit:contain;width:${s}px;height:${s}px;flex-shrink:0"/>`;
}
