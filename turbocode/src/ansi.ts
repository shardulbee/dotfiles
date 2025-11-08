export function stripAnsi(text: string): string {
  return text.replace(/\u001b\[[0-9;]*[a-zA-Z]/g, '').replace(/\u001b\][^\u0007]*\u0007/g, '');
}

export interface DecorationRange {
  start: number;
  end: number;
  fg?: string;
  bright?: boolean;
  bold?: boolean;
}

function mapBasicColors(code: number): { color: string; bright: boolean } | null {
  const colors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'];
  if (code >= 0 && code <= 7) return { color: colors[code], bright: false };
  if (code >= 8 && code <= 15) {
    if (code === 8) return { color: 'white', bright: false }; // jj uses 8 as grey, not bright black
    return { color: colors[code - 8], bright: true };
  }
  return null;
}

export function parseAnsiLine(line: string): { text: string; decorations: DecorationRange[] } {
  const decorations: DecorationRange[] = [];
  let text = '';
  let fg: string | undefined;
  let bright = false;
  let bold = false;
  let start = 0;
  
  const colors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'];
  
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '\u001b' && line[i + 1] === '[') {
      const end = line.indexOf('m', i);
      if (end === -1) continue;
      const codes = line.slice(i + 2, end).split(';').map(Number);
      
      if (start < text.length && (fg || bold)) {
        decorations.push({ start, end: text.length, fg, bright, bold });
      }
      
      start = text.length;
      fg = undefined;
      bright = false;
      bold = false;
      
      for (let j = 0; j < codes.length; j++) {
        const code = codes[j];
        if (code === 0) { fg = undefined; bright = false; bold = false; }
        else if (code === 1) bold = true;
        else if (code === 38 && codes[j + 1] === 5 && codes[j + 2] !== undefined) {
          const mapped = mapBasicColors(codes[j + 2]);
          if (mapped) { fg = mapped.color; bright = mapped.bright; }
          j += 2;
        }
        else if (code === 39) { fg = undefined; bright = false; }
        else if (code >= 30 && code <= 37) { fg = colors[code - 30]; bright = false; }
        else if (code >= 90 && code <= 97) { fg = colors[code - 90]; bright = true; }
      }
      
      i = end;
    } else {
      text += line[i];
    }
  }
  
  if (start < text.length && (fg || bold)) {
    decorations.push({ start, end: text.length, fg, bright, bold });
  }
  
  return { text, decorations };
}

