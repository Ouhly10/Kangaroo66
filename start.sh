#!/bin/bash
# ============================================================
# Kangaroo Startup Script
# يدعم إعدادات التليغرام عبر متغيرات البيئة
# ============================================================

set -e

KANGAROO_BIN="/opt/Kangaroo/kangaroo"
LOG_FILE="/workspace/logs/kangaroo.log"
RESULT_FILE="/workspace/results/found.txt"

# ── قراءة الإعدادات من متغيرات البيئة ──────────────────────
# Bitcoin Puzzle settings
PUZZLE="${PUZZLE:-66}"
PUBKEY="${PUBKEY:-}"
RANGE_START="${RANGE_START:-}"
RANGE_END="${RANGE_END:-}"
DP="${DP:-16}"
WORKERS="${WORKERS:-4}"

# Telegram settings
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"

# ── التحقق من المتغيرات الأساسية ────────────────────────────
if [ -z "$PUBKEY" ]; then
    echo "[ERROR] يجب تحديد PUBKEY (المفتاح العام)"
    echo "مثال: -e PUBKEY=02abc123..."
    exit 1
fi

echo "================================================"
echo "  Kangaroo Bitcoin Puzzle Solver"
echo "================================================"
echo "  Puzzle   : #${PUZZLE}"
echo "  PubKey   : ${PUBKEY:0:20}..."
echo "  DP       : ${DP}"
echo "  Workers  : ${WORKERS}"
[ -n "$RANGE_START" ] && echo "  Range    : ${RANGE_START} → ${RANGE_END}"
echo "  Telegram : $([ -n "$TG_TOKEN" ] && echo 'مفعّل ✓' || echo 'معطّل')"
echo "================================================"

# ── إرسال إشعار بدء العمل ───────────────────────────────────
if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
    python3 /workspace/notify.py \
        --token "$TG_TOKEN" \
        --chat "$TG_CHAT_ID" \
        --msg "🦘 *Kangaroo بدأ العمل*

🔢 Puzzle: \`#${PUZZLE}\`
🔑 PubKey: \`${PUBKEY:0:16}...\`
⚙️ Workers: ${WORKERS} | DP: ${DP}
🕐 $(date '+%Y-%m-%d %H:%M:%S UTC')" &
fi

# ── بناء أمر التشغيل ─────────────────────────────────────────
CMD="$KANGAROO_BIN"

# إضافة النطاق إن وُجد
if [ -n "$RANGE_START" ] && [ -n "$RANGE_END" ]; then
    CMD="$CMD -r ${RANGE_START}:${RANGE_END}"
fi

# عدد النقاط المميزة
CMD="$CMD -d ${DP}"

# عدد الـ threads
CMD="$CMD -t ${WORKERS}"

# تسجيل النتيجة في ملف
CMD="$CMD -o ${RESULT_FILE}"

# المفتاح العام
CMD="$CMD ${PUBKEY}"

echo "[INFO] تشغيل: $CMD"
echo "[INFO] $(date) - بدأ البحث..." | tee -a "$LOG_FILE"

# ── تشغيل Kangaroo ───────────────────────────────────────────
$CMD 2>&1 | tee -a "$LOG_FILE" &
KANGAROO_PID=$!

# ── مراقبة النتيجة ───────────────────────────────────────────
monitor_result() {
    while kill -0 $KANGAROO_PID 2>/dev/null; do
        if [ -f "$RESULT_FILE" ] && [ -s "$RESULT_FILE" ]; then
            FOUND_KEY=$(cat "$RESULT_FILE")
            echo ""
            echo "================================================"
            echo "  🎉 تم العثور على المفتاح!"
            echo "  $FOUND_KEY"
            echo "================================================"

            if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
                python3 /workspace/notify.py \
                    --token "$TG_TOKEN" \
                    --chat "$TG_CHAT_ID" \
                    --msg "🎉 *تم إيجاد المفتاح!*

🔢 Puzzle: \`#${PUZZLE}\`
🗝️ Private Key:
\`\`\`
${FOUND_KEY}
\`\`\`
🕐 $(date '+%Y-%m-%d %H:%M:%S UTC')"
            fi
            break
        fi
        sleep 30
    done
}

monitor_result &

# ── إرسال تقارير دورية كل ساعة ───────────────────────────────
if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
    (
        while kill -0 $KANGAROO_PID 2>/dev/null; do
            sleep 3600
            # استخراج آخر سطر من اللوج
            LAST_LOG=$(tail -5 "$LOG_FILE" 2>/dev/null | tr '\n' ' ')
            python3 /workspace/notify.py \
                --token "$TG_TOKEN" \
                --chat "$TG_CHAT_ID" \
                --msg "📊 *تقرير دوري - Kangaroo*

🔢 Puzzle: \`#${PUZZLE}\`
🕐 $(date '+%Y-%m-%d %H:%M:%S UTC')
📋 \`${LAST_LOG:0:200}\`"
        done
    ) &
fi

# انتظار انتهاء العملية الرئيسية
wait $KANGAROO_PID
EXIT_CODE=$?

echo "[INFO] $(date) - انتهى Kangaroo بكود: $EXIT_CODE" | tee -a "$LOG_FILE"
exit $EXIT_CODE
