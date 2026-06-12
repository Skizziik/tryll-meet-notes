/** Проверка Google-кредов: читаем ближайшие события календаря. */
import "dotenv/config";
import { google } from "googleapis";
import { googleAuth } from "../src/google";

async function main() {
  const cal = google.calendar({ version: "v3", auth: googleAuth() });
  const res = await cal.events.list({
    calendarId: process.env.GOOGLE_CALENDAR_ID || "primary",
    timeMin: new Date().toISOString(),
    maxResults: 5,
    singleEvents: true,
    orderBy: "startTime",
  });
  const items = res.data.items ?? [];
  console.log(`OK, календарь читается. Ближайшие события: ${items.length}`);
  for (const ev of items) {
    const start = ev.start?.dateTime ?? ev.start?.date;
    const hasMeet = ev.hangoutLink ? " [Meet]" : "";
    console.log(`- ${start} | ${ev.summary}${hasMeet}`);
  }
}
main().catch((e) => {
  console.error("FAIL:", e.message ?? e);
  process.exit(1);
});
