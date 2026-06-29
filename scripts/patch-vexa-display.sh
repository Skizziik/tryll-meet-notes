#!/bin/sh
# Патч vexa-lite: авто-чистка зависших X-локов перед выбором per-bot дисплея.
#
# ПРОБЛЕМА: каждый бот в vexa-lite поднимает свой Xvfb-дисплей (:101..:199) и
# создаёт /tmp/.X<n>-lock. Лок НЕ удаляется при выходе бота → за дни (и при
# рестарте контейнера, который не чистит /tmp) локи копятся. Новый бот утыкается
# в «занятый» дисплей → Xvfb не стартует → Chrome: "Missing X server / Address
# already in use" → бот падает на старте. По факту 29.06 так легли ВСЕ миты утра.
#
# ФИКС: перед циклом выбора дисплея в bot-slot-wrapper.sh / entrypoint.sh чистим
# локи мёртвых дисплеев. X-лок хранит PID своего X-сервера — если процесс мёртв,
# лок (и сокет) удаляем. Живые дисплеи не трогаем. Идемпотентно (tryll-clean-stale-x).
#
# Применять после пересоздания контейнера vexa-lite:
#   docker cp scripts/patch-vexa-display.sh vexa-lite:/tmp/ && \
#   docker exec vexa-lite sh /tmp/patch-vexa-display.sh
set -e
docker exec vexa-lite python3 -c "
import io
block = '''  # tryll-clean-stale-x: убрать зависшие X-локи от мёртвых ботов (лок хранит PID
  # X-сервера). Иначе новый бот утыкается в занятый дисплей -> Chrome не стартует.
  for __n in \$(seq 101 199); do
    __lk=\"/tmp/.X\$__n-lock\"
    if [ -e \"\$__lk\" ]; then
      __pid=\$(tr -dc '0-9' < \"\$__lk\" 2>/dev/null)
      if [ -z \"\$__pid\" ] || ! kill -0 \"\$__pid\" 2>/dev/null; then
        rm -f \"\$__lk\" \"/tmp/.X11-unix/X\$__n\" 2>/dev/null
        echo \"[lite-slot] removed stale X lock :\$__n\"
      fi
    fi
  done
'''
anchor = 'if [ \"\${DISPLAY:-:99}\" = \":99\" ]; then\n'
for p in ['/app/vexa-bot/bot-slot-wrapper.sh','/app/vexa-bot/entrypoint.sh']:
    try:
        s=io.open(p,encoding='utf-8').read()
    except FileNotFoundError:
        print(p+': not found, skip'); continue
    if 'tryll-clean-stale-x' in s:
        print(p+': already patched'); continue
    if anchor not in s:
        print(p+': ANCHOR NOT FOUND — проверить вручную'); continue
    s=s.replace(anchor, anchor+block, 1)
    io.open(p,'w',encoding='utf-8').write(s)
    print(p+': patched (stale-X cleanup added)')
"
echo "patch-vexa-display: done (применится при следующем запуске бота)"
