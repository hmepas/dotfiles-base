import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

async function run(command: string, args: string[]) {
  return execFileAsync(command, args, { timeout: 10_000, maxBuffer: 1024 * 1024 });
}

async function readMacClipboardImage(): Promise<string | null> {
  const timestamp = Date.now();
  const pngPath = join(tmpdir(), `pi_clipboard_${timestamp}.png`);
  const tiffPath = join(tmpdir(), `pi_clipboard_${timestamp}.tiff`);

  const pngScript = `
    set outFile to POSIX file ${JSON.stringify(pngPath)}
    set imageData to the clipboard as «class PNGf»
    set fileRef to open for access outFile with write permission
    set eof of fileRef to 0
    write imageData to fileRef
    close access fileRef
    return POSIX path of outFile
  `;

  try {
    await run("osascript", ["-e", pngScript]);
    if (existsSync(pngPath)) return pngPath;
  } catch {
    // Many macOS apps put TIFF data on NSPasteboard instead of PNG.
  }

  const tiffScript = `
    set outFile to POSIX file ${JSON.stringify(tiffPath)}
    set imageData to the clipboard as TIFF picture
    set fileRef to open for access outFile with write permission
    set eof of fileRef to 0
    write imageData to fileRef
    close access fileRef
    return POSIX path of outFile
  `;

  try {
    await run("osascript", ["-e", tiffScript]);
    if (!existsSync(tiffPath)) return null;
    await run("sips", ["-s", "format", "png", tiffPath, "--out", pngPath]);
    return existsSync(pngPath) ? pngPath : null;
  } catch {
    return null;
  }
}

async function pasteImage(ctx: any) {
  ctx.ui.setStatus("mac-paste-image", "Reading macOS clipboard image...");
  try {
    const filePath = await readMacClipboardImage();
    if (!filePath) {
      ctx.ui.notify("No image data found in macOS clipboard", "warning");
      return;
    }

    const existingText = ctx.ui.getEditorText();
    ctx.ui.setEditorText(existingText ? `${existingText} @${filePath}` : `@${filePath}`);
    ctx.ui.notify("Clipboard image saved and inserted", "success");
  } catch (error: any) {
    ctx.ui.notify(`Paste image failed: ${error?.message || String(error)}`, "error");
  } finally {
    ctx.ui.setStatus("mac-paste-image", undefined);
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("ctrl+shift+v", {
    description: "Paste image from macOS clipboard",
    handler: pasteImage,
  });

  pi.registerCommand("paste-image-mac", {
    description: "Save image from macOS clipboard and insert it as @file",
    handler: async (_args, ctx) => pasteImage(ctx),
  });
}
