cd /home/nico/nicoprj/mediatools/organise
# /home/nico/bin/lein exec /home/nico/nicoprj/systemtools/diskcatalog/do-cron.clj >/home/nico/log/diskcatalog-do-cron.log 2>&1
/home/nico/bin/lein exec /home/nico/nicoprj/mediatools/organise/move-series.clj >/home/nico/log/move-series-cron.log 2>&1

# hierna unison voor series, films en films-tijdelijk
/home/nico/bin/unison -auto -batch series-rpi >/dev/null 2>&1
/home/nico/bin/unison -auto -batch films-rpi >/dev/null 2>&1
/home/nico/bin/unison -auto -batch films-temp-rpi >/dev/null 2>&1
/home/nico/bin/unison -auto -batch cabaret-rpi >/dev/null 2>&1

