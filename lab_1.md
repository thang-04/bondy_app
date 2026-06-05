# BÀI KIỂM TRA LAB — SPRING CLOUD MICROSERVICES

**Spring Boot 4.x + MS SQL Server**  
**Thời gian:** 90 phút

## 1. Mục tiêu & Tổng quan

Sau khi hoàn thành bài lab, sinh viên có thể:

- Khởi tạo và cấu hình Microservice độc lập với Spring Boot 4.x kết nối MS SQL Server.
- Đăng ký và khám phá service qua Eureka Discovery Server.
- Thực hiện inter-service communication bằng Spring Cloud OpenFeign.
- Thiết kế đúng cấu trúc entity, schema SQL Server và REST API với input/output rõ ràng.
- Cấu hình Spring Cloud Gateway làm entry point, định tuyến và ghi log request.

### Kiến trúc tổng quan

```text
Eureka Server :9001
        |
        v
API Gateway :8080
      /     \
     v       v
Student Service :8081
DB: lab01_students

Course Service :8082
DB: lab01_courses
```

**Thứ tự khởi chạy:**

1. Eureka Server (9001)
2. Student Service (8081)
3. Course Service (8082)
4. API Gateway (8080)

---

## 2. Bảng điểm tổng hợp

| Thành phần | Điểm |
|------------|-------|
| Student Service | 40 |
| Course Service | 40 |
| API Gateway | 20 |

---

# 3. Student Service (40 điểm)

**Port:** 8081  
**Database:** lab01_students  
**Application Name:** student-service

**Tên dự án:**

```text
TênLớp_MSSV_StudentService
```

---

## 3.1 Khởi tạo project & cấu hình SQL Server

### Dependencies

- spring-boot-starter-web
- spring-boot-starter-data-jpa
- mssql-jdbc
- spring-cloud-starter-netflix-eureka-client
- spring-boot-starter-validation

### application.yml

```yaml
server:
  port: 8081

spring:
  application:
    name: student-service

  datasource:
    url: jdbc:sqlserver://localhost:1433;databaseName=lab01_students
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver

  jpa:
    hibernate:
      ddl-auto: update
    database-platform: org.hibernate.dialect.SQLServerDialect
```

Tạo database:

```sql
CREATE DATABASE lab01_students;
```

Thêm:

```java
@EnableDiscoveryClient
```

Service phải đăng ký thành công trên Eureka Dashboard.

---

## 3.2 Entity Student

### Bảng students

| Field | Column | Type | Constraint |
|---------|---------|---------|---------|
| id | id | BIGINT | PK, IDENTITY(1,1) |
| studentCode | student_code | NVARCHAR(20) | NOT NULL, UNIQUE |
| fullName | full_name | NVARCHAR(150) | NOT NULL |
| email | email | NVARCHAR(200) | NOT NULL, UNIQUE |
| phone | phone | NVARCHAR(20) | NULL |
| major | major | NVARCHAR(100) | NOT NULL |
| gpa | gpa | DECIMAL(3,2) | CHECK(0-4) |
| status | status | NVARCHAR(20) | DEFAULT ACTIVE |
| createdAt | created_at | DATETIME2 | DEFAULT GETDATE() |
| updatedAt | updated_at | DATETIME2 | NULL |

### Validation

```java
@NotBlank
@Email
@DecimalMin("0")
@DecimalMax("4")
```

### Repository

```java
public interface StudentRepository
        extends JpaRepository<Student, Long> {

    Optional<Student> findByStudentCode(String studentCode);

}
```

---

## 3.3 REST API Student

### GET /api/students

Query params:

```text
major=<string>
status=ACTIVE|INACTIVE|GRADUATED
page=0
size=20
```

Response:

```json
[
  {
    "id": 1,
    "studentCode": "SV001",
    "fullName": "Nguyen Van A",
    "email": "a@gmail.com",
    "major": "SE",
    "gpa": 3.5,
    "status": "ACTIVE"
  }
]
```

HTTP: `200`

---

### GET /api/students/{id}

Response:

```json
{
  "id": 1,
  "studentCode": "SV001",
  "fullName": "Nguyen Van A",
  "email": "a@gmail.com",
  "phone": "0123456789",
  "major": "SE",
  "gpa": 3.5,
  "status": "ACTIVE",
  "createdAt": "2025-01-01"
}
```

HTTP:

```text
200 / 404
```

---

### GET /api/students/code/{code}

Dùng cho Feign.

HTTP:

```text
200 / 404
```

---

### POST /api/students

Request:

```json
{
  "studentCode": "SV001",
  "fullName": "Nguyen Van A",
  "email": "a@gmail.com",
  "phone": "0123456789",
  "major": "SE"
}
```

HTTP:

```text
201 / 400 / 409
```

---

### PUT /api/students/{id}

Không cho sửa:

```text
studentCode
```

Request:

```json
{
  "fullName": "Nguyen Van A",
  "email": "a@gmail.com",
  "phone": "0123456789",
  "major": "SE",
  "gpa": 3.8,
  "status": "ACTIVE"
}
```

HTTP:

```text
200 / 404
```

---

### DELETE /api/students/{id}

Soft Delete:

```text
status = INACTIVE
```

Response:

```json
{
  "message": "Student deactivated"
}
```

HTTP:

```text
200 / 404
```

---

