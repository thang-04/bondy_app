import requests
import random
import time
import unicodedata
import sys

# Force utf-8 printing for Windows
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://103.149.86.25:3000/api"

MALE_NAMES = ["Hải", "Long", "Minh", "Khoa", "Anh", "Tuấn", "Nam", "Việt", "Hoàng", "Sơn", "Huy", "Cường", "Duy", "Thành", "Đức"]
FEMALE_NAMES = ["Lan", "Mai", "Hoa", "Linh", "Trang", "Nhung", "Vy", "Hương", "Hà", "Ngọc", "Thu", "Tâm", "Thảo", "My", "Yến"]
LAST_NAMES = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"]
MIDDLE_NAMES_M = ["Văn", "Đăng", "Gia", "Thanh", "Bảo", "Tuấn", "Hoàng", "Đình", "Nhật", "Quang"]
MIDDLE_NAMES_F = ["Thị", "Ngọc", "Thu", "Phương", "Bảo", "Thanh", "Diễm", "Kiều", "Hồng", "Kim"]
NICKNAMES = ["Bé Bự", "Cún", "Mèo lười", "Gấu", "Sunshine", "Alex", "Mia", "Kevin", "Zoe", "Ryan", "Emma", "Tom", "Mây", "Nắng", "Gió", "Mít", "Bơ", "Sóc", "Nhím"]
ADJECTIVES = ["Cute", "Cool", "Vui Vẻ", "Bé Bỏng", "Ngốc", "Kute", "Lạnh Lùng"]
CITIES = ["Hà Nội", "Hồ Chí Minh", "Đà Nẵng", "Cần Thơ", "Hải Phòng"]
DATING_GOALS = ["Mối quan hệ nghiêm túc", "Hẹn hò vui vẻ", "Tìm bạn bè mới", "Chưa xác định", "Tìm người trò chuyện"]
ZODIACS = ["Bạch Dương", "Kim Ngưu", "Song Tử", "Cự Giải", "Sư Tử", "Xử Nữ", "Thiên Bình", "Thiên Yết", "Nhân Mã", "Ma Kết", "Bảo Bình", "Song Ngư"]

FLIRTY_MESSAGES_MALE = [
    "Trời đổ mưa rồi, sao em chưa đổ anh?",
    "Em có bản đồ không? Anh bị lạc trong mắt em mất rồi.",
    "Hôm nay trời đẹp, đi cà phê với anh không?",
    "Nhìn em quen quen, hình như là người yêu tương lai của anh thì phải.",
    "Nụ cười của em làm anh quên cả mệt mỏi cả ngày luôn á.",
    "Anh không phải thợ săn, nhưng trái tim anh vừa bị em đánh cắp."
]

FLIRTY_MESSAGES_FEMALE = [
    "Anh ơi, Trái Đất hình tròn, sao anh đi loanh quanh mãi mà chưa vào tim em?",
    "Thính này em thả, anh có dính không thì bảo?",
    "Người ta nói con gái thích ngọt ngào, nhưng em lại thích anh.",
    "Anh có tin vào tình yêu sét đánh không, hay để em đi ngang qua lần nữa?",
    "Hôm nay em hơi mệt, anh có thể làm chỗ dựa cho em không?"
]

MOODS = ["Vui vẻ", "Bình yên", "Năng lượng", "Hơi buồn", "Mệt mỏi", "Biết ơn"]

def remove_accents(input_str):
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return u"".join([c for c in nfkd_form if not unicodedata.combining(c)])

def generate_email(full_name, dob_year):
    parts = remove_accents(full_name).lower().split()
    first = parts[-1]
    last = "".join([p[0] for p in parts[:-1]])
    
    formats = [
        f"{first}{last}{dob_year}",
        f"{first}.{last}{dob_year}",
        f"{last}{first}{str(dob_year)[-2:]}",
        f"{first}{dob_year}{last}"
    ]
    return f"{random.choice(formats)}@gmail.com"

def random_dob():
    year = random.randint(1996, 2006)
    month = random.randint(1, 12)
    day = random.randint(1, 28)
    return f"{year}-{month:02d}-{day:02d}", year

def generate_display_name(first_name, b_year):
    choice = random.randint(1, 100)
    if choice <= 40: return first_name
    elif choice <= 65: return random.choice(NICKNAMES)
    elif choice <= 80: return f"{first_name}{str(b_year)[-2:]}"
    elif choice <= 90: return f"{first_name} {random.choice(ADJECTIVES)}"
    else: return f"{first_name} {random.choice(['A.', 'B.', 'C.', 'T.', 'V.'])}"

def post_req(path, data, token=None):
    headers = {}
    if token: headers["Authorization"] = f"Bearer {token}"
    try:
        res = requests.post(f"{BASE_URL}{path}", json=data, headers=headers, timeout=10)
        return res
    except Exception as e:
        print(f"Error {path}: {e}")
        return None

