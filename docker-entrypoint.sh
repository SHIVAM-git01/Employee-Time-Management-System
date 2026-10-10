
#!/bin/sh
set -eu

APP_PORT="${PORT:-10000}"

sed -i "s/port=\"8080\"/port=\"${APP_PORT}\"/" "$CATALINA_HOME/conf/server.xml"

exec "$CATALINA_HOME/bin/catalina.sh" run
