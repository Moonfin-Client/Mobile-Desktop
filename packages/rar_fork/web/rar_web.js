// web/rar_web.js
//
// JavaScript glue code for RAR operations on web platform.
// Uses libarchive.js (WASM-compiled libarchive) for RAR archive handling.
//
// Library: libarchive.js
// License: BSD (libarchive) + MIT (JavaScript wrapper)
// Source: https://github.com/nicolo-ribaudo/libarchive.js (or similar)
//
// This file exposes a simple async API that the Dart code interacts with
// via JS interop. The WASM module is loaded on-demand.
//
// API:
// - RarWeb.init() - Initialize the WASM library
// - RarWeb.listFromBytes(Uint8Array, password) - List archive contents
// - RarWeb.extractFromBytes(Uint8Array, password) - Extract archive contents

(function () {
  'use strict';

  // Bump this to force cache-busting if needed
  const BUILD_TAG = 'v4';
  const warn = (...args) => console.warn('[RAR Web]', ...args);
  const err = (...args) => console.error('[RAR Web]', ...args);

  // WASM module state (libarchive.js only)
  let wasmModule = null;
  let isInitialized = false;

  // The RarWeb API exposed to Dart
  window.RarWeb = {
    // Check if library is initialized
    get isInitialized() {
      return isInitialized;
    },

    // Initialize the WASM library
    // Must be called before any other operations
    async init() {
      if (isInitialized) {
        return true;
      }

      try {
        // Load the libarchive WASM module
        // We use a CDN-hosted version or local file depending on configuration
        wasmModule = await loadArchiveModule();
        isInitialized = true;
        return true;
      } catch (error) {
        err('Failed to initialize RAR WASM library:', error);
        return false;
      }
    },

    // List contents of a RAR archive
    // data: Uint8Array - The RAR file data
    // password: String|null - Optional password for encrypted archives
    // Returns: { success: boolean, message: string, files: string[] }
    async listFromBytes(data, password) {
      if (!isInitialized) {
        return {
          success: false,
          message: 'RAR library not initialized. Call init() first.',
          files: []
        };
      }

      try {
        const archive = await openArchive(data, password);

        const entries = await listArchiveEntries(archive);
        const files = entries
          .map((entry) => entry && (entry.path || entry.name || entry.fileName || ''))
          .filter((p) => !!p);

        if (typeof archive.close === 'function') {
          archive.close();
        }

        return {
          success: true,
          message: 'Successfully listed RAR contents',
          files: files
        };
      } catch (error) {
        err('listFromBytes failed', error);
        return {
          success: false,
          message: getErrorMessage(error),
          files: []
        };
      }
    },

    // Extract contents of a RAR archive
    // data: Uint8Array - The RAR file data
    // password: String|null - Optional password for encrypted archives
    // Returns: { success: boolean, message: string, entries: [{name, data, size}] }
    async extractFromBytes(data, password) {
      if (!isInitialized) {
        return {
          success: false,
          message: 'RAR library not initialized. Call init() first.',
          entries: []
        };
      }

      try {
        const archive = await openArchive(data, password);

        const entries = await extractArchiveEntries(archive);

        if (typeof archive.close === 'function') {
          archive.close();
        }

        return {
          success: true,
          message: `Extraction completed successfully (${entries.length} files)`,
          entries: entries
        };
      } catch (error) {
        err('extractFromBytes failed', error);
        return {
          success: false,
          message: getErrorMessage(error),
          entries: []
        };
      }
    }
  };

  // Load the archive WASM module (libarchive.js only, no fallbacks)
  async function loadArchiveModule() {
    const localBases = getLocalBaseUrls();
    let lastError;
    for (const base of localBases) {
      try {
        const archive = await tryLoadArchiveModuleFromBase(base);
        if (archive) {
          return archive;
        }
      } catch (e) {
        lastError = e;
        warn(`Failed to load libarchive from ${base}`, e);
      }
    }
    throw lastError || new Error('libarchive.js could not be loaded from local assets');
  }

  // Normalize listing across libarchive.js
  async function listArchiveEntries(archive) {
    if (!archive) {
      throw new Error('Archive instance is null');
    }

    const summary = summarizeArchive(archive);

    // Direct worker access (bypassing the wrapper's tree construction)
    if (archive.client && typeof archive.client.listFiles === 'function') {
      try {
        const files = await archive.client.listFiles();
        if (Array.isArray(files)) {
          return files;
        }
      } catch (e) {
        warn('archive.client.listFiles failed, falling back', e);
      }
    }

    if (typeof archive.listFiles === 'function') {
      const files = await archive.listFiles();
      if (!Array.isArray(files)) {
        throw new Error('archive.listFiles returned non-array');
      }
      return files;
    }

    if (typeof archive.entries === 'function') {
      const result = [];
      for (const entry of archive.entries(true)) {
        result.push(entry);
      }
      return result;
    }

    throw new Error('Archive entries not iterable');
  }

  // Normalize extraction across libarchive.js
  async function extractArchiveEntries(archive) {
    if (!archive) {
      throw new Error('Archive instance is null');
    }

    const summary = summarizeArchive(archive);
    // Direct worker access (bypassing the wrapper's tree construction)
    if (archive.client && typeof archive.client.extractFiles === 'function') {
      try {
        const files = await archive.client.extractFiles();
        const normalized = await normalizeFileResults(files);
        if (normalized) {
          return normalized;
        }
      } catch (e) {
        warn('archive.client.extractFiles failed, falling back', e);
      }
    }

    // Preferred: libarchive.js extractFiles (includes fileData)
    if (typeof archive.extractFiles === 'function') {
      const files = await archive.extractFiles();
      const normalized = await normalizeFileResults(files);
      if (normalized) {
        return normalized;
      }
      warn('extractFiles returned unexpected shape; trying per-file extraction via entries');
    }

    // Attempt extraction via entries(false) generator (libarchive API)
    if (typeof archive.entries === 'function') {
      const results = [];
      for (const entry of archive.entries(false)) {
        if (!entry || entry.isDirectory) continue;
        const name = entry.path || entry.name || entry.fileName || '';
        if (!name) continue;
        if (!entry.fileData) {
          throw new Error(`entries() missing fileData for ${name}`);
        }
        const uint8 = new Uint8Array(entry.fileData);
        results.push({
          name,
          data: uint8,
          size: uint8.byteLength,
        });
      }
      return results;
    }

    throw new Error('Archive entries not extractable (extractFiles missing)');
  }

  async function normalizeFileResults(files) {
    if (!files) return null;

    const arr = Array.isArray(files) || typeof files.length === 'number'
      ? Array.from(files)
      : (files.files && Array.isArray(files.files) ? files.files : null);
    if (!arr) return null;

    const result = [];
    for (const f of arr) {
      if (!f) continue;
      const name = f.path || f.fileName || f.name || '';
      let data = f.fileData || f.data || f.buffer || f.bytes;
      if (!data && f.file && typeof f.file.arrayBuffer === 'function') {
        const buf = await f.file.arrayBuffer();
        data = new Uint8Array(buf);
      } else if (!data && typeof f.arrayBuffer === 'function') {
        const buf = await f.arrayBuffer();
        data = new Uint8Array(buf);
      }
      const uint8 = data ? new Uint8Array(data) : new Uint8Array();
      result.push({
        name,
        data: uint8,
        size: uint8.byteLength || f.size || 0,
      });
    }
    return result;
  }

  function summarizeArchive(archive) {
    if (!archive) return { nullArchive: true };
    const entries = archive.entries;
    const hasIterator = entries && typeof entries[Symbol.iterator] === 'function';
    const isArray = Array.isArray(entries);
    const length = entries && typeof entries.length === 'number' ? entries.length : undefined;
    const ctor = archive && archive.constructor && archive.constructor.name;
    return {
      ctor,
      keys: Object.keys(archive || {}),
      hasEntries: !!entries,
      entriesType: typeof entries,
      entriesHasIterator: hasIterator,
      entriesIsArray: isArray,
      entriesLength: length,
      listFilesFn: typeof archive.listFiles,
      getFilesArrayFn: typeof archive.getFilesArray,
      extractFilesFn: typeof archive.extractFiles,
      closeFn: typeof archive.close,
      hasClient: !!archive.client,
      clientListFiles: archive.client && typeof archive.client.listFiles,
      clientExtractFiles: archive.client && typeof archive.client.extractFiles
    };
  }

  // Determine possible base URLs where libarchive assets might live
  function getLocalBaseUrls() {
    const bases = [];

    // Try to derive from the current script tag (works with Flutter asset pipeline)
    const script = document.currentScript || document.querySelector('script[src*="rar_web.js"]');
    if (script && script.src) {
      try {
        const url = new URL(script.src, window.location.href);
        const base = url.href.substring(0, url.href.lastIndexOf('/') + 1);
        bases.push(base);
      } catch (e) {
        console.warn('Failed to resolve base URL from script', e);
      }
    }

    // Common Flutter asset paths
    bases.push('assets/packages/rar/');
    bases.push('/assets/packages/rar/');
    bases.push('./');

    // Remove duplicates/empty entries
    return Array.from(new Set(bases.filter(Boolean)));
  }

  // Try to load libarchive from a specific base path
  async function tryLoadArchiveModuleFromBase(baseUrl) {
    const normalizedBase = baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`;
    const scriptUrl = `${normalizedBase}libarchive.js`;
    const workerUrl = `${normalizedBase}worker-bundle.js`;
    const wasmUrl = `${normalizedBase}libarchive.wasm`;

    try {
      if (typeof Archive === 'undefined') {
        await importArchiveLibrary([scriptUrl]);
      }

      if (typeof Archive !== 'undefined') {
        await initArchive({ workerUrl, base: normalizedBase, wasmUrl });
        return Archive;
      }
    } catch (e) {
      warn(`Failed to load libarchive from ${scriptUrl}:`, e);
      throw e;
    }

    return null;
  }

  // Initialize Archive with a worker URL and a locateFile override so the WASM
  // file is resolved relative to the same base (works in Flutter asset paths).
  async function initArchive({ workerUrl, wasmUrl, base }) {
    const baseUrl = ensureTrailingSlash(base || workerUrl.substring(0, workerUrl.lastIndexOf('/') + 1));
    const locateFile = (path) => {
      if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:') || path.startsWith('blob:')) {
        return path;
      }
      return baseUrl + path;
    };

    const options = {
      workerUrl,
      locateFile,
      wasmBinaryFile: wasmUrl
    };

    return Archive.init(options);
  }

  function ensureTrailingSlash(url) {
    if (!url) return '';
    return url.endsWith('/') ? url : `${url}/`;
  }

  // Load a script dynamically
  // (Unused) kept for reference; imports are module-based

  // Dynamically import archive library as a module and attach Archive to globalThis.
  async function importArchiveLibrary(urls) {
    let lastError;
    for (const url of urls) {
      if (!url) continue;
      try {
        const mod = await import(/* webpackIgnore: true */ url);
        const archiveExport = mod.Archive || mod.default;
        if (!archiveExport) {
          throw new Error('Archive export missing');
        }
        globalThis.Archive = archiveExport;
        return archiveExport;
      } catch (e) {
        lastError = e;
        warn('Import failed', url, e);
      }
    }
    throw lastError || new Error('Failed to import Archive module');
  }

  // Open an archive from Uint8Array data
  async function openArchive(data, password) {
    if (!wasmModule || !wasmModule.open) {
      throw new Error('libarchive.js is not initialized');
    }
    const options = {};
    if (password) {
      options.passphrase = password;
    }
    return await wasmModule.open(new File([data], 'archive.rar'), options);
  }

  // Get a user-friendly error message
  function getErrorMessage(error) {
    if (error.message) {
      // Handle common error types
      const msg = error.message.toLowerCase();
      if (msg.includes('password') || msg.includes('encrypted')) {
        return 'Incorrect password or password required';
      }
      if (msg.includes('corrupt') || msg.includes('invalid')) {
        return 'Corrupt or invalid RAR archive';
      }
      if (msg.includes('format') || msg.includes('unsupported')) {
        return 'Unknown or unsupported archive format';
      }
      return error.message;
    }
    return 'Unknown error occurred';
  }

  // Minimal RAR implementation for when libarchive.js is not available
  // This provides basic RAR v4/v5 support using pure JavaScript
  function createMinimalRarModule() {
    return {
      parseRar: function (data, password) {
        // Ensure we have a proper Uint8Array with accessible buffer
        // Data from Dart's JSUint8Array may need conversion
        let uint8Data;
        if (data instanceof Uint8Array) {
          // Make a copy to ensure we have a proper ArrayBuffer
          uint8Data = new Uint8Array(data);
        } else if (ArrayBuffer.isView(data)) {
          uint8Data = new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
        } else if (data instanceof ArrayBuffer) {
          uint8Data = new Uint8Array(data);
        } else if (data && typeof data.length === 'number') {
          // Handle array-like objects from Dart
          uint8Data = new Uint8Array(data.length);
          for (let i = 0; i < data.length; i++) {
            uint8Data[i] = data[i];
          }
        } else {
          throw new Error('Invalid data type for RAR parsing: ' + (typeof data));
        }

        if (uint8Data.length === 0) {
          throw new Error('RAR data is empty (0 bytes)');
        }

        return new MinimalRarArchive(uint8Data, password);
      }
    };
  }

  // Minimal RAR archive parser
  // Supports basic RAR v4 and v5 format parsing
  class MinimalRarArchive {
    constructor(data, password) {
      // data should now be a proper Uint8Array with accessible buffer
      this.data = data;
      this.password = password;
      this.entries = [];
      this.parse();
    }

    parse() {
      // Validate we have a proper ArrayBuffer-backed Uint8Array
      if (!this.data.buffer || !(this.data.buffer instanceof ArrayBuffer)) {
        throw new Error('RAR data does not have a valid ArrayBuffer. Buffer type: ' + (typeof this.data.buffer));
      }

      const view = new DataView(this.data.buffer, this.data.byteOffset || 0, this.data.byteLength);

      // Check RAR signature
      // RAR 4.x: 0x52 0x61 0x72 0x21 0x1A 0x07 0x00
      // RAR 5.x: 0x52 0x61 0x72 0x21 0x1A 0x07 0x01 0x00
      const sig = this.data.slice(0, 8);
      const rar4Sig = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00];
      const rar5Sig = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00];

      let isRar4 = true;
      let isRar5 = true;

      for (let i = 0; i < 7; i++) {
        if (sig[i] !== rar4Sig[i]) isRar4 = false;
      }
      for (let i = 0; i < 8; i++) {
        if (sig[i] !== rar5Sig[i]) isRar5 = false;
      }

      if (!isRar4 && !isRar5) {
        const sigHex = Array.from(sig).map(b => '0x' + b.toString(16).padStart(2, '0')).join(' ');
        throw new Error('Not a valid RAR archive. Signature bytes: ' + sigHex);
      }

      if (isRar5) {
        this.parseRar5(view, 8);
      } else {
        this.parseRar4(view, 7);
      }
    }

    parseRar4(view, offset) {
      // RAR 4.x format parsing
      // Header flags
      const LHD_LARGE = 0x0100;      // Large file (>2GB), has HIGH_PACK/UNP_SIZE fields
      const LHD_UNICODE = 0x0200;    // Filename is Unicode encoded
      const LONG_BLOCK = 0x8000;     // ADD_SIZE field present (packed data follows header)

      while (offset < this.data.length - 7) {
        // Read block header
        const headerCrc = view.getUint16(offset, true);
        const headerType = view.getUint8(offset + 2);
        const headerFlags = view.getUint16(offset + 3, true);
        const headerSize = view.getUint16(offset + 5, true);

        if (headerSize < 7 || offset + headerSize > this.data.length) {
          break; // End of valid headers
        }

        // File header (type 0x74)
        if (headerType === 0x74) {
          let packSize = view.getUint32(offset + 7, true);
          let unpSize = view.getUint32(offset + 11, true);
          const method = view.getUint8(offset + 25);
          const nameSize = view.getUint16(offset + 26, true);
          const fileAttr = view.getUint32(offset + 28, true);

          // Handle LHD_LARGE flag - high bits for pack/unpack sizes
          if (headerFlags & LHD_LARGE) {
            const highPackSize = view.getUint32(offset + 32, true);
            const highUnpSize = view.getUint32(offset + 36, true);
            packSize = packSize + (highPackSize * 0x100000000);
            unpSize = unpSize + (highUnpSize * 0x100000000);
          }

          // The filename is at the END of the header, right before packed data
          // headerSize includes everything from start of header to end of filename
          const nameOffset = offset + headerSize - nameSize;

          // Validate nameOffset is reasonable
          if (nameOffset < offset + 32 || nameOffset + nameSize > offset + headerSize) {
            // Skip malformed entry
            offset += headerSize + packSize;
            continue;
          }

          // Read filename bytes
          const nameBytes = this.data.slice(nameOffset, nameOffset + nameSize);
          let fileName;

          // Handle Unicode filenames (LHD_UNICODE flag)
          if (headerFlags & LHD_UNICODE) {
            // Unicode format: ASCII name + null byte + encoded Unicode data
            const nullIndex = Array.from(nameBytes).indexOf(0);
            if (nullIndex > 0 && nullIndex < nameBytes.length - 1) {
              // Has Unicode part - decode the Unicode portion
              fileName = this.decodeUnicodeName(nameBytes, nullIndex);
            } else if (nullIndex === -1) {
              // No null terminator, treat as UTF-8
              fileName = new TextDecoder('utf-8').decode(nameBytes);
            } else {
              // Just ASCII part
              fileName = new TextDecoder('utf-8').decode(nameBytes.slice(0, nullIndex));
            }
          } else {
            // Standard filename - try UTF-8
            fileName = new TextDecoder('utf-8').decode(nameBytes);
          }

          // Normalize path separators
          fileName = fileName.replace(/\\/g, '/');

          const isDirectory = (fileAttr & 0x10) !== 0 || fileName.endsWith('/');

          const capturedOffset = offset;
          const capturedHeaderSize = headerSize;
          const capturedPackSize = packSize;
          const capturedMethod = method;

          this.entries.push({
            path: fileName,
            isDirectory: isDirectory,
            size: unpSize,
            compressedSize: packSize,
            _offset: offset + headerSize,
            _packSize: packSize,
            extract: async () => {
              if (capturedMethod === 0x30) { // Stored (no compression)
                return this.data.slice(capturedOffset + capturedHeaderSize, capturedOffset + capturedHeaderSize + capturedPackSize).buffer;
              }
              throw new Error('Compressed files require full RAR library. Please include libarchive.js.');
            }
          });

          // Move to next header - packed data follows the header
          offset += headerSize + packSize;
        } else if (headerType === 0x7b) {
          // End of archive marker
          break;
        } else {
          // Skip other block types
          let addSize = 0;
          if (headerFlags & LONG_BLOCK) {
            addSize = view.getUint32(offset + 7, true);
          }
          offset += headerSize + addSize;
        }
      }
    }

    // Decode RAR Unicode filename format
    decodeUnicodeName(nameBytes, nullIndex) {
      // RAR Unicode encoding: ASCII name + 0x00 + high byte flags + encoded chars
      const asciiPart = new TextDecoder('utf-8').decode(nameBytes.slice(0, nullIndex));
      const unicodeData = nameBytes.slice(nullIndex + 1);

      if (unicodeData.length === 0) {
        return asciiPart;
      }

      // The Unicode encoding uses the ASCII name as a base and encodes differences
      let result = '';
      let asciiPos = 0;
      let dataPos = 0;
      let highByte = unicodeData[dataPos++] || 0;

      while (asciiPos < asciiPart.length && dataPos <= unicodeData.length) {
        const flags = dataPos < unicodeData.length ? unicodeData[dataPos++] : 0;

        for (let i = 0; i < 4 && asciiPos < asciiPart.length; i++) {
          const flagBits = (flags >> (i * 2)) & 0x03;

          switch (flagBits) {
            case 0: // Use ASCII char
              result += asciiPart[asciiPos++];
              break;
            case 1: // Use ASCII char + high byte
              if (dataPos < unicodeData.length) {
                const lowByte = asciiPart.charCodeAt(asciiPos++);
                result += String.fromCharCode((highByte << 8) | lowByte);
              } else {
                result += asciiPart[asciiPos++];
              }
              break;
            case 2: // Use next byte + high byte
              if (dataPos < unicodeData.length) {
                const lowByte = unicodeData[dataPos++];
                result += String.fromCharCode((highByte << 8) | lowByte);
                asciiPos++;
              } else {
                result += asciiPart[asciiPos++];
              }
              break;
            case 3: // Use next two bytes
              if (dataPos + 1 < unicodeData.length) {
                const lowByte = unicodeData[dataPos++];
                const newHighByte = unicodeData[dataPos++];
                result += String.fromCharCode((newHighByte << 8) | lowByte);
                asciiPos++;
              } else {
                result += asciiPart[asciiPos++];
              }
              break;
          }
        }
      }

      return result || asciiPart;
    }

    parseRar5(view, offset) {
      // RAR 5.x format parsing
      while (offset < this.data.length - 4) {
        // Read header CRC32 (4 bytes)
        const headerCrc = view.getUint32(offset, true);
        offset += 4;

        // Read header size (vint)
        const { value: headerSize, bytesRead: hb } = this.readVInt(view, offset);
        offset += hb;

        if (headerSize < 1 || offset + Number(headerSize) > this.data.length) {
          break; // End of valid headers
        }

        const headerStart = offset;

        // Read header type (vint)
        const { value: headerType, bytesRead: tb } = this.readVInt(view, offset);
        offset += tb;

        // Read header flags (vint)
        const { value: headerFlags, bytesRead: fb } = this.readVInt(view, offset);
        offset += fb;

        // File header (type 2)
        if (headerType === BigInt(2)) {
          // File header
          const { value: fileFlags, bytesRead: ffb } = this.readVInt(view, offset);
          offset += ffb;

          const { value: unpSize, bytesRead: ub } = this.readVInt(view, offset);
          offset += ub;

          const { value: attributes, bytesRead: ab } = this.readVInt(view, offset);
          offset += ab;

          // Skip mtime if present
          if (fileFlags & BigInt(0x02)) {
            offset += 4;
          }

          // Skip data CRC if present
          if (fileFlags & BigInt(0x04)) {
            offset += 4;
          }

          // Read compression info
          const { value: compInfo, bytesRead: cb } = this.readVInt(view, offset);
          offset += cb;

          // Read host OS
          const { value: hostOS, bytesRead: ob } = this.readVInt(view, offset);
          offset += ob;

          // Read name length
          const { value: nameLen, bytesRead: nb } = this.readVInt(view, offset);
          offset += nb;

          // Read filename
          const nameBytes = this.data.slice(offset, offset + Number(nameLen));
          const fileName = new TextDecoder('utf-8').decode(nameBytes);

          const isDirectory = (fileFlags & BigInt(0x01)) !== BigInt(0);

          this.entries.push({
            path: fileName,
            isDirectory: isDirectory,
            size: Number(unpSize),
            compressedSize: 0,
            extract: async () => {
              throw new Error('RAR 5.x extraction requires full RAR library. Please include libarchive.js.');
            }
          });
        } else if (headerType === BigInt(5)) {
          // End of archive marker
          break;
        }

        // Move to next header
        offset = headerStart + Number(headerSize);

        // Skip data area if present
        if (headerFlags & BigInt(0x0002)) {
          const { value: dataSize, bytesRead: db } = this.readVInt(view, offset);
          offset += db + Number(dataSize);
        }
      }
    }

    // Read a variable-length integer (RAR5 format)
    readVInt(view, offset) {
      let value = BigInt(0);
      let bytesRead = 0;
      let shift = BigInt(0);

      while (offset + bytesRead < view.byteLength) {
        const byte = view.getUint8(offset + bytesRead);
        bytesRead++;
        value |= BigInt(byte & 0x7F) << shift;
        if ((byte & 0x80) === 0) {
          break;
        }
        shift += BigInt(7);
        if (bytesRead > 10) {
          break; // Prevent infinite loop
        }
      }

      return { value, bytesRead };
    }

    close() {
      // Cleanup
      this.data = null;
      this.entries = [];
    }
  }

})();
