-- ============================================
-- Dating Matching & Healing App
-- MySQL 8.0 DDL Schema
-- Version: 1.0.0
-- ============================================

-- Create database
CREATE DATABASE IF NOT EXISTS dating_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE dating_app;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  account_status ENUM('active', 'suspended', 'deleted') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_users_email (email),
  INDEX idx_users_status (account_status),
  INDEX idx_users_created (created_at)
) ENGINE=InnoDB;

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE profiles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender ENUM('male', 'female', 'non-binary', 'other') NOT NULL,
  orientation ENUM('straight', 'gay', 'lesbian', 'bisexual', 'queer', 'other') NOT NULL,
  bio TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  location_city VARCHAR(100),
  relationship_goal ENUM('casual', 'dating', 'serious', 'marriage') NOT NULL,
  interests JSON,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_profiles_user (user_id),
  INDEX idx_profiles_gender (gender),
  INDEX idx_profiles_goal (relationship_goal),
  INDEX idx_profiles_visible (is_visible),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- PHOTOS TABLE
-- ============================================
CREATE TABLE photos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  profile_id BIGINT UNSIGNED NOT NULL,
  url VARCHAR(500) NOT NULL,
  moderation_status ENUM('approved', 'pending', 'rejected') NOT NULL DEFAULT 'pending',
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_photos_profile (profile_id),
  INDEX idx_photos_status (moderation_status),
  FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- MATCHING PREFERENCES TABLE
