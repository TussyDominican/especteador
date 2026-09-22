--[[
    SCAMMER - TUSSY
    Cliente espectador con navegacion Q/E, avisos de amigos y telemetria.

    Debe ejecutarse como LocalScript.
    Roblox no expone el modelo de CPU ni la RAM fisica del dispositivo.
    El panel muestra FPS, ping, memoria usada por Roblox, plataforma y calidad grafica.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("ScammerTussy")
if existingGui then
    existingGui:Destroy()
end

local THEME = {
    background = Color3.fromRGB(8, 8, 9),
    surface = Color3.fromRGB(15, 15, 17),
    surfaceRaised = Color3.fromRGB(22, 22, 25),
    surfaceHover = Color3.fromRGB(31, 31, 35),
    selected = Color3.fromRGB(48, 48, 54),
    border = Color3.fromRGB(62, 62, 68),
    borderStrong = Color3.fromRGB(105, 105, 112),
    text = Color3.fromRGB(238, 238, 240),
    textMuted = Color3.fromRGB(150, 150, 158),
    textDim = Color3.fromRGB(98, 98, 106),
    status = Color3.fromRGB(205, 205, 210),
}

local currentTarget = nil
local playerList = {}
local isSpectating = false
local isMinimized = false
local isDragging = false
local dragStart = nil
local panelStart = nil
local frameCounter = 0
local measuredFps = 0
local fpsElapsed = 0
local updatePlayerList
local stopSpectate

local function new(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left),
        PaddingRight = UDim.new(0, right),
        PaddingTop = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
    }, parent)
end

local function tween(instance, properties, duration)
    local animation = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local screenGui = new("ScreenGui", {
    Name = "ScammerTussy",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 20,
}, playerGui)

local mainPanel = new("Frame", {
    Name = "MainPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(400, 590),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = THEME.background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, screenGui)
corner(mainPanel, 6)
stroke(mainPanel, THEME.borderStrong, 0.25, 1)

new("UISizeConstraint", {
    MinSize = Vector2.new(340, 520),
    MaxSize = Vector2.new(440, 650),
}, mainPanel)

local topBar = new("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = THEME.surface,
    BorderSizePixel = 0,
    Active = true,
}, mainPanel)

new("Frame", {
    Name = "TopRule",
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = THEME.text,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
}, topBar)

local brand = new("TextLabel", {
    Size = UDim2.new(1, -104, 0, 28),
    Position = UDim2.fromOffset(16, 10),
    BackgroundTransparency = 1,
    Text = "SCAMMER - TUSSY",
    TextColor3 = THEME.text,
    Font = Enum.Font.RobotoMono,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

new("TextLabel", {
    Size = UDim2.new(1, -104, 0, 18),
    Position = UDim2.fromOffset(16, 37),
    BackgroundTransparency = 1,
    Text = "SPECTATOR CONTROL / SESSION ACTIVE",
    TextColor3 = THEME.textDim,
    Font = Enum.Font.RobotoMono,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

local function createWindowButton(name, label, xOffset)
    local button = new("TextButton", {
        Name = name,
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, xOffset, 0, 18),
        BackgroundColor3 = THEME.surfaceRaised,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = THEME.textMuted,
        Font = Enum.Font.RobotoMono,
        TextSize = 14,
        AutoButtonColor = false,
    }, topBar)
    corner(button, 4)
    stroke(button, THEME.border, 0.25, 1)
    button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = THEME.surfaceHover, TextColor3 = THEME.text }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = THEME.surfaceRaised, TextColor3 = THEME.textMuted }, 0.12)
    end)
    return button
end

local minimizeButton = createWindowButton("Minimize", "_", -76)
local closeButton = createWindowButton("Close", "X", -40)

local content = new("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -24, 1, -82),
    Position = UDim2.fromOffset(12, 74),
    BackgroundTransparency = 1,
}, mainPanel)

local sessionRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = THEME.surface,
    BorderSizePixel = 0,
}, content)
corner(sessionRow, 4)
stroke(sessionRow, THEME.border, 0.45, 1)

local statusDot = new("Frame", {
    Size = UDim2.fromOffset(7, 7),
    Position = UDim2.new(0, 13, 0.5, -3),
    BackgroundColor3 = THEME.textDim,
    BorderSizePixel = 0,
}, sessionRow)
corner(statusDot, 7)

