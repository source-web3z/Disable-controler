local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera
local screenSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)

local parentGui = (gethui and gethui()) or CoreGui

local ScreenGui = parentGui:FindFirstChild("MinotifyGui")
if not ScreenGui then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MinotifyGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = parentGui
end

local Container = ScreenGui:FindFirstChild("ToastContainer")
if not Container then
    Container = Instance.new("Frame")
    Container.Name = "ToastContainer"
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = ScreenGui
end

local function HexToColor(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

local activeToasts = rawget(_G, "Minotify_ActiveToasts")
if not activeToasts then
    activeToasts = {}
    _G.Minotify_ActiveToasts = activeToasts
end

local MAX_TOASTS = 5
local TOAST_WIDTH = 310
local TOAST_GAP = 8
local PADDING = 20

local function UpdateToastPositions(corner)
    local isTop = corner:match("^Top") ~= nil
    local isRight = corner:match("Right$") ~= nil

    local currentY = isTop and PADDING or (screenSize.Y - PADDING)

    for i = #activeToasts, 1, -1 do
        if not activeToasts[i] or not activeToasts[i].Parent then
            table.remove(activeToasts, i)
        end
    end

    for i = 1, #activeToasts do
        local toast = activeToasts[i]
        if toast and toast.Parent then
            local targetHeight = toast.Size.Y.Offset
            if toast.AbsoluteSize.Y > 0 then
                targetHeight = toast.AbsoluteSize.Y
            end
            
            if not isTop then
                currentY = currentY - targetHeight
            end

            local targetX = isRight and (screenSize.X - TOAST_WIDTH - PADDING) or PADDING
            local targetPos = UDim2.new(0, targetX, 0, currentY)

            pcall(function()
                local moveTween = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos})
                moveTween:Play()
            end)

            if isTop then
                currentY = currentY + targetHeight + TOAST_GAP
            else
                currentY = currentY - TOAST_GAP
            end
        end
    end
end

local function RemoveToast(wrapper, corner)
    if not wrapper or not wrapper.Parent or wrapper:GetAttribute("Closing") then return end
    wrapper:SetAttribute("Closing", true)

    local idx = table.find(activeToasts, wrapper)
    if idx then 
        table.remove(activeToasts, idx) 
    end

    local isRight = corner:match("Right$") ~= nil
    local outX = isRight and (TOAST_WIDTH + 50) or -(TOAST_WIDTH + 50)

    pcall(function()
        local slideOut = TweenService:Create(wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(wrapper.Position.X.Scale, wrapper.Position.X.Offset + outX, wrapper.Position.Y.Scale, wrapper.Position.Y.Offset),
            BackgroundTransparency = 1
        })
        
        for _, child in ipairs(wrapper:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
        end

        slideOut:Play()
        slideOut.Completed:Wait()
    end)

    if wrapper and wrapper.Parent then
        wrapper:Destroy()
    end

    UpdateToastPositions(corner)
end