-- ============================================
CREATE TABLE matching_preferences (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  min_age INT NOT NULL DEFAULT 18,
  max_age INT NOT NULL DEFAULT 50,
  max_distance_km INT NOT NULL DEFAULT 50,
  preferred_genders JSON,
  preferred_goals JSON,
  deal_breakers JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_mprefs_user (user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- COMPATIBILITY SCORES TABLE
-- ============================================
CREATE TABLE compatibility_scores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_a_id BIGINT UNSIGNED NOT NULL,
  user_b_id BIGINT UNSIGNED NOT NULL,
  score DECIMAL(5, 2) NOT NULL,
  factors JSON,
  calculated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_scores_pair (user_a_id, user_b_id),
  INDEX idx_scores_user_a (user_a_id),
  INDEX idx_scores_user_b (user_b_id),
  INDEX idx_scores_score (score),
  FOREIGN KEY (user_a_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_b_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- LIKES TABLE
-- ============================================
CREATE TABLE likes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  source_user_id BIGINT UNSIGNED NOT NULL,
  target_user_id BIGINT UNSIGNED NOT NULL,
  action ENUM('like', 'pass') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_likes_pair_action (source_user_id, target_user_id, action),
  INDEX idx_likes_source (source_user_id),
  INDEX idx_likes_target (target_user_id),
  INDEX idx_likes_created (created_at),
  FOREIGN KEY (source_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- MATCHES TABLE
-- ============================================
CREATE TABLE matches (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_a_id BIGINT UNSIGNED NOT NULL,
  user_b_id BIGINT UNSIGNED NOT NULL,
  user_a_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
  user_b_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
  status ENUM('pending', 'confirmed', 'expired', 'unmatched') NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_matches_pair (user_a_id, user_b_id),
  INDEX idx_matches_user_a (user_a_id),
  INDEX idx_matches_user_b (user_b_id),
  INDEX idx_matches_status (status),
  INDEX idx_matches_expires (expires_at),
  FOREIGN KEY (user_a_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_b_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- CONVERSATIONS TABLE
-- ============================================
CREATE TABLE conversations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  match_id BIGINT UNSIGNED NOT NULL,
  status ENUM('active', 'archived', 'deleted') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_convs_match (match_id),
  INDEX idx_convs_status (status),
  FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- CONVERSATION MEMBERS TABLE
-- ============================================
CREATE TABLE conversation_members (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_read_at TIMESTAMP NULL,
  unread_count INT NOT NULL DEFAULT 0,
  UNIQUE INDEX idx_cmembers_conv_user (conversation_id, user_id),
  INDEX idx_cmembers_user (user_id),
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE TABLE messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  type ENUM('text', 'emoji', 'image', 'voice', 'ai_suggestion') NOT NULL DEFAULT 'text',
  content TEXT NOT NULL,
  delivery_status ENUM('sent', 'delivered', 'seen') NOT NULL DEFAULT 'sent',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_msgs_conv (conversation_id),
  INDEX idx_msgs_sender (sender_id),
  INDEX idx_msgs_type (type),
  INDEX idx_msgs_status (delivery_status),
  INDEX idx_msgs_created (created_at),
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- AI USAGE TABLE
-- ============================================
CREATE TABLE ai_usage (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  usage_date DATE NOT NULL,
  count INT NOT NULL DEFAULT 0,
  `limit` INT NOT NULL DEFAULT 10,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_ai_usage_user_date (user_id, usage_date),
  INDEX idx_ai_usage_date (usage_date),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE subscriptions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  tier ENUM('free', 'plus', 'premium', 'elite') NOT NULL DEFAULT 'free',
  status ENUM('active', 'cancelled', 'expired') NOT NULL DEFAULT 'active',
  start_date DATE NOT NULL,
  end_date DATE,
  is_mock BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX idx_subs_user (user_id),
  INDEX idx_subs_tier (tier),
  INDEX idx_subs_status (status),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- HEALING CHECK-INS TABLE
-- ============================================
CREATE TABLE healing_check_ins (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  mood VARCHAR(50),
  readiness VARCHAR(50),
  emotional_needs TEXT,
  triggers TEXT,
  small_goal TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_hcheck_user (user_id),
  INDEX idx_hcheck_created (created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- AFFILIATE COURSES TABLE
-- ============================================
CREATE TABLE affiliate_courses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  affiliate_url VARCHAR(500) NOT NULL,
  disclaimer TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_acourses_category (category),
  INDEX idx_acourses_active (is_active)
) ENGINE=InnoDB;

-- ============================================
-- REPORTS TABLE
-- ============================================
CREATE TABLE reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_id BIGINT UNSIGNED NOT NULL,
  target_user_id BIGINT UNSIGNED,
  target_type ENUM('user', 'profile', 'conversation', 'message') NOT NULL,
  reason VARCHAR(100) NOT NULL,
  evidence JSON,
  status ENUM('pending', 'reviewed', 'resolved') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  INDEX idx_reports_reporter (reporter_id),
  INDEX idx_reports_target_user (target_user_id),
  INDEX idx_reports_status (status),
  INDEX idx_reports_created (created_at),
  FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- MODERATION LOGS TABLE
-- ============================================
CREATE TABLE moderation_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(50) NOT NULL,
  target_id BIGINT NOT NULL,
  reason TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_mlogs_admin (admin_id),
  INDEX idx_mlogs_target (target_type, target_id),
  INDEX idx_mlogs_created (created_at),
  FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TRIGGERS FOR AUDIT LOGGING
-- ============================================

-- Trigger for user creation
DELIMITER //
CREATE TRIGGER trg_users_after_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  INSERT INTO moderation_logs (admin_id, action, target_type, target_id, reason)
  VALUES (NEW.id, 'USER_CREATED', 'user', NEW.id, 'New user registered');
END//
DELIMITER ;

-- Trigger for match creation
DELIMITER //
CREATE TRIGGER trg_matches_after_insert
AFTER INSERT ON matches
FOR EACH ROW
BEGIN
  INSERT INTO moderation_logs (admin_id, action, target_type, target_id, reason)
  VALUES (NEW.user_a_id, 'MATCH_CREATED', 'match', NEW.id,
    CONCAT('Match created between user ', NEW.user_a_id, ' and user ', NEW.user_b_id));
END//
DELIMITER ;

-- ============================================
-- SCHEMA VERSION
-- ============================================
CREATE TABLE schema_version (
  version INT NOT NULL PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO schema_version (version) VALUES (1);