--[[
    ============================================
    MOBILE OPTIMIZED SCRIPT - ROBLOX
    Mục đích: Nghiên cứu Vector2/Vector3, CFrame, Hình học không gian
    ============================================
]]

-- ═══════════════════════════════════════════════════════
-- 1. KHAI BÁO DỊCH VỤ HỆ THỐNG (Local Variables - Tối ưu truy xuất)
-- ═══════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════
-- 2. LOAD RAYFIELD GEN2 UI LIBRARY
-- ═══════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- ═══════════════════════════════════════════════════════
-- 3. TẠO CỬA SỔ UI CHÍNH
-- ═══════════════════════════════════════════════════════
local window = Rayfield:CreateWindow({
    name = "Mobile Hub",
    subtitle = "Optimized for Mobile",
})

-- ═══════════════════════════════════════════════════════
-- 4. TẠO 2 TAB: COMBAT & PLAYER
-- ═══════════════════════════════════════════════════════
local combatTab = window:CreateTab({ name = "Combat", icon = 0 })
local playerTab = window:CreateTab({ name = "Player", icon = 0 })

-- ═══════════════════════════════════════════════════════
-- 5. BIẾN TRẠNG THÁI (State Variables)
-- ═══════════════════════════════════════════════════════
local isRageAimEnabled = false
local isSmoothAimEnabled = false
local isEspEnabled = false
local isFovCircleEnabled = false

local smoothAimSpeed = 5        -- Giá trị mặc định (1-10, càng cao càng mượt)
local fovRadius = 180           -- Bán kính vòng tròn FOV (1-360)

-- Biến lưu trữ Drawing objects & Connections (để cleanup)
local fovCircle = nil
local espDrawings = {}          -- Bảng lưu các đối tượng Drawing ESP
local espConnections = {}       -- Bảng lưu các connections ESP
local aimConnection = nil       -- Connection cho Aim loop
local espLoopConnection = nil   -- Connection cho ESP loop

-- ═══════════════════════════════════════════════════════
-- 6. HÀM TIỆN ÍCH (Utility Functions)
-- ═══════════════════════════════════════════════════════

-- Kiểm tra tính hợp lệ của mục tiêu (Clean validation)
local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player or not player.Character then return false end
    
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not humanoid or not hrp or not head then return false end
    if humanoid.Health <= 0 then return false end
    
    return true
end

-- Chuyển đổi Vector3 thế giới sang Vector2 màn hình
local function worldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Tính khoảng cách từ điểm đến tâm màn hình
local function getDistanceToCenter(screenPos)
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (screenPos - viewportCenter).Magnitude
end

-- Kiểm tra xem vị trí màn hình có nằm trong vòng tròn FOV không
local function isInFov(screenPos)
    if not isFovCircleEnabled or not fovCircle then return true end
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (screenPos - viewportCenter).Magnitude <= fovRadius
end

-- Tìm mục tiêu gần tâm màn hình nhất và nằm trong FOV
local function getClosestTargetToCenter()
    local closestPlayer = nil
    local closestDistance = math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local head = player.Character.Head
            local screenPos, onScreen = worldToScreen(head.Position)
            
            if onScreen and isInFov(screenPos) then
                local distance = getDistanceToCenter(screenPos)
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- ═══════════════════════════════════════════════════════
-- 7. FOV CIRCLE (Drawing)
-- ═══════════════════════════════════════════════════════
local function createFovCircle()
    if fovCircle then return end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = true
    fovCircle.Thickness = 1.5
    fovCircle.Color = Color3.fromRGB(0, 255, 0)  -- Xanh lá cây
    fovCircle.Transparency = 0.7
    fovCircle.Filled = false
    fovCircle.NumSides = 64
    fovCircle.Radius = fovRadius
end

local function updateFovCircle()
    if not fovCircle then return end
    
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Position = viewportCenter
    fovCircle.Radius = fovRadius
    fovCircle.Visible = isFovCircleEnabled
end

local function removeFovCircle()
    if fovCircle then
        fovCircle:Remove()
        fovCircle = nil
    end
end

-- ═══════════════════════════════════════════════════════
-- 8. ESP PLAYER (Drawing Box/Highlight)
-- ═══════════════════════════════════════════════════════
local function createEspForPlayer(player)
    if espDrawings[player] then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 0, 0)  -- Đỏ
    box.Transparency = 0.8
    box.Filled = false
    
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Size = 14
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Outline = true
    nameText.Center = true
    
    espDrawings[player] = {
        box = box,
        nameText = nameText
    }
end