local statusText = new("TextLabel", {
    Size = UDim2.new(1, -42, 1, 0),
    Position = UDim2.fromOffset(30, 0),
    BackgroundTransparency = 1,
    Text = "WAITING FOR TARGET",
    TextColor3 = THEME.textMuted,
    Font = Enum.Font.RobotoMono,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, sessionRow)

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.fromOffset(2, 48),
    BackgroundTransparency = 1,
    Text = "CONNECTED PLAYERS",
    TextColor3 = THEME.textDim,
    Font = Enum.Font.RobotoMono,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

local listContainer = new("Frame", {
    Size = UDim2.new(1, 0, 0, 205),
    Position = UDim2.fromOffset(0, 68),
    BackgroundColor3 = THEME.surface,
    BorderSizePixel = 0,
}, content)
corner(listContainer, 4)
stroke(listContainer, THEME.border, 0.45, 1)

local scrollList = new("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.fromOffset(5, 5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = THEME.borderStrong,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, listContainer)
padding(scrollList, 1, 4, 1, 1)
local listLayout = new("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, scrollList)

local navigation = new("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    Position = UDim2.fromOffset(0, 281),
    BackgroundColor3 = THEME.surface,
    BorderSizePixel = 0,
}, content)
corner(navigation, 4)
stroke(navigation, THEME.border, 0.45, 1)

local function createNavButton(name, text, position)
    local button = new("TextButton", {
        Name = name,
        Size = UDim2.new(0.36, 0, 1, -10),
        Position = position,
        BackgroundColor3 = THEME.surfaceRaised,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = THEME.textMuted,
        Font = Enum.Font.RobotoMono,
        TextSize = 11,
        AutoButtonColor = false,
    }, navigation)
    corner(button, 3)
    button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = THEME.surfaceHover, TextColor3 = THEME.text }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = THEME.surfaceRaised, TextColor3 = THEME.textMuted }, 0.12)
    end)
    return button
end

local previousButton = createNavButton("Previous", "[Q] PREVIOUS", UDim2.new(0, 5, 0, 5))
local nextButton = createNavButton("Next", "NEXT [E]", UDim2.new(0.64, -5, 0, 5))
local navigationLabel = new("TextLabel", {
    Size = UDim2.new(0.28, 0, 1, 0),
    Position = UDim2.new(0.36, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "00 / 00",
    TextColor3 = THEME.text,
    Font = Enum.Font.RobotoMono,
    TextSize = 11,
}, navigation)

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.fromOffset(2, 334),
    BackgroundTransparency = 1,
    Text = "LOCAL TELEMETRY",
    TextColor3 = THEME.textDim,
    Font = Enum.Font.RobotoMono,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

local telemetry = new("Frame", {
    Size = UDim2.new(1, 0, 0, 82),
    Position = UDim2.fromOffset(0, 354),
    BackgroundColor3 = THEME.surface,
    BorderSizePixel = 0,
}, content)
corner(telemetry, 4)
stroke(telemetry, THEME.border, 0.45, 1)

local telemetryGrid = new("UIGridLayout", {
    CellSize = UDim2.new(0.5, -5, 0, 32),
    CellPadding = UDim2.fromOffset(6, 6),
    FillDirectionMaxCells = 2,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, telemetry)
telemetryGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
telemetryGrid.VerticalAlignment = Enum.VerticalAlignment.Center

local metricValues = {}
local function createMetric(order, key, label)
    local cell = new("Frame", {
        LayoutOrder = order,
        BackgroundColor3 = THEME.surfaceRaised,
        BorderSizePixel = 0,
    }, telemetry)
    corner(cell, 3)
    new("TextLabel", {
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.fromOffset(9, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = THEME.textDim,
        Font = Enum.Font.RobotoMono,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, cell)
    metricValues[key] = new("TextLabel", {
        Size = UDim2.new(0.52, -9, 1, 0),
        Position = UDim2.new(0.48, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "--",
        TextColor3 = THEME.text,
        Font = Enum.Font.RobotoMono,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, cell)
end

createMetric(1, "fps", "FPS")
createMetric(2, "ping", "PING")
createMetric(3, "memory", "MEMORY")
createMetric(4, "system", "SYSTEM")

local actions = new("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    Position = UDim2.fromOffset(0, 446),
    BackgroundTransparency = 1,
}, content)

local function createActionButton(name, text, position, size)
    local button = new("TextButton", {
        Name = name,
        Size = size,
        Position = position,
        BackgroundColor3 = THEME.surfaceRaised,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = THEME.text,
        Font = Enum.Font.RobotoMono,
        TextSize = 11,
        AutoButtonColor = false,
    }, actions)
    corner(button, 4)
    stroke(button, THEME.borderStrong, 0.35, 1)
    button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = THEME.selected }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = THEME.surfaceRaised }, 0.12)
    end)
    return button
end

local spectateButton = createActionButton("Spectate", "START", UDim2.fromOffset(0, 0), UDim2.new(0.42, -4, 1, 0))
local stopButton = createActionButton("Stop", "STOP", UDim2.new(0.42, 4, 0, 0), UDim2.new(0.36, -4, 1, 0))
local refreshButton = createActionButton("Refresh", "SYNC", UDim2.new(0.78, 4, 0, 0), UDim2.new(0.22, -4, 1, 0))

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 15),
    Position = UDim2.fromOffset(2, 496),
    BackgroundTransparency = 1,
    Text = "CPU/RAM HARDWARE ACCESS: RESTRICTED BY ROBLOX",
    TextColor3 = THEME.textDim,
    Font = Enum.Font.RobotoMono,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