def patch_req(path, data, token):
    headers = {"Authorization": f"Bearer {token}"}
    try:
        res = requests.patch(f"{BASE_URL}{path}", json=data, headers=headers, timeout=10)
        return res
    except Exception as e:
        print(f"Error {path}: {e}")
        return None

def create_user(gender):
    is_male = gender == "Nam"
    first = random.choice(MALE_NAMES if is_male else FEMALE_NAMES)
    mid = random.choice(MIDDLE_NAMES_M if is_male else MIDDLE_NAMES_F)
    last_n = random.choice(LAST_NAMES)
    full_name = f"{last_n} {mid} {first}"
    dob, b_year = random_dob()
    
    # Random suffix to guarantee uniqueness for tests
    email = generate_email(full_name, b_year).replace("@", f"{random.randint(1000,9999)}@")
    display_name = generate_display_name(first, b_year)

    print(f"Creating user {email} ({display_name})...")
    
    # 1. Send OTP
    res = post_req("/auth/send-otp", {"email": email})
    if not res or res.status_code != 200:
        return None
    dev_otp = res.json().get("devOtp")
    if not dev_otp: return None
    
    # 2. Verify OTP
    res = post_req("/auth/verify-otp", {"email": email, "otp": dev_otp})
    if not res or res.status_code != 200:
        return None
    data = res.json().get("data", {})
    token = data.get("accessToken")
    user_id = data.get("user", {}).get("id")
    if not token: return None
    
    # 3. Update Profile
    profile_data = {
        "fullName": full_name,
        "name": display_name,
        "gender": "MALE" if is_male else "FEMALE",
        "birthDate": dob,
        "city": random.choice(CITIES),
        "bio": f"Xin chào, mình là {display_name}!",
        "datingGoal": random.choice(DATING_GOALS),
        "zodiacSign": random.choice(ZODIACS),
    }
    patch_req("/profile/me", profile_data, token)

    return {"id": user_id, "token": token, "email": email, "gender": gender, "name": display_name}

def swipe(token, target_id, action="LIKE"):
    res = post_req("/swipes", {"targetUserId": target_id, "action": action}, token)
    if res and res.status_code == 200:
        d = res.json().get("data", {})
        if d.get("matched"):
            return d.get("conversationId") or d.get("matchId")
    return None

def send_chat(token, chat_id, msg):
    post_req(f"/chats/{chat_id}/messages", {"content": msg, "messageType": "TEXT"}, token)

def checkin_healing(token):
    # submit checkin
    data = {
        "mood": random.choice(MOODS),
        "readiness": "ready",
        "needs": ["Tĩnh tâm", "Nghỉ ngơi"],
        "trigger": "Không có",
        "smallGoal": "Đọc 1 trang sách"
    }
    post_req("/healing/checkin", data, token)
    
def chat_ai(token, msg, match_id):
    # simulate calling coach
    data = {
        "chatId": "ai-chat-123",
        "matchId": match_id,
        "message": msg,
        "intent": "continue"
    }
    post_req("/ai/coach/suggestions", data, token)

def main():
    print("STARTING MOCK DATA GENERATION VIA API...")
    
    m_users = []
    for _ in range(50):
        u = create_user("Nam")
        if u: m_users.append(u)
        time.sleep(0.05)
        
    f_users = []
    for _ in range(40):
        u = create_user("Nữ")
        if u: f_users.append(u)
        time.sleep(0.05)

    print(f"Success created {len(m_users)} M, {len(f_users)} F")
    
    print("SIMULATING SWIPES, MATCHES AND CHATS...")
    
    for m in m_users:
        # Men passes 20 women
        passes = random.sample(f_users, min(20, len(f_users)))
        for p in passes:
            swipe(m["token"], p["id"], "PASS")
            
        # Men likes 10 women
        likes = random.sample(f_users, min(10, len(f_users)))
        for t in likes:
            # Male likes Female
            swipe(m["token"], t["id"], "LIKE")
            
            # Female likes Male -> match (approx 30-40% chance)
            if random.random() < 0.4:
                chat_id = swipe(t["token"], m["id"], "LIKE")
                if chat_id:
                    print(f"Match formed: {m['name']} & {t['name']}")
                    # send messages
                    send_chat(m["token"], chat_id, random.choice(FLIRTY_MESSAGES_MALE))
                    time.sleep(0.1)
                    send_chat(t["token"], chat_id, random.choice(FLIRTY_MESSAGES_FEMALE))
                    time.sleep(0.1)
                    send_chat(m["token"], chat_id, "Wow, thật luôn hả? 😌")
                    
    print("SIMULATING HEALING & AI...")
    all_users = m_users + f_users
    for u in all_users:
        if random.random() < 0.3:
            checkin_healing(u["token"])
        if random.random() < 0.1:
            chat_ai(u["token"], "Giúp mình nói chuyện cho bớt nhạt", "test-match")
            
    print("DONE! Data generated successfully.")

if __name__ == "__main__":
    main()