## 3.4 Exception Handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
}
```

Format lỗi:

```json
{
  "error": "Conflict",
  "message": "Student code already exists",
  "timestamp": "2026-06-03T10:00:00"
}
```

---

# 4. Course Service (40 điểm)

**Port:** 8082

**Database:** lab01_courses

**Tên dự án**

```text
TênLớp_MSSV_CourseService
```

---

## 4.1 Dependencies

Ngoài các dependency của Student Service, thêm:

```xml
spring-cloud-starter-openfeign
```

Main Class:

```java
@EnableFeignClients
```

---

## 4.2 Entity Course

### courses

| Field | Type |
|---------|---------|
| id | BIGINT |
| courseCode | NVARCHAR(20) UNIQUE |
| courseName | NVARCHAR(200) |
| credits | INT |
| department | NVARCHAR(100) |
| description | NVARCHAR(MAX) |
| maxStudents | INT DEFAULT 50 |
| createdAt | DATETIME2 |

---

## 4.3 Entity Enrollment

### enrollments

| Field | Type |
|---------|---------|
| id | BIGINT |
| studentId | BIGINT |
| courseId | BIGINT |
| enrolledAt | DATETIME2 |
| grade | DECIMAL(4,1) |
| status | ENROLLED / COMPLETED / DROPPED |
| note | NVARCHAR(500) |

---

### Repository Methods

```java
List<Enrollment> findByStudentId(Long studentId);

List<Enrollment> findByCourseId(Long courseId);

long countByCourseIdAndStatus(
        Long courseId,
        String status);
```

---

## 4.4 OpenFeign

```java
@FeignClient(name = "student-service")
public interface StudentClient {

    @GetMapping("/api/students/{id}")
    StudentDto getStudentById(
            @PathVariable Long id);

}
```

Kiểm tra:

- Student tồn tại
- Student ACTIVE
- Không vượt maxStudents

---

## 4.5 Course APIs

### GET /api/courses

Filter:

```text
department=<string>
page=0
size=20
```

---

### GET /api/courses/{id}

HTTP:

```text
200 / 404
```

---

### POST /api/courses

HTTP:

```text
201 / 400 / 409
```

---

## 4.6 Enrollment APIs

### POST /api/enrollments

Request:

```json
{
  "studentId": 1,
  "courseId": 1,
  "note": "Hoc lai"
}
```

Response:

```json
{
  "id": 1,
  "studentId": 1,
  "courseId": 1,
  "enrolledAt": "2025-01-01",
  "status": "ENROLLED",
  "studentName": "Nguyen Van A",
  "courseName": "Spring Boot"
}
```

HTTP:

```text
201 / 400 / 404 / 409
```

---

### GET /api/enrollments/student/{studentId}

Danh sách môn học của sinh viên.

HTTP:

```text
200
```

---

### GET /api/enrollments/course/{courseId}

Danh sách sinh viên trong môn học.

HTTP:

```text
200
```

---

### PUT /api/enrollments/{id}/grade

Request:

```json
{
  "grade": 8.5
}
```

HTTP:

```text
200 / 400 / 404
```

---

### DELETE /api/enrollments/{id}

Chỉ cho phép khi:

```text
status = ENROLLED
```

Response:

```json
{
  "message": "Enrollment dropped"
}
```

HTTP:

```text
200 / 400 / 404
```

---

# 5. API Gateway (20 điểm)

**Port:** 8080

**Tên dự án**

```text
TênLớp_MSSSV_Gateway
```

---

## Dependencies

```xml
spring-cloud-starter-gateway
spring-cloud-starter-netflix-eureka-client
spring-boot-starter-actuator
```

Không thêm:

```xml
spring-boot-starter-web
```

---

## application.yml

```yaml
spring:
  cloud:
    gateway:
      discovery:
        locator:
          enabled: true

      routes:

        - id: student-route
          uri: lb://student-service
          predicates:
            - Path=/api/students/**

        - id: course-route
          uri: lb://course-service
          predicates:
            - Path=/api/courses/**

        - id: enrollment-route
          uri: lb://course-service
          predicates:
            - Path=/api/enrollments/**
```

---

# 6. Project Structure

```text
fu.<studentId>.student.entity
fu.<studentId>.student.repository
fu.<studentId>.student.service
fu.<studentId>.student.service.impl
fu.<studentId>.student.controller
fu.<studentId>.student.dto
fu.<studentId>.student.config
fu.<studentId>.student.common
```

Áp dụng tương tự cho:

```text
course
gateway
```

---

# 7. Hướng dẫn kỹ thuật

## MSSQL Driver

```xml
<dependency>
    <groupId>com.microsoft.sqlserver</groupId>
    <artifactId>mssql-jdbc</artifactId>
    <version>12.4.2.jre11</version>
</dependency>
```

## Spring Cloud BOM

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>2025.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

## Tạo Database

```sql
CREATE DATABASE lab01_students;

CREATE DATABASE lab01_courses;
```

## Eureka

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

---

# 8. Hướng dẫn nộp bài

1. Build tất cả service:

```bash
mvn clean package -DskipTests
```

2. Test toàn bộ API qua Gateway.

3. Eureka hiển thị đủ:

```text
student-service
course-service
api-gateway
```

4. Nén source:

```text
TênLớp_MSSV_Lab01.zip
```

5. Kèm README.md:

- Môi trường
- SQL Server setup
- Thứ tự chạy
- API examples

6. Nộp lên Edunext trước khi hết giờ.