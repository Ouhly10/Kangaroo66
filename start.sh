#!/bin/bash
echo "=== Kangaroo Starting ==="

# إرسال إشعار تليغرام
if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT_ID}" \
        -d text="🦘 Kangaroo بدأ - Puzzle #${PUZZLE}" \
        -d parse_mode="Markdown"
fi

# التحقق من وجود الملف
if [ ! -f "/opt/Kangaroo/kangaroo" ]; then
    echo "ERROR: kangaroo binary not found!"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT_ID}" \
        -d text="❌ خطأ: ملف kangaroo غير موجود"
    sleep infinity
fi

echo "Binary found, starting search..."

/opt/Kangaroo/kangaroo \
    -d ${DP:-16} \
    -t ${WORKERS:-4} \
    -o /workspace/results/found.txt \
    ${PUBKEY}