local notifications = new("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.fromOffset(330, 420),
    Position = UDim2.new(1, -18, 0, 18),
    BackgroundTransparency = 1,
}, screenGui)
new("UIListLayout", {
    Padding = UDim.new(0, 8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, notifications)

local notificationOrder = 0
local function showNotification(title, primaryText, secondaryText, userId, duration)
    notificationOrder = notificationOrder + 1
    local card = new("Frame", {
        LayoutOrder = notificationOrder,
        Size = UDim2.fromOffset(0, 82),
        BackgroundColor3 = THEME.background,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, notifications)
    corner(card, 5)
    stroke(card, THEME.borderStrong, 0.2, 1)

    local avatar = new("ImageLabel", {
        Size = UDim2.fromOffset(50, 50),
        Position = UDim2.fromOffset(12, 16),
        BackgroundColor3 = THEME.surfaceRaised,
        BorderSizePixel = 0,
        Image = "",
    }, card)
    corner(avatar, 4)

    new("TextLabel", {
        Size = UDim2.new(1, -84, 0, 18),
        Position = UDim2.fromOffset(74, 11),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = THEME.textDim,
        Font = Enum.Font.RobotoMono,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    new("TextLabel", {
        Size = UDim2.new(1, -84, 0, 22),
        Position = UDim2.fromOffset(74, 29),
        BackgroundTransparency = 1,
        Text = primaryText,
        TextColor3 = THEME.text,
        Font = Enum.Font.RobotoMono,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    new("TextLabel", {
        Size = UDim2.new(1, -84, 0, 17),
        Position = UDim2.fromOffset(74, 51),
        BackgroundTransparency = 1,
        Text = secondaryText,
        TextColor3 = THEME.textMuted,
        Font = Enum.Font.RobotoMono,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    if userId then
        task.spawn(function()
            local ok, image = pcall(function()
                return Players:GetUserThumbnailAsync(
                    userId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size150x150
                )
            end)
            if ok and card.Parent then
                avatar.Image = image
            end
        end)
    end

    card.Position = UDim2.fromOffset(340, 0)
    tween(card, { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(330, 82) }, 0.28)
    task.delay(duration or 5, function()
        if card.Parent then
            tween(card, { Position = UDim2.fromOffset(340, 0), BackgroundTransparency = 1 }, 0.25)
            task.wait(0.27)
            if card.Parent then card:Destroy() end
        end
    end)
end

local function setStatus(text, active)
    statusText.Text = string.upper(text)
    statusText.TextColor3 = active and THEME.text or THEME.textMuted
    statusDot.BackgroundColor3 = active and THEME.status or THEME.textDim
end

local function getPlayerIndex(target)
    for index, candidate in ipairs(playerList) do
        if candidate == target then
            return index
        end
    end
    return nil
end

local function highlightTarget()
    for _, child in ipairs(scrollList:GetChildren()) do
        if child:IsA("TextButton") then
            local selected = currentTarget and child.Name == "Player_" .. currentTarget.UserId
            tween(child, {
                BackgroundColor3 = selected and THEME.selected or THEME.surfaceRaised,
                TextColor3 = selected and THEME.text or THEME.textMuted,
            }, 0.12)
        end
    end
end

local function attachCamera(target)
    local character = target and target.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local camera = workspace.CurrentCamera
    if not camera then
        return false
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    return true
end

local function navigateTo(index)
    if #playerList == 0 then return end
    if index < 1 then index = #playerList end
    if index > #playerList then index = 1 end

    currentTarget = playerList[index]
    navigationLabel.Text = string.format("%02d / %02d", index, #playerList)
    setStatus((isSpectating and "Viewing: " or "Selected: ") .. currentTarget.DisplayName, isSpectating)
    highlightTarget()

    if isSpectating and not attachCamera(currentTarget) then
        setStatus("Target character unavailable", false)
    end
end

local function nextPlayer()
    if #playerList == 0 then return end
    navigateTo((getPlayerIndex(currentTarget) or 0) + 1)
end

local function previousPlayer()
    if #playerList == 0 then return end
    navigateTo((getPlayerIndex(currentTarget) or 2) - 1)
end

local function startSpectate()
    if not currentTarget then
        setStatus("Select a target", false)
        return
    end
    if not attachCamera(currentTarget) then
        setStatus("Target character unavailable", false)
        return
    end
    isSpectating = true
    spectateButton.Text = "ACTIVE"
    setStatus("Viewing: " .. currentTarget.DisplayName, true)
    highlightTarget()
end

stopSpectate = function(message)
    local camera = workspace.CurrentCamera
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        if humanoid then camera.CameraSubject = humanoid end
    end
    isSpectating = false
    spectateButton.Text = "START"
    setStatus(message or "Spectator stopped", false)
end

updatePlayerList = function()
    local previousTarget = currentTarget
    for _, child in ipairs(scrollList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    playerList = {}
    for _, candidate in ipairs(Players:GetPlayers()) do
        if candidate ~= localPlayer then
            table.insert(playerList, candidate)
        end
    end
    table.sort(playerList, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)

    for index, candidate in ipairs(playerList) do
        local button = new("TextButton", {
            Name = "Player_" .. candidate.UserId,
            LayoutOrder = index,
            Size = UDim2.new(1, -2, 0, 38),
            BackgroundColor3 = THEME.surfaceRaised,
            BorderSizePixel = 0,
            Text = "   " .. candidate.DisplayName .. "  /  @" .. candidate.Name,
            TextColor3 = THEME.textMuted,
            Font = Enum.Font.RobotoMono,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
        }, scrollList)
        corner(button, 3)

        local healthDot = new("Frame", {
            Size = UDim2.fromOffset(5, 5),
            Position = UDim2.new(1, -14, 0.5, -2),
            BackgroundColor3 = THEME.textDim,
            BorderSizePixel = 0,
        }, button)
        corner(healthDot, 5)

        local humanoid = candidate.Character and candidate.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            healthDot.BackgroundColor3 = THEME.text
        end

        button.MouseEnter:Connect(function()
            if candidate ~= currentTarget then
                tween(button, { BackgroundColor3 = THEME.surfaceHover }, 0.1)
            end
        end)
        button.MouseLeave:Connect(function()
            if candidate ~= currentTarget then
                tween(button, { BackgroundColor3 = THEME.surfaceRaised }, 0.1)
            end
        end)
        button.MouseButton1Click:Connect(function()
            local targetIndex = getPlayerIndex(candidate)
            if targetIndex then navigateTo(targetIndex) end
        end)
    end

    if #playerList == 0 then
        currentTarget = nil
        navigationLabel.Text = "00 / 00"
        setStatus("No targets connected", false)
        if isSpectating then stopSpectate("Target disconnected") end
        return
    end

    local preservedIndex = getPlayerIndex(previousTarget)
    navigateTo(preservedIndex or 1)
end

local function detectSystem()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "MOBILE"
    elseif GuiService:IsTenFootInterface() then
        return "CONSOLE"
    elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        return "GAMEPAD"
    end
    return "DESKTOP"
end

local function getPing()
    local ok, value = pcall(function()
        local network = Stats:FindFirstChild("Network")
        local serverStats = network and network:FindFirstChild("ServerStatsItem")
        local pingItem = serverStats and serverStats:FindFirstChild("Data Ping")
        return pingItem and pingItem:GetValueString() or "N/A"
    end)
    return ok and value or "N/A"
end

local function updateTelemetry()
    metricValues.fps.Text = tostring(math.max(0, math.floor(measuredFps + 0.5)))
    metricValues.ping.Text = getPing()
    local ok, memory = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
    metricValues.memory.Text = ok and string.format("%.0f MB", memory) or "N/A"
    metricValues.system.Text = detectSystem()
end

RunService.RenderStepped:Connect(function(deltaTime)
    frameCounter = frameCounter + 1
    fpsElapsed = fpsElapsed + deltaTime
    if fpsElapsed >= 0.5 then
        measuredFps = frameCounter / fpsElapsed
        frameCounter = 0
        fpsElapsed = 0
        updateTelemetry()
    end

    if isSpectating and currentTarget then
        local character = currentTarget.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            stopSpectate("Target unavailable")
        end
    end
end)

local function handlePlayerAdded(joinedPlayer)
    updatePlayerList()
    task.spawn(function()
        local ok, isFriend = pcall(function()
            return localPlayer:IsFriendsWith(joinedPlayer.UserId)
        end)
        if ok and isFriend then
            showNotification(
                "FRIEND CONNECTED",
                joinedPlayer.DisplayName,
                "@" .. joinedPlayer.Name .. " joined the server",
                joinedPlayer.UserId,
                6
            )
        end
    end)
end

local function handlePlayerRemoving(leavingPlayer)
    if currentTarget == leavingPlayer then
        currentTarget = nil
        if isSpectating then stopSpectate("Target disconnected") end
    end
    task.defer(updatePlayerList)
end

Players.PlayerAdded:Connect(handlePlayerAdded)
Players.PlayerRemoving:Connect(handlePlayerRemoving)

localPlayer.CharacterAdded:Connect(function()
    if isSpectating then stopSpectate("Local character restored") end
end)

previousButton.MouseButton1Click:Connect(previousPlayer)
nextButton.MouseButton1Click:Connect(nextPlayer)
spectateButton.MouseButton1Click:Connect(startSpectate)
stopButton.MouseButton1Click:Connect(function() stopSpectate() end)
refreshButton.MouseButton1Click:Connect(function()
    refreshButton.Text = "..."
    updatePlayerList()
    task.delay(0.25, function()
        if refreshButton.Parent then refreshButton.Text = "SYNC" end
    end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        previousPlayer()
    elseif input.KeyCode == Enum.KeyCode.E then
        nextPlayer()
    end
end)

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        panelStart = mainPanel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not isDragging or not dragStart or not panelStart then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        mainPanel.Position = UDim2.new(
            panelStart.X.Scale,
            panelStart.X.Offset + delta.X,
            panelStart.Y.Scale,
            panelStart.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    content.Visible = not isMinimized
    minimizeButton.Text = isMinimized and "+" or "_"
    tween(mainPanel, { Size = isMinimized and UDim2.fromOffset(400, 66) or UDim2.fromOffset(400, 590) }, 0.22)
end)

closeButton.MouseButton1Click:Connect(function()
    if isSpectating then stopSpectate() end
    tween(mainPanel, {
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
    }, 0.2)
    task.wait(0.22)
    screenGui:Destroy()
end)

updatePlayerList()
updateTelemetry()

local finalSize = mainPanel.Size
mainPanel.Size = UDim2.fromOffset(0, 0)
tween(mainPanel, { Size = finalSize }, 0.35)
showNotification(
    "SYSTEM READY",
    "SCAMMER - TUSSY",
    "Q / E navigation enabled",
    localPlayer.UserId,
    4
)

print("SCAMMER - TUSSY / spectator client initialized")
