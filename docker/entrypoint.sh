#!/bin/sh
set -eu

# Copy viewer to the data volume so it can be served alongside feed.xml.
cp /app/public/index.html /data/index.html

# Run once on start so /data/feed.xml exists immediately.
echo "running initial scrape…"
/app/bin/scrape || echo "initial scrape failed (continuing to cron loop)"

# Generate crontab from $CRON_SCHEDULE.
CRONTAB=/tmp/crontab
echo "${CRON_SCHEDULE} /app/bin/scrape" > "$CRONTAB"
echo "starting supercronic with schedule: ${CRON_SCHEDULE}"
exec supercronic "$CRONTAB"
