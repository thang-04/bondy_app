import uuid
import random
import unicodedata
from datetime import datetime, timedelta

MALE_NAMES = ["Hải", "Long", "Minh", "Khoa", "Anh", "Tuấn", "Nam", "Việt", "Hoàng", "Sơn", "Huy", "Cường", "Duy", "Thành", "Đức"]
FEMALE_NAMES = ["Lan", "Mai", "Hoa", "Linh", "Trang", "Nhung", "Vy", "Hương", "Hà", "Ngọc", "Thu", "Tâm", "Thảo", "My", "Yến"]
LAST_NAMES = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"]
MIDDLE_NAMES_M = ["Văn", "Đăng", "Gia", "Thanh", "Bảo", "Tuấn", "Hoàng", "Đình", "Nhật", "Quang"]
MIDDLE_NAMES_F = ["Thị", "Ngọc", "Thu", "Phương", "Bảo", "Thanh", "Diễm", "Kiều", "Hồng", "Kim"]
NICKNAMES = ["Bé Bự", "Cún", "Mèo lười", "Gấu", "Sunshine", "Alex", "Mia", "Kevin", "Zoe", "Ryan", "Emma", "Tom"]
ADJECTIVES = ["Cute", "Cool", "Vui Vẻ", "Bé Bỏng", "Ngốc", "Kute", "Lạnh Lùng"]
CITIES = ["Hà Nội", "Hồ Chí Minh", "Đà Nẵng", "Cần Thơ", "Hải Phòng"]
DATING_GOALS = ["Mối quan hệ nghiêm túc", "Hẹn hò vui vẻ", "Tìm bạn bè mới", "Chưa xác định", "Tìm người trò chuyện"]
ZODIACS = ["Bạch Dương", "Kim Ngưu", "Song Tử", "Cự Giải", "Sư Tử", "Xử Nữ", "Thiên Bình", "Thiên Yết", "Nhân Mã", "Ma Kết", "Bảo Bình", "Song Ngư"]

FLIRTY_MESSAGES_MALE = [
    "Trời đổ mưa rồi, sao em chưa đổ anh?",
    "Em có bản đồ không? Anh bị lạc trong mắt em mất rồi.",
    "Hôm nay trời đẹp, đi cà phê với anh không?",
    "Nụ cười của em làm anh quên cả mệt mỏi cả ngày luôn á."
]
FLIRTY_MESSAGES_FEMALE = [
    "Anh ơi, Trái Đất hình tròn, sao anh đi loanh quanh mãi mà chưa vào tim em?",
    "Thính này em thả, anh có dính không thì bảo?",
    "Người ta nói con gái thích ngọt ngào, nhưng em lại thích anh.",
    "Hôm nay em hơi mệt, anh có thể làm chỗ dựa cho em không?"
]

def remove_accents(input_str):
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return u"".join([c for c in nfkd_form if not unicodedata.combining(c)])

def gen_email(full_name, dob_year):
    parts = remove_accents(full_name).lower().split()
    first = parts[-1]
    last = "".join([p[0] for p in parts[:-1]])
    return f"{first}{last}{dob_year}{random.randint(100,999)}@gmail.com"

def gen_uuid():
    return str(uuid.uuid4())

def random_date(days_ago_start, days_ago_end):
    now = datetime.now()
    start = now - timedelta(days=days_ago_start)
    end = now - timedelta(days=days_ago_end)
    diff = end - start
    random_seconds = random.randint(0, int(diff.total_seconds()))
    return start + timedelta(seconds=random_seconds)

def escape_sql(text):
    return str(text).replace("'", "''")