local function updateEspForPlayer(player)
    local drawings = espDrawings[player]
    if not drawings then return end
    
    if not isEspEnabled or not isValidTarget(player) then
        drawings.box.Visible = false
        drawings.nameText.Visible = false
        return
    end
    
    local character = player.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not hrp or not head then
        drawings.box.Visible = false
        drawings.nameText.Visible = false
        return
    end
    
    -- Tính toán vị trí box
    local headPos, headOnScreen = worldToScreen(head.Position + Vector3.new(0, 0.5, 0))
    local footPos, footOnScreen = worldToScreen(hrp.Position - Vector3.new(0, 3, 0))
    
    if headOnScreen and footOnScreen then
        local boxHeight = math.abs(footPos.Y - headPos.Y)
        local boxWidth = boxHeight * 0.6
        
        drawings.box.Size = Vector2.new(boxWidth, boxHeight)
        drawings.box.Position = Vector2.new(headPos.X - boxWidth / 2, headPos.Y)
        drawings.box.Visible = true
        
        drawings.nameText.Text = player.Name
        drawings.nameText.Position = Vector2.new(headPos.X, headPos.Y - 20)
        drawings.nameText.Visible = true
    else
        drawings.box.Visible = false
        drawings.nameText.Visible = false
    end
end

local function cleanupEsp()
    -- Ngắt kết nối loop
    if espLoopConnection then
        espLoopConnection:Disconnect()
        espLoopConnection = nil
    end
    
    -- Xóa tất cả Drawing objects
    for player, drawings in pairs(espDrawings) do
        if drawings.box then drawings.box:Remove() end
        if drawings.nameText then drawings.nameText:Remove() end
    end
    espDrawings = {}
    
    -- Ngắt kết nối sự kiện PlayerRemoving
    for _, conn in ipairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
end

local function startEsp()
    -- Tạo ESP cho tất cả người chơi hiện tại
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createEspForPlayer(player)
        end
    end
    
    -- Lắng nghe người chơi mới vào
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            createEspForPlayer(player)
        end
    end)
    table.insert(espConnections, playerAddedConn)
    
    -- Lắng nghe người chơi rời đi để dọn dẹp
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        if espDrawings[player] then
            if espDrawings[player].box then espDrawings[player].box:Remove() end
            if espDrawings[player].nameText then espDrawings[player].nameText:Remove() end
            espDrawings[player] = nil
        end
    end)
    table.insert(espConnections, playerRemovingConn)
    
    -- RenderStepped loop cho ESP (đồng bộ với khung hình)
    espLoopConnection = RunService.RenderStepped:Connect(function()
        if not isEspEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updateEspForPlayer(player)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 9. AIM LOGIC (Rage & Smooth)
-- ═══════════════════════════════════════════════════════
local function startAimLoop()
    if aimConnection then return end
    
    aimConnection = RunService.RenderStepped:Connect(function()
        if not isRageAimEnabled and not isSmoothAimEnabled then return end
        
        local target = getClosestTargetToCenter()
        if not target then return end
        
        local head = target.Character:FindFirstChild("Head")
        if not head then return end
        
        if isRageAimEnabled then
            -- Rage Aim: Khóa ngay lập tức vào đầu
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        elseif isSmoothAimEnabled then
            -- Smooth Aim: Di chuyển mượt mà
            -- Giá trị slider càng CAO -> Lerp càng gần 0 (càng mượt)
            -- Slider 1 -> Lerp 0.5, Slider 10 -> Lerp 0.05
            local lerpFactor = 0.55 - (smoothAimSpeed * 0.05)  -- 1->0.50, 10->0.05
            lerpFactor = math.clamp(lerpFactor, 0.01, 0.5)
            
            local targetCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lerpFactor)
        end
    end)
end

local function stopAimLoop()
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════
-- 10. TAB COMBAT - UI ELEMENTS
-- ═══════════════════════════════════════════════════════

-- Toggle: Auto Aim Head (Rage)
combatTab:CreateToggle({
    name = "Auto Aim Head (Rage)",
    callback = function(value)
        isRageAimEnabled = value
        
        -- Logic độc quyền: Nếu bật Rage thì tắt Smooth
        if value and isSmoothAimEnabled then
            isSmoothAimEnabled = false
            -- Cập nhật lại UI toggle smooth (nếu cần, Rayfield Gen2 tự lưu state)
        end
        
        if isRageAimEnabled or isSmoothAimEnabled then
            startAimLoop()
        else
            stopAimLoop()
        end
    end,
})

-- Toggle: Aim Legit (Smooth)
combatTab:CreateToggle({
    name = "Aim Legit (Smooth)",
    callback = function(value)
        isSmoothAimEnabled = value
        
        -- Logic độc quyền: Nếu bật Smooth thì tắt Rage
        if value and isRageAimEnabled then
            isRageAimEnabled = false
        end
        
        if isRageAimEnabled or isSmoothAimEnabled then
            startAimLoop()
        else
            stopAimLoop()
        end
    end,
})

