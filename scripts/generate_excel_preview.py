import csv
import random
import unicodedata

MALE_NAMES = ["Hải", "Long", "Minh", "Khoa", "Anh", "Tuấn", "Nam", "Việt", "Hoàng", "Sơn", "Huy", "Cường", "Duy", "Thành", "Đức"]
FEMALE_NAMES = ["Lan", "Mai", "Hoa", "Linh", "Trang", "Nhung", "Vy", "Hương", "Hà", "Ngọc", "Thu", "Tâm", "Thảo", "My", "Yến"]
LAST_NAMES = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"]
MIDDLE_NAMES_M = ["Văn", "Đăng", "Gia", "Thanh", "Bảo", "Tuấn", "Hoàng", "Đình", "Nhật", "Quang"]
MIDDLE_NAMES_F = ["Thị", "Ngọc", "Thu", "Phương", "Bảo", "Thanh", "Diễm", "Kiều", "Hồng", "Kim"]

NICKNAMES = ["Bé Bự", "Cún", "Mèo lười", "Gấu", "Sunshine", "Alex", "Mia", "Kevin", "Zoe", "Ryan", "Emma", "Tom", "Mây", "Nắng", "Gió", "Mít", "Bơ", "Sóc", "Nhím"]
ADJECTIVES = ["Cute", "Cool", "Vui Vẻ", "Bé Bỏng", "Ngốc", "Kute", "Lạnh Lùng"]

HOBBIES = ["Đọc sách", "Thể thao", "Nghe nhạc", "Du lịch", "Mua sắm", "Xem phim", "Chơi game", "Nấu ăn", "Chụp ảnh", "Thú cưng", "Cà phê", "Cắm trại"]
ZODIACS = ["Bạch Dương", "Kim Ngưu", "Song Tử", "Cự Giải", "Sư Tử", "Xử Nữ", "Thiên Bình", "Thiên Yết", "Nhân Mã", "Ma Kết", "Bảo Bình", "Song Ngư"]
CITIES = ["Hà Nội", "Hồ Chí Minh", "Đà Nẵng", "Cần Thơ", "Hải Phòng"]
DATING_GOALS = ["Mối quan hệ nghiêm túc", "Hẹn hò vui vẻ", "Tìm bạn bè mới", "Chưa xác định", "Tìm người trò chuyện"]
PARTNER_TYPES = ["Người biết lắng nghe", "Có khiếu hài hước", "Trưởng thành", "Lạc quan", "Sở thích tương đồng", "Yêu động vật", "Thông minh"]
FREE_TIME_SLOTS = ["Sáng (08:00 - 12:00)", "Chiều (13:00 - 17:00)", "Tối (18:00 - 22:00)", "Cuối tuần"]

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

HEALING_COURSES = ["7 Ngày Yêu Bản Thân", "Thấu Hiểu Cảm Xúc", "Thiền Định Cơ Bản", "Chữa Lành Tổn Thương", "Quản Lý Stress"]
MOODS = ["Vui vẻ (Happy)", "Bình yên (Calm)", "Năng lượng (Energetic)", "Hơi buồn (Sad)", "Mệt mỏi (Tired)", "Biết ơn (Grateful)"]

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
    if choice <= 40:
        return first_name
    elif choice <= 65:
        return random.choice(NICKNAMES)
    elif choice <= 80:
        return f"{first_name}{str(b_year)[-2:]}"
    elif choice <= 90:
        return f"{first_name} {random.choice(ADJECTIVES)}"
    else:
        return f"{first_name} {random.choice(['A.', 'B.', 'C.', 'T.', 'V.'])}"

def generate_preview():
    filename = "mock_users_preview_v4.csv"
    with open(filename, mode='w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        headers = [
            "STT", "Email", "Hồ Sơ (Full Name)", "Tên Hiển Thị", 
            "Giới Tính", "Tuổi", "Thành Phố", 
            "Bio (Giới thiệu)", "Sở Thích", "Cung Hoàng Đạo", 
            "Tổng Lượt Like", "Tổng Lượt Pass", "Dự Kiến Match", 
            "Đoạn Chat Mẫu (Thả Thính)", "Khóa Học Healing (Nếu có)", "Bài Học Đang Dở", "Check-in Cảm Xúc"
        ]
        writer.writerow(headers)
        
        users = []
        # Generate 50 Males
        for i in range(1, 51):
            last = random.choice(LAST_NAMES)
            mid = random.choice(MIDDLE_NAMES_M)
            first = random.choice(MALE_NAMES)
            full_name = f"{last} {mid} {first}"
            
            dob, b_year = random_dob()
            email = generate_email(full_name, b_year)
            display_name = generate_display_name(first, b_year)
            
            city = random.choice(CITIES)
            bio = f"Xin chào, mình là {display_name}."
            hobs = ", ".join(random.sample(HOBBIES, random.randint(2, 4)))
            zodiac = random.choice(ZODIACS)
            
            # Swipes
            likes = random.randint(15, 20)
            passes = random.randint(30, 40)
            matches = random.randint(3, 5)
            
            # Chat sample
            chat_sample = f"User: {random.choice(FLIRTY_MESSAGES_MALE)}"
            
            # Healing (30% chance)
            is_healing = random.random() < 0.3
            course = random.choice(HEALING_COURSES) if is_healing else "Không tham gia"
            lesson = f"Bài {random.randint(2, 4)}" if is_healing else ""
            mood = random.choice(MOODS) if is_healing else ""
            
            users.append([
                i, email, full_name, display_name, "Nam", 2026 - b_year, city, 
                bio, hobs, zodiac, 
                likes, passes, matches, 
                chat_sample, course, lesson, mood
            ])
            
        # Generate 40 Females
        for i in range(1, 41):
            last = random.choice(LAST_NAMES)
            mid = random.choice(MIDDLE_NAMES_F)
            first = random.choice(FEMALE_NAMES)
            full_name = f"{last} {mid} {first}"
            
            dob, b_year = random_dob()
            email = generate_email(full_name, b_year)
            display_name = generate_display_name(first, b_year)
            
            city = random.choice(CITIES)
            bio = f"Hello mọi người, gọi mình là {display_name} nhé!"
            hobs = ", ".join(random.sample(HOBBIES, random.randint(2, 4)))
            zodiac = random.choice(ZODIACS)
            
            # Swipes
            likes = random.randint(15, 20)
            passes = random.randint(30, 40)
            matches = random.randint(3, 5)
            
            # Chat sample
            chat_sample = f"User: {random.choice(FLIRTY_MESSAGES_FEMALE)}"
            
            # Healing (30% chance)
            is_healing = random.random() < 0.3
            course = random.choice(HEALING_COURSES) if is_healing else "Không tham gia"
            lesson = f"Bài {random.randint(2, 4)}" if is_healing else ""
            mood = random.choice(MOODS) if is_healing else ""
            
            users.append([
                50 + i, email, full_name, display_name, "Nữ", 2026 - b_year, city, 
                bio, hobs, zodiac, 
                likes, passes, matches, 
                chat_sample, course, lesson, mood
            ])
            
        writer.writerows(users)
    print(f"Generated {filename}")

if __name__ == "__main__":
    generate_preview()