def main():
    print("Generating mock_data_15_days.sql ...")
    
    with open("mock_data_15_days.sql", "w", encoding="utf-8") as f:
        f.write("-- MOCK DATA SCRIPT FOR BONDY APP (LAST 15 DAYS)\n")
        f.write("-- NOTE: Tên bảng (Table names) có thể cần điều chỉnh lại cho khớp với schema của bạn.\n\n")
        
        users = []
        # Create Users
        for i in range(90):
            is_male = i < 50
            first = random.choice(MALE_NAMES if is_male else FEMALE_NAMES)
            mid = random.choice(MIDDLE_NAMES_M if is_male else MIDDLE_NAMES_F)
            last_n = random.choice(LAST_NAMES)
            full_name = f"{last_n} {mid} {first}"
            b_year = random.randint(1996, 2006)
            email = gen_email(full_name, b_year)
            
            choice = random.randint(1, 100)
            if choice <= 40: display_name = first
            elif choice <= 65: display_name = random.choice(NICKNAMES)
            elif choice <= 80: display_name = f"{first}{str(b_year)[-2:]}"
            else: display_name = f"{first} {random.choice(ADJECTIVES)}"
            
            created_at = random_date(15, 0)
            
            user_id = gen_uuid()
            profile_id = gen_uuid()
            
            # Determine Subscription
            sub_plan = "FREE"
            r = random.random()
            if r > 0.9: sub_plan = "ELITE"
            elif r > 0.7: sub_plan = "PREMIUM"
            elif r > 0.5: sub_plan = "PLUS"
            
            users.append({
                "id": user_id, "gender": "MALE" if is_male else "FEMALE", 
                "created_at": created_at, "name": display_name, "plan": sub_plan
            })
            
            f.write(f"INSERT INTO users (id, email, name, created_at, updated_at) VALUES ('{user_id}', '{email}', '{escape_sql(display_name)}', '{created_at}', '{created_at}');\n")
            
            f.write(f"INSERT INTO profiles (id, user_id, full_name, gender, birth_date, city, dating_goal, zodiac_sign, bio, created_at, updated_at) ")
            f.write(f"VALUES ('{profile_id}', '{user_id}', '{escape_sql(full_name)}', 'MALE' if is_male else 'FEMALE', '{b_year}-05-10', '{random.choice(CITIES)}', '{random.choice(DATING_GOALS)}', '{random.choice(ZODIACS)}', 'Xin chào, mình là {escape_sql(display_name)}!', '{created_at}', '{created_at}');\n")
            
            # Insert Subscription
            sub_id = gen_uuid()
            f.write(f"INSERT INTO subscriptions (id, user_id, plan, status, start_date, created_at) VALUES ('{sub_id}', '{user_id}', '{sub_plan}', 'ACTIVE', '{created_at}', '{created_at}');\n")
            
        f.write("\n-- SWIPES & MATCHES --\n")
        males = [u for u in users if u["gender"] == "MALE"]
        females = [u for u in users if u["gender"] == "FEMALE"]
        
        matches = []
        for m in males:
            # Likes (15-20) and Passes (30-40)
            target_females = random.sample(females, min(60, len(females)))
            passes = target_females[:40]
            likes = target_females[40:]
            
            # Passes
            for f_u in passes:
                swipe_id = gen_uuid()
                sw_date = random_date(14, 0)
                if sw_date < m["created_at"]: sw_date = m["created_at"]
                f.write(f"INSERT INTO swipes (id, source_user_id, target_user_id, action, created_at) VALUES ('{swipe_id}', '{m['id']}', '{f_u['id']}', 'PASS', '{sw_date}');\n")
                
            # Likes
            for f_u in likes:
                swipe_id = gen_uuid()
                sw_date = random_date(14, 0)
                if sw_date < m["created_at"]: sw_date = m["created_at"]
                f.write(f"INSERT INTO swipes (id, source_user_id, target_user_id, action, created_at) VALUES ('{swipe_id}', '{m['id']}', '{f_u['id']}', 'LIKE', '{sw_date}');\n")
                
                # Female likes back? (success rate 20-30%)
                if random.random() < 0.25:
                    f_sw_id = gen_uuid()
                    f_sw_date = sw_date + timedelta(hours=random.randint(1, 24))
                    f.write(f"INSERT INTO swipes (id, source_user_id, target_user_id, action, created_at) VALUES ('{f_sw_id}', '{f_u['id']}', '{m['id']}', 'LIKE', '{f_sw_date}');\n")
                    
                    # Match
                    match_id = gen_uuid()
                    f.write(f"INSERT INTO matches (id, user1_id, user2_id, status, created_at) VALUES ('{match_id}', '{m['id']}', '{f_u['id']}', 'MATCHED', '{f_sw_date}');\n")
                    matches.append({"id": match_id, "m": m, "f": f_u, "date": f_sw_date})
                    
        f.write("\n-- CONVERSATIONS & MESSAGES --\n")
        for match in matches:
            conv_id = gen_uuid()
            f.write(f"INSERT INTO conversations (id, match_id, created_at) VALUES ('{conv_id}', '{match['id']}', '{match['date']}');\n")
            
            # Chat accepted? (60% chat conversion rate)
            if random.random() < 0.6:
                m_date = match['date'] + timedelta(minutes=random.randint(2, 30))
                msg1_id = gen_uuid()
                f.write(f"INSERT INTO messages (id, conversation_id, sender_id, content, created_at) VALUES ('{msg1_id}', '{conv_id}', '{match['m']['id']}', '{escape_sql(random.choice(FLIRTY_MESSAGES_MALE))}', '{m_date}');\n")
                
                m_date2 = m_date + timedelta(minutes=random.randint(1, 15))
                msg2_id = gen_uuid()
                f.write(f"INSERT INTO messages (id, conversation_id, sender_id, content, created_at) VALUES ('{msg2_id}', '{conv_id}', '{match['f']['id']}', '{escape_sql(random.choice(FLIRTY_MESSAGES_FEMALE))}', '{m_date2}');\n")
                
        f.write("\n-- AI USAGE & HEALING --\n")
        FEATURES = ["SELF_REFLECTION", "COUPLES_CORNER", "CONFLICT_RESOLUTION", "AI_COACH"]
        for u in users:
            # AI Usage
            num_ai = random.randint(0, 5)
            for _ in range(num_ai):
                ai_id = gen_uuid()
                f_type = random.choice(FEATURES)
                ai_date = random_date(14, 0)
                if ai_date < u["created_at"]: ai_date = u["created_at"]
                f.write(f"INSERT INTO ai_usages (id, user_id, feature, created_at) VALUES ('{ai_id}', '{u['id']}', '{f_type}', '{ai_date}');\n")
                
            # Healing Courses
            if random.random() < 0.4:
                c_id = gen_uuid()
                c_date = u["created_at"] + timedelta(days=1)
                f.write(f"INSERT INTO healing_courses (id, user_id, course_name, progress_percentage, created_at) VALUES ('{c_id}', '{u['id']}', '7 Ngày Yêu Bản Thân', {random.randint(10, 100)}, '{c_date}');\n")

    print("Success! File mock_data_15_days.sql has been generated.")

if __name__ == "__main__":
    main()
