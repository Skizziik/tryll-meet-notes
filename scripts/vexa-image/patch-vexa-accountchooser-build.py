# -*- coding: utf-8 -*-
# Build-safe патч: пройти auth-экраны Google перед митом.
# ПРОБЛЕМА: при заходе на мит Google (для остывшей сессии) показывает
#   1) «выбери аккаунт» (signin/accountchooser), затем
#   2) «verify it's you» / ввод пароля (signin/challenge/pwd).
# Штатный join.js их не обрабатывает → 30с таймаут → join_meeting_error.
# ФИКС: пока мы на accounts.google.com — кликаем плитку аккаунта, а на экране
# пароля вводим пароль из env BOT_GOOGLE_PASSWORD (в коде/логах пароля НЕТ).
# 2FA на аккаунте должен быть ВЫКЛючен. Идемпотентно (маркер tryll-authscreens).
import io, sys

P = "/app/vexa-bot/dist/platforms/googlemeet/join.js"
src = io.open(P, encoding="utf-8").read()

anchor = '        (0, utils_1.log)("📸 Diagnostic screenshot: auth lobby state");\n'

block = (
    '        /* tryll-authscreens: пройти экраны Google — «выбери аккаунт» и ввод пароля.\n'
    '           Пароль из env BOT_GOOGLE_PASSWORD, в логи не пишем. Если уже на meet — no-op. */\n'
    '        try {\n'
    '            const __pw = process.env.BOT_GOOGLE_PASSWORD || "";\n'
    '            for (let __ac = 0; __ac < 20; __ac++) {\n'
    '                const __u = page.url();\n'
    '                if (!/accounts\\.google\\.com/.test(__u)) break;\n'
    '                if (/challenge\\/pwd|\\/pwd\\b/.test(__u)) {\n'
    '                    const __pf = await page.$(\'input[type="password"]\');\n'
    '                    if (__pw && __pf) {\n'
    '                        (0, utils_1.log)("tryll: password challenge — entering stored password");\n'
    '                        await __pf.fill(__pw);\n'
    '                        await Promise.all([\n'
    '                            page.waitForNavigation({ timeout: 15000 }).catch(() => {}),\n'
    '                            page.click(\'#passwordNext, button:has-text("Next"), button:has-text("Далее")\').catch(() => {}),\n'
    '                        ]);\n'
    '                        await page.waitForTimeout(3000);\n'
    '                        continue;\n'
    '                    } else {\n'
    '                        (0, utils_1.log)("tryll: password challenge but no BOT_GOOGLE_PASSWORD/field — cannot pass");\n'
    '                        await page.screenshot({ path: \'/app/storage/screenshots/tryll-authscreen.png\', fullPage: true }).catch(() => {});\n'
    '                        break;\n'
    '                    }\n'
    '                }\n'
    '                const __sel = (await page.$(\'[data-identifier]\')) ? \'[data-identifier]\'\n'
    '                    : (await page.$(\'[data-authuser]\')) ? \'[data-authuser]\' : null;\n'
    '                if (__sel) {\n'
    '                    (0, utils_1.log)("tryll: account chooser — clicking tile (" + __sel + ")");\n'
    '                    await Promise.all([\n'
    '                        page.waitForNavigation({ timeout: 15000 }).catch(() => {}),\n'
    '                        page.click(__sel).catch(() => {}),\n'
    '                    ]);\n'
    '                    await page.waitForTimeout(2500);\n'
    '                    continue;\n'
    '                }\n'
    '                (0, utils_1.log)("tryll: unhandled accounts.google screen — screenshot -> " + __u);\n'
    '                await page.screenshot({ path: \'/app/storage/screenshots/tryll-authscreen.png\', fullPage: true }).catch(() => {});\n'
    '                break;\n'
    '            }\n'
    '            if (/meet\\.google\\.com/.test(page.url())) (0, utils_1.log)("tryll: past auth screens, on meet -> " + page.url());\n'
    '        } catch (__ace) { (0, utils_1.log)("tryll: auth-screens handler error (non-fatal): " + (__ace && __ace.message)); }\n'
)

if "tryll-authscreens" in src:
    print("join.js: auth-screens handler already applied")
elif anchor not in src:
    sys.exit("AUTHSCREENS: anchor not found (auth lobby screenshot line)")
else:
    io.open(P, "w", encoding="utf-8").write(src.replace(anchor, anchor + block, 1))
    print("join.js: auth-screens handler injected (chooser + password)")

print("authscreens (build): done")
