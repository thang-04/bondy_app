#!/bin/bash
# =====================================================================
# Script chạy giả lập Analytics tự động với số lượng user ngẫu nhiên
# Dành cho VPS Ubuntu (Chạy hàng ngày qua Cron Job)
# =====================================================================

# ---- CẤU HÌNH ĐƯỜNG DẪN ----
# Thay đổi đường dẫn này thành thư mục chứa code của bạn trên VPS
PROJECT_DIR="/home/ubuntu/bondy_app/scripts"

# Di chuyển vào thư mục chứa script
cd "$PROJECT_DIR" || exit

# ---- RANDOM SỐ LƯỢNG USER ----
# Khai báo mảng chứa các mức user mong muốn (30, 50, 60)
USER_OPTIONS=(30 50 60)

# Chọn ngẫu nhiên một chỉ số từ mảng
RANDOM_INDEX=$(( RANDOM % ${#USER_OPTIONS[@]} ))
SELECTED_USERS=${USER_OPTIONS[$RANDOM_INDEX]}

# Tính toán số batch phù hợp (mỗi batch 8-10 tabs để không treo VPS)
BATCH_SIZE=8
WAIT_TIME=420 # 7 phút chờ mỗi batch để tăng Engagement Time lên 5-8 phút

echo "[$(date)] Bắt đầu chạy giả lập với ${SELECTED_USERS} users (Batch size: ${BATCH_SIZE})..."

# Chạy Python script ở chế độ headless
python3 analytics_boost_v2.py --headless --users "$SELECTED_USERS" --batch "$BATCH_SIZE" --wait "$WAIT_TIME"

echo "[$(date)] Hoàn thành đợt giả lập."
