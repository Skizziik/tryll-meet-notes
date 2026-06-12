/** Проверка Drive-доступа: листинг подпапок корневой папки Notes. */
import "dotenv/config";
import { google } from "googleapis";
import { googleAuth } from "../src/google";

async function main() {
  const drive = google.drive({ version: "v3", auth: googleAuth() });
  const rootId = process.env.DRIVE_ROOT_FOLDER_ID!;
  const meta = await drive.files.get({ fileId: rootId, fields: "name", supportsAllDrives: true });
  const res = await drive.files.list({
    q: `'${rootId}' in parents and trashed = false`,
    fields: "files(id, name, mimeType)",
    supportsAllDrives: true,
    includeItemsFromAllDrives: true,
  });
  console.log(`OK, корень виден: "${meta.data.name}"`);
  for (const f of res.data.files ?? []) {
    const kind = f.mimeType?.includes("folder") ? "папка" : "файл";
    console.log(`- [${kind}] ${f.name}`);
  }
}
main().catch((e) => {
  console.error("FAIL:", e.message ?? e);
  process.exit(1);
});
