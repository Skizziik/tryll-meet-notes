#!/bin/sh
# Патч vexa-lite: включать виртуальную камеру бота, когда задан default_avatar_url.
# В стоковом meeting-api параметр cameraEnabled не прокинут из API (v0.10.x).
# Применять после пересоздания контейнера vexa-lite: bash scripts/patch-vexa-camera.sh
set -e
docker exec vexa-lite python3 -c "
import io
p = '/app/meeting-api/meeting_api/meetings.py'
src = io.open(p, encoding='utf-8').read()
anchor = 'bot_config[\"defaultAvatarUrl\"] = req.default_avatar_url'
patch = anchor + '\n        bot_config[\"cameraEnabled\"] = True  # tryll patch: avatar needs camera'
if 'tryll patch' in src:
    print('already patched')
elif anchor not in src:
    raise SystemExit('ANCHOR NOT FOUND — версия Vexa изменилась, патч обновить вручную')
else:
    io.open(p, 'w', encoding='utf-8').write(src.replace(anchor, patch))
    print('patched')
"
# перезапуск meeting-api (supervisord поднимет сам)
docker exec vexa-lite sh -c "kill \$(ps aux | grep 'meeting_api.main' | grep -v grep | awk '{print \$2}')"
echo "meeting-api перезапускается..."
