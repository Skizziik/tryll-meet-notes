/**
 * Тест письма-карточки: шлёт ТОЛЬКО тебе (maksim@) пример, чтобы посмотреть вёрстку.
 * Запуск: npx tsx scripts/send-test-email.ts
 */
import "dotenv/config";
import { sendNotesEmail } from "../src/email";

const TO = process.env.NOTES_EMAIL_FROM || "maksim.makevich@tryllengine.com";
const title = "Sync Tryll";
const dateISO = "2026-06-17";
const docUrl = "https://drive.google.com/file/d/1rdBT_RQ_HWer8s6COLmWmL-cku7FoAQ9/view";
const tldr = [
  "Reviewed demo development progress and media strategy",
  "Decided to prioritize internal documentation",
  "Model-manager sync between Unreal and Unity is the main technical focus",
  "Weekly tasks distributed across the team",
];

sendNotesEmail([TO], title, dateISO, docUrl, tldr)
  .then(() => console.log(`тестовое письмо-карточка отправлено на ${TO}`))
  .catch((e) => {
    console.error("FAIL:", e.message ?? e);
    process.exit(1);
  });