local function Minotify(options)
    task.spawn(function()
        options = options or {}
        local titleText = options.Title or "#####################################"
        local descText = options.Content or options.Cont or "####################"
        local iconId = options.Icon or "rbxassetid://126085287453932"
        local duration = options.Duration or 3
        local corner = options.Corner or "TopRight"

        local isTop = corner:match("^Top") ~= nil
        local isRight = corner:match("Right$") ~= nil

        if #activeToasts >= MAX_TOASTS then
            local oldestWrapper = activeToasts[1]
            if oldestWrapper then
                task.spawn(RemoveToast, oldestWrapper, corner)
            end
        end

        local textMaxWidth = TOAST_WIDTH - 74
        local descBounds = TextService:GetTextSize(descText, 14, Enum.Font.Code, Vector2.new(textMaxWidth, 1000))
        local descHeight = math.max(20, descBounds.Y)
        local totalHeight = math.max(64, 36 + descHeight + 10)

        local Wrapper = Instance.new("Frame")
        Wrapper.Name = "ToastWrapper"
        Wrapper.Size = UDim2.new(0, TOAST_WIDTH, 0, totalHeight)
        Wrapper.BackgroundTransparency = 1
        Wrapper.Parent = Container

        local startX = isRight and (screenSize.X + 50) or (-TOAST_WIDTH - 50)
        local startY = isTop and (-totalHeight - 20) or (screenSize.Y + 20)
        
        Wrapper.Position = UDim2.new(0, startX, 0, startY)

        if isTop then
            table.insert(activeToasts, Wrapper)
        else
            table.insert(activeToasts, 1, Wrapper)
        end

        local OuterBorder = Instance.new("Frame")
        OuterBorder.Name = "OuterBorder"
        OuterBorder.Size = UDim2.new(1, 0, 1, 0)
        OuterBorder.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        OuterBorder.BorderSizePixel = 0
        OuterBorder.Parent = Wrapper

        local OuterCorner = Instance.new("UICorner")
        OuterCorner.CornerRadius = UDim.new(0, 6)
        OuterCorner.Parent = OuterBorder

        local GrayFrame = Instance.new("Frame")
        GrayFrame.Size = UDim2.new(1, -4, 1, -4)
        GrayFrame.Position = UDim2.new(0, 2, 0, 2)
        GrayFrame.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
        GrayFrame.BorderSizePixel = 0
        GrayFrame.Parent = OuterBorder

        local GrayCorner = Instance.new("UICorner")
        GrayCorner.CornerRadius = UDim.new(0, 5)
        GrayCorner.Parent = GrayFrame

        local InnerBg = Instance.new("Frame")
        InnerBg.Size = UDim2.new(1, -6, 1, -6)
        InnerBg.Position = UDim2.new(0, 3, 0, 3)
        InnerBg.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        InnerBg.BorderSizePixel = 0
        InnerBg.Parent = GrayFrame

        local InnerCorner = Instance.new("UICorner")
        InnerCorner.CornerRadius = UDim.new(0, 4)
        InnerCorner.Parent = InnerBg

        -- ==================== THANH LOADING THỜI GIAN ====================
        local TimerBarBg = Instance.new("Frame")
        TimerBarBg.Size = UDim2.new(1, -8, 0, 3)
        TimerBarBg.Position = UDim2.new(0, 4, 1, -5)
        TimerBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        TimerBarBg.BorderSizePixel = 0
        TimerBarBg.ZIndex = 2
        TimerBarBg.Parent = InnerBg

        local TimerBarFill = Instance.new("Frame")
        TimerBarFill.Size = UDim2.new(1, 0, 1, 0)
        TimerBarFill.BackgroundColor3 = Color3.fromRGB(85, 255, 120) -- Màu xanh lá mặc định cho thanh loading
        TimerBarFill.BorderSizePixel = 0
        TimerBarFill.ZIndex = 3
        TimerBarFill.Parent = TimerBarBg

        local TimerBarCorner = Instance.new("UICorner")
        TimerBarCorner.CornerRadius = UDim.new(1, 0)
        TimerBarCorner.Parent = TimerBarFill
        -- ===============================================================

        local ClickButton = Instance.new("TextButton")
        ClickButton.Size = UDim2.new(1, 0, 1, 0)
        ClickButton.BackgroundTransparency = 1
        ClickButton.Text = ""
        ClickButton.AutoButtonColor = false
        ClickButton.ZIndex = 4
        ClickButton.Parent = InnerBg

        local Icon = Instance.new("ImageLabel")
        Icon.Size = UDim2.new(0, 36, 0, 36)
        Icon.Position = UDim2.new(0, 10, 0.5, -18)
        Icon.BackgroundTransparency = 1
        Icon.Image = iconId
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.Parent = InnerBg

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -64, 0, 22)
        TitleLabel.Position = UDim2.new(0, 54, 0, 7)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = titleText
        TitleLabel.Font = Enum.Font.Code
        TitleLabel.TextSize = 16
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = InnerBg

        if options.ChangeColor and options.ChangeColor.Title then
            local customColor = HexToColor(options.ChangeColor.Title)
            TitleLabel.TextColor3 = customColor or Color3.fromRGB(85, 255, 85)
        else
            TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            local TitleGradient = Instance.new("UIGradient")
            TitleGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 255, 85)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 130, 255))
            })
            TitleGradient.Parent = TitleLabel
        end

        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -64, 0, descHeight)
        DescLabel.Position = UDim2.new(0, 54, 0, 29)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = descText
        DescLabel.Font = Enum.Font.Code
        DescLabel.TextSize = 14
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextYAlignment = Enum.TextYAlignment.Top
        DescLabel.TextWrapped = true
        DescLabel.Parent = InnerBg

        local contentHex = options.ChangeColor and (options.ChangeColor.Cont or options.ChangeColor.Content)
        if contentHex then
            local customColor = HexToColor(contentHex)
            DescLabel.TextColor3 = customColor or Color3.fromRGB(255, 140, 0)
        else
            DescLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            local DescGradient = Instance.new("UIGradient")
            DescGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 140, 0)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 230, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 200, 255)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 80, 160))
            })
            DescGradient.Parent = DescLabel
        end

        UpdateToastPositions(corner)

        -- Chạy hiệu ứng thu nhỏ thanh loading đúng bằng số giây Duration
        local loadTween = TweenService:Create(TimerBarFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0)
        })
        loadTween:Play()

        local dismissed = false
        local function dismiss()
            if dismissed then return end
            dismissed = true
            loadTween:Cancel()
            RemoveToast(Wrapper, corner)
        end

        ClickButton.MouseButton1Click:Connect(dismiss)

        task.delay(duration, function()
            dismiss()
        end)
    end)
end

return Minotify