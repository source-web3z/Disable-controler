local Minotify = loadstring([[
    local TweenService = game:GetService("TweenService")
    local TextService = game:GetService("TextService")
    local CoreGui = game:GetService("CoreGui")

    local parentGui = (gethui and gethui()) or CoreGui
    if parentGui:FindFirstChild("MinotifyGui") then
        parentGui.MinotifyGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MinotifyGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = parentGui

    local Container = Instance.new("Frame")
    Container.Name = "ToastContainer"
    Container.Size = UDim2.new(0, 320, 1, -20)
    Container.Position = UDim2.new(1, -330, 0, 10)
    Container.BackgroundTransparency = 1
    Container.Parent = ScreenGui

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Container

    local function HexToColor(hex)
        if type(hex) ~= "string" then return nil end
        hex = hex:gsub("#", "")
        if #hex ~= 6 then return nil end
        local r = tonumber(hex:sub(1, 2), 16) or 255
        local g = tonumber(hex:sub(3, 4), 16) or 255
        local b = tonumber(hex:sub(5, 6), 16) or 255
        return Color3.fromRGB(r, g, b)
    end

    local toastOrder = 0
    local activeToasts = {}
    local MAX_TOASTS = 5
    local TOAST_WIDTH = 310

    local function RemoveToast(wrapper, outerBorder)
        if not wrapper or not wrapper.Parent or wrapper:GetAttribute("Closing") then return end
        wrapper:SetAttribute("Closing", true)

        local idx = table.find(activeToasts, wrapper)
        if idx then table.remove(activeToasts, idx) end

        local slideOut = TweenService:Create(outerBorder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, TOAST_WIDTH + 40, 0, 0)})
        slideOut:Play()
        slideOut.Completed:Wait()

        local collapse = TweenService:Create(wrapper, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, TOAST_WIDTH, 0, 0)})
        collapse:Play()
        collapse.Completed:Wait()

        wrapper:Destroy()
    end

    local function Minotify(options)
        options = options or {}
        local titleText = options.Title or "Thông báo"
        local descText = options.Content or options.Cont or ""
        local iconId = options.Icon or "rbxassetid://6031094678"
        local duration = options.Duration or 3

        if #activeToasts >= MAX_TOASTS then
            local oldestWrapper = activeToasts[1]
            if oldestWrapper and oldestWrapper:FindFirstChild("OuterBorder") then
                task.spawn(RemoveToast, oldestWrapper, oldestWrapper.OuterBorder)
            end
        end

        toastOrder -= 1

        local textMaxWidth = TOAST_WIDTH - 74
        local descBounds = TextService:GetTextSize(descText, 14, Enum.Font.Code, Vector2.new(textMaxWidth, 1000))
        local descHeight = math.max(20, descBounds.Y)
        local totalHeight = math.max(64, 36 + descHeight + 10)

        local Wrapper = Instance.new("Frame")
        Wrapper.Name = "ToastWrapper"
        Wrapper.Size = UDim2.new(0, TOAST_WIDTH, 0, totalHeight)
        Wrapper.BackgroundTransparency = 1
        Wrapper.ClipsDescendants = true
        Wrapper.LayoutOrder = toastOrder
        Wrapper.Parent = Container

        table.insert(activeToasts, Wrapper)

        local OuterBorder = Instance.new("Frame")
        OuterBorder.Name = "OuterBorder"
        OuterBorder.Size = UDim2.new(1, 0, 1, 0)
        OuterBorder.Position = UDim2.new(0, TOAST_WIDTH + 40, 0, 0)
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

        local slideIn = TweenService:Create(OuterBorder, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
        slideIn:Play()

        task.delay(duration, function()
            RemoveToast(Wrapper, OuterBorder)
        end)
    end

    return Minotify
]])()

-- Test thử ngay lập tức
Minotify({
    Title = "Thành công",
    Content = "Đã loadstring thành công!",
    Duration = 3
})