-- Slider: Smooth Speed (1-10, càng cao càng mượt)
combatTab:CreateSlider({
    name = "Smooth Speed",
    range = {1, 10},
    increment = 1,
    suffix = "Level",
    currentValue = 5,
    callback = function(value)
        smoothAimSpeed = value
    end,
})

-- ═══════════════════════════════════════════════════════
-- 11. TAB PLAYER - UI ELEMENTS
-- ═══════════════════════════════════════════════════════

-- Toggle: ESP Player
playerTab:CreateToggle({
    name = "ESP Player",
    callback = function(value)
        isEspEnabled = value
        if value then
            startEsp()
        else
            cleanupEsp()
        end
    end,
})

-- Toggle: POV/FOV Circle
playerTab:CreateToggle({
    name = "FOV Circle",
    callback = function(value)
        isFovCircleEnabled = value
        if value then
            createFovCircle()
            -- Cập nhật vị trí vòng tròn mỗi frame
            if not fovCircle then
                fovCircle = Drawing.new("Circle")
                fovCircle.Thickness = 1.5
                fovCircle.Color = Color3.fromRGB(0, 255, 0)
                fovCircle.Transparency = 0.7
                fovCircle.Filled = false
                fovCircle.NumSides = 64
            end
            -- Kết nối cập nhật vị trí
            RunService.RenderStepped:Connect(function()
                if fovCircle and isFovCircleEnabled then
                    updateFovCircle()
                end
            end)
        else
            removeFovCircle()
        end
    end,
})

-- Slider: FOV Radius (1-360, mặc định 180)
playerTab:CreateSlider({
    name = "FOV Radius",
    range = {1, 360},
    increment = 1,
    suffix = "px",
    currentValue = 180,
    callback = function(value)
        fovRadius = value
        if fovCircle then
            fovCircle.Radius = value
        end
    end,
})

-- ═══════════════════════════════════════════════════════
-- 12. NÚT ẢO MOBILE (Mobile Toggle Button)
-- ═══════════════════════════════════════════════════════
local mobileToggleButton = Instance.new("ScreenGui")
mobileToggleButton.Name = "MobileToggle"
mobileToggleButton.ResetOnSpawn = false
mobileToggleButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Parent vào CoreGui hoặc PlayerGui
if syn and syn.protect_gui then
    syn.protect_gui(mobileToggleButton)
    mobileToggleButton.Parent = CoreGui
else
    mobileToggleButton.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local toggleFrame = Instance.new("Frame")
toggleFrame.Name = "ToggleFrame"
toggleFrame.Size = UDim2.new(0, 60, 0, 60)
toggleFrame.Position = UDim2.new(0, 20, 0.5, -30)  -- Góc trái, giữa màn hình
toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleFrame.BackgroundTransparency = 0.3
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = mobileToggleButton

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)  -- Hình tròn
corner.Parent = toggleFrame

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Name = "Label"
toggleLabel.Size = UDim2.new(1, 0, 1, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "☰"
toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLabel.TextSize = 24
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.Parent = toggleFrame

-- Tính năng kéo thả nút (Draggable)
local dragging = false
local dragStartPos = nil
local frameStartPos = nil

toggleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        frameStartPos = toggleFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
        toggleFrame.Position = UDim2.new(
            frameStartPos.X.Scale, 
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, 
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Toggle UI khi bấm nút
toggleFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Kiểm tra không phải đang kéo (drag distance nhỏ)
        if dragStartPos then
            local endPos = Vector2.new(input.Position.X, input.Position.Y)
            if (endPos - dragStartPos).Magnitude < 5 then  -- Nếu di chuyển < 5px thì coi là click
                local isVisible = Rayfield:IsVisible()
                Rayfield:SetVisibility(not isVisible)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- 13. DỌN DẸP KHI SCRIPT BỊ HỦY (Cleanup)
-- ═══════════════════════════════════════════════════════
LocalPlayer.CharacterRemoving:Connect(function()
    stopAimLoop()
    cleanupEsp()
    removeFovCircle()
    if mobileToggleButton then
        mobileToggleButton:Destroy()
    end
end)

-- ═══════════════════════════════════════════════════════
-- 14. THÔNG BÁO KHI LOAD THÀNH CÔNG
-- ═══════════════════════════════════════════════════════
Rayfield:Notify({
    title = "Mobile Hub",
    content = "Script loaded successfully! Tap ☰ to toggle UI.",
    duration = 5,
})
