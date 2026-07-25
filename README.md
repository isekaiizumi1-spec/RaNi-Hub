# RaNi-Hub 
# 📱 Mobile Optimized Roblox Script

> **Mục đích:** Nghiên cứu toán hình học không gian (Vector2/Vector3), tương tác hệ thống CFrame trên Roblox Studio.  
> Script được tối ưu hóa hiệu năng cao cho thiết bị di động (Mobile) để tránh tụt FPS.

---

## 🚀 Tính năng chính

### Tab Combat
| Tính năng | Mô tả |
|-----------|-------|
| **Auto Aim Head (Rage)** | Khóa góc nhìn (Camera.CFrame) lập tức vào bộ phận `Head` của kẻ địch gần tâm màn hình nhất. |
| **Aim Legit (Smooth)** | Di chuyển Camera mượt mà hướng vào mục tiêu bằng `CFrame:Lerp()`. |
| **Smooth Speed Slider** | Thanh kéo giá trị từ **1 đến 10**. Giá trị càng cao, di chuyển càng mượt (tỷ lệ nghịch với `lerpFactor`). |

> ⚠️ **Lưu ý:** Hai tính năng Auto Aim và Aim Legit **không thể bật cùng lúc** (độc quyền lẫn nhau).

### Tab Player
| Tính năng | Mô tả |
|-----------|-------|
| **ESP Player** | Vẽ khung Box + tên ngườichơi xung quanh ngườichơi khác bằng `Drawing.new()`. Chỉ hiển thị khi bật. |
| **POV/FOV Circle** | Vẽ vòng tròn màu xanh lá cây `Color3.fromRGB(0, 255, 0)` cố định ở tâm màn hình. |
| **FOV Radius Slider** | Thanh kéo chỉnh bán kính vòng tròn từ **1 đến 360** (mặc định 180). |

> 🎯 Logic Aim ở Tab Combat **chỉ kích hoạt** khi kẻ địch nằm bên trong vòng tròn POV này.

---

## 🏗️ Cấu trúc 
mã nguồn
