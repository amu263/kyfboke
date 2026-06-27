/**
 * 图库数据加载
 * - 扫描 public/gallery/ 下所有图片
 * - 解析文件头提取宽高 (JPEG/PNG/WebP/GIF), 不依赖 sharp
 * - SSR 阶段运行一次, 结果内联到页面
 */
import { readdir, stat, open } from 'node:fs/promises';
import { join } from 'node:path';

export interface GalleryItem {
  src: string;
  width: number;
  height: number;
  bytes: number;
  name: string;
  mtimeMs: number;
}

const ALLOWED_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif']);

/**
 * 读取文件前 64KB 足够覆盖 JPEG/PNG/WebP 的尺寸元数据
 */
async function readDimensions(fullPath: string): Promise<{ width: number; height: number } | null> {
  let fh;
  try {
    fh = await open(fullPath, 'r');
    const buf = Buffer.alloc(65536);
    const { bytesRead } = await fh.read(buf, 0, 65536, 0);
    return parseDimensions(buf.subarray(0, bytesRead));
  } catch {
    return null;
  } finally {
    if (fh) await fh.close().catch(() => {});
  }
}

function parseDimensions(buf: Buffer): { width: number; height: number } | null {
  // PNG
  if (
    buf.length >= 24 &&
    buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47 &&
    buf[4] === 0x0d && buf[5] === 0x0a && buf[6] === 0x1a && buf[7] === 0x0a &&
    buf[12] === 0x49 && buf[13] === 0x48 && buf[14] === 0x44 && buf[15] === 0x52
  ) {
    const w = buf.readUInt32BE(16);
    const h = buf.readUInt32BE(20);
    return { width: w, height: h };
  }

  // GIF
  if (
    buf.length >= 10 &&
    buf[0] === 0x47 && buf[1] === 0x49 && buf[2] === 0x46 &&
    buf[3] === 0x38 && (buf[4] === 0x37 || buf[4] === 0x39) && buf[5] === 0x61
  ) {
    const w = buf.readUInt16LE(6);
    const h = buf.readUInt16LE(8);
    return { width: w, height: h };
  }

  // JPEG: 扫描 SOF markers
  if (buf.length >= 4 && buf[0] === 0xff && buf[1] === 0xd8) {
    let off = 2;
    while (off < buf.length - 9) {
      if (buf[off] !== 0xff) return null;
      while (off < buf.length && buf[off] === 0xff) off++;
      if (off >= buf.length) return null;
      const marker = buf[off];
      off++;
      if (
        marker >= 0xc0 && marker <= 0xcf &&
        marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc
      ) {
        if (off + 7 > buf.length) return null;
        const h = buf.readUInt16BE(off + 3);
        const w = buf.readUInt16BE(off + 5);
        return { width: w, height: h };
      }
      if (off + 2 > buf.length) return null;
      const segLen = buf.readUInt16BE(off);
      off += segLen;
    }
    return null;
  }

  // WebP
  if (
    buf.length >= 30 &&
    buf.toString('ascii', 0, 4) === 'RIFF' &&
    buf.toString('ascii', 8, 12) === 'WEBP'
  ) {
    const chunk = buf.toString('ascii', 12, 16);
    if (chunk === 'VP8 ') {
      const w = buf.readUInt16LE(26) & 0x3fff;
      const h = buf.readUInt16LE(28) & 0x3fff;
      return { width: w, height: h };
    }
    if (chunk === 'VP8L') {
      const b1 = buf.readUInt8(21);
      const b2 = buf.readUInt8(22);
      const b3 = buf.readUInt8(23);
      const b4 = buf.readUInt8(24);
      const w = 1 + (((b2 & 0x3f) << 8) | b1);
      const h = 1 + (((b4 & 0x0f) << 10) | (b3 << 2) | ((b2 & 0xc0) >> 6));
      return { width: w, height: h };
    }
    if (chunk === 'VP8X') {
      const w = 1 + (buf.readUInt8(24) | (buf.readUInt8(25) << 8) | (buf.readUInt8(26) << 16));
      const h = 1 + (buf.readUInt8(27) | (buf.readUInt8(28) << 8) | (buf.readUInt8(29) << 16));
      return { width: w, height: h };
    }
  }

  return null;
}

export async function loadGallery(publicDir: string): Promise<GalleryItem[]> {
  const galleryDir = join(publicDir, 'gallery');
  let entries: string[];
  try {
    entries = await readdir(galleryDir);
  } catch {
    return [];
  }

  const items: GalleryItem[] = [];
  for (const file of entries) {
    const dot = file.lastIndexOf('.');
    if (dot <= 0) continue;
    const ext = file.slice(dot).toLowerCase();
    if (!ALLOWED_EXT.has(ext)) continue;
    const fullPath = join(galleryDir, file);
    const st = await stat(fullPath);
    const dims = await readDimensions(fullPath);
    items.push({
      src: `/gallery/${encodeURIComponent(file)}`,
      width: dims?.width ?? 0,
      height: dims?.height ?? 0,
      bytes: st.size,
      name: file.slice(0, dot),
      mtimeMs: st.mtimeMs,
    });
  }
  // 按修改时间降序：最新添加的图片排在最前面，出现在第一排
  items.sort((a, b) => b.mtimeMs - a.mtimeMs);
  return items;
}