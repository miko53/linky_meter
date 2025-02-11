# linky_meter SERVER

```bash
export LINKY_METER_URL="http://localhost:5555"

curl ${LINKY_METER_URL}/

DATE_FROM="2025-01-01T00:00:00" \
DATE_TO="2025-02-01T00:00:00" \
curl -H "date-from:${DATE_FROM}" -H "date-to:${DATE_TO}" ${LINKY_METER_URL}/p

```
