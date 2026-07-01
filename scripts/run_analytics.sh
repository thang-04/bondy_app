#!/bin/bash
# =====================================================================
# Script chạy giả lập Analytics tự động với số lượng user ngẫu nhiên
# Dành cho VPS Ubuntu (Chạy hàng ngày qua Cron Job)
# =====================================================================

# ---- TỰ ĐỘNG LẤY ĐƯỜNG DẪN THƯ MỤC CHỨA SCRIPT ----
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="$PROJECT_DIR/run.log"

# Di chuyển vào thư mục chứa script
cd "$PROJECT_DIR" || exit

# ---- RANDOM SỐ LƯỢNG USER ----
USER_OPTIONS=(30 50 60)
RANDOM_INDEX=$(( RANDOM % ${#USER_OPTIONS[@]} ))
SELECTED_USERS=${USER_OPTIONS[$RANDOM_INDEX]}

# Tính toán các tham số
BATCH_SIZE=8
WAIT_TIME=900 # 15 phút chờ mỗi batch (vì mỗi tab giờ chạy ~13.6 phút)

# ---- BẮT ĐẦU LOG ----
echo "" >> "$LOG_FILE"
echo "============================================================" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 BẮT ĐẦU ĐỢT CHẠY MỚI" >> "$LOG_FILE"
echo "  Users: ${SELECTED_USERS} | Batch: ${BATCH_SIZE} | Wait: ${WAIT_TIME}s" >> "$LOG_FILE"
echo "  Thư mục: ${PROJECT_DIR}" >> "$LOG_FILE"
echo "------------------------------------------------------------" >> "$LOG_FILE"

# Ghi nhận thời gian bắt đầu
START_TIME=$(date +%s)

# ---- CHẠY SCRIPT PYTHON ----
python3 analytics_boost_v2.py --headless --users "$SELECTED_USERS" --batch "$BATCH_SIZE" --wait "$WAIT_TIME" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

# Tính thời gian chạy
END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))
MINUTES=$(( DURATION / 60 ))
SECONDS=$(( DURATION % 60 ))

# ---- KẾT QUẢ LOG ----
echo "------------------------------------------------------------" >> "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ HOÀN THÀNH" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ LỖI (exit code: $EXIT_CODE)" >> "$LOG_FILE"
fi
echo "  Thời gian chạy: ${MINUTES} phút ${SECONDS} giây" >> "$LOG_FILE"
echo "  Ước tính events: ~$(( SELECTED_USERS * 63 ))" >> "$LOG_FILE"
echo "============================================================" >> "$LOG_FILE"
