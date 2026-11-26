--[[
    ALASHBAT | BATMAN THEMED CLIENT UI
    Cosmetic interface/demo scaffold for Roblox executor environments.
    This build intentionally contains no aimbot, triggerbot, hitbox edits,
    player tracking, or through-wall ESP.
    Toggle menu: F1
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.ALASHBAT_UNLOAD then
    pcall(env.ALASHBAT_UNLOAD)
end

local alive = true
local connections = {}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function getParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    local ok, result = pcall(function() return game:GetService("CoreGui") end)
    if ok and result then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local old = getParent():FindFirstChild("ALASHBAT")
if old then old:Destroy() end

local COLORS = {
    bg = Color3.fromRGB(7, 9, 14),
    panel = Color3.fromRGB(13, 16, 24),
    card = Color3.fromRGB(20, 24, 34),
    card2 = Color3.fromRGB(27, 32, 44),
    gold = Color3.fromRGB(235, 184, 67),
    gold2 = Color3.fromRGB(255, 220, 125),
    white = Color3.fromRGB(239, 242, 248),
    muted = Color3.fromRGB(137, 147, 164),
    red = Color3.fromRGB(213, 76, 76),
    green = Color3.fromRGB(82, 195, 133)
}

local gui = Instance.new("ScreenGui")
gui.Name = "ALASHBAT"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(gui) end
end)
gui.Parent = getParent()

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function outline(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.gold
    s.Transparency = transparency or 0.5
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function tween(obj, duration, props, style)
    local t = TweenService:Create(obj, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Two-second Batman-inspired intro (original bat mark, not an image asset).
local intro = Instance.new("Frame")
intro.Name = "Intro"
intro.Size = UDim2.fromScale(1, 1)
intro.BackgroundColor3 = COLORS.bg
intro.BackgroundTransparency = 0
intro.Parent = gui

local introGlow = Instance.new("Frame")
introGlow.AnchorPoint = Vector2.new(0.5, 0.5)
introGlow.Position = UDim2.fromScale(0.5, 0.48)
introGlow.Size = UDim2.fromOffset(230, 120)
introGlow.BackgroundColor3 = COLORS.gold
introGlow.BackgroundTransparency = 0.88
introGlow.Parent = intro
corner(introGlow, 100)

local bat = Instance.new("TextLabel")
bat.BackgroundTransparency = 1
bat.AnchorPoint = Vector2.new(0.5, 0.5)
bat.Position = UDim2.fromScale(0.5, 0.43)
bat.Size = UDim2.fromOffset(360, 150)
bat.Font = Enum.Font.GothamBlack
bat.Text = "   ᗧ ᗣ ᗤ"
bat.Text = "🦇"
bat.TextColor3 = COLORS.gold
bat.TextScaled = true
bat.TextTransparency = 1
bat.Parent = intro

local introName = Instance.new("TextLabel")
introName.BackgroundTransparency = 1
introName.AnchorPoint = Vector2.new(0.5, 0.5)
introName.Position = UDim2.fromScale(0.5, 0.61)
introName.Size = UDim2.fromOffset(420, 52)
introName.Font = Enum.Font.GothamBlack
introName.Text = "ALASHBAT"
introName.TextColor3 = COLORS.white
introName.TextSize = 30
introName.TextTransparency = 1
introName.Parent = intro

local introLine = Instance.new("Frame")
introLine.AnchorPoint = Vector2.new(0.5, 0.5)
introLine.Position = UDim2.fromScale(0.5, 0.67)
introLine.Size = UDim2.fromOffset(0, 2)
introLine.BackgroundColor3 = COLORS.gold
introLine.BorderSizePixel = 0
introLine.Parent = intro

tween(bat, 0.35, {TextTransparency = 0})
tween(introName, 0.45, {TextTransparency = 0})
tween(introLine, 0.45, {Size = UDim2.fromOffset(210, 2)})
tween(introGlow, 0.7, {BackgroundTransparency = 0.72})
task.wait(1.65)
tween(intro, 0.3, {BackgroundTransparency = 1})
tween(bat, 0.2, {TextTransparency = 1})
tween(introName, 0.2, {TextTransparency = 1})
tween(introGlow, 0.2, {BackgroundTransparency = 1})
task.wait(0.32)
intro:Destroy()

-- Main window
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(620, 420)
main.Position = UDim2.new(0.5, -310, 0.5, -210)
main.BackgroundColor3 = COLORS.panel
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 14)
outline(main, COLORS.gold, 0.28, 1.2)

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 21, 31)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 16))
})
mainGradient.Rotation = 35
mainGradient.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 62)
top.BackgroundColor3 = COLORS.bg
top.BorderSizePixel = 0
top.Parent = main
corner(top, 14)

local topMask = Instance.new("Frame")
topMask.Position = UDim2.new(0, 0, 1, -14)
topMask.Size = UDim2.new(1, 0, 0, 14)
topMask.BackgroundColor3 = COLORS.bg
topMask.BorderSizePixel = 0
topMask.Parent = top

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 8)
title.Size = UDim2.fromOffset(240, 27)
title.Font = Enum.Font.GothamBlack
title.Text = "ALASHBAT"
title.TextColor3 = COLORS.gold
title.TextSize = 21
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(21, 34)
subtitle.Size = UDim2.fromOffset(300, 17)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "DARK KNIGHT  •  CLIENT INTERFACE"
subtitle.TextColor3 = COLORS.muted
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = top

local batMini = Instance.new("TextLabel")
batMini.BackgroundTransparency = 1
batMini.Position = UDim2.new(1, -94, 0, 7)
batMini.Size = UDim2.fromOffset(42, 42)
batMini.Font = Enum.Font.GothamBlack
batMini.Text = "🦇"
batMini.TextColor3 = COLORS.gold
batMini.TextScaled = true
batMini.Parent = top

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -42, 0, 15)
close.Size = UDim2.fromOffset(26, 26)
close.BackgroundColor3 = Color3.fromRGB(52, 27, 31)
close.Text = "×"
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.TextColor3 = COLORS.white
close.AutoButtonColor = false
close.Parent = top
corner(close, 7)

local side = Instance.new("Frame")
side.Position = UDim2.fromOffset(12, 75)
side.Size = UDim2.new(0, 145, 1, -88)
side.BackgroundColor3 = COLORS.bg
side.BorderSizePixel = 0
side.Parent = main
corner(side, 10)

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(170, 75)
content.Size = UDim2.new(1, -182, 1, -88)
content.BackgroundTransparency = 1
content.Parent = main

local pages, tabButtons = {}, {}
local currentTab = "Overview"

local function newPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Name = name
    p.Size = UDim2.fromScale(1, 1)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = COLORS.gold
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = false
    p.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = p
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        p.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end)
    pages[name] = p
    return p
end

local function setTab(name)
    currentTab = name
    for key, page in pairs(pages) do page.Visible = key == name end
    for key, button in pairs(tabButtons) do
        local selected = key == name
        button.BackgroundColor3 = selected and Color3.fromRGB(65, 51, 25) or COLORS.bg
        button.TextColor3 = selected and COLORS.gold2 or COLORS.muted
    end
end

local function addTab(name, iconText, order)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.Position = UDim2.fromOffset(8, 10 + (order - 1) * 47)
    b.Size = UDim2.new(1, -16, 0, 38)
    b.BackgroundColor3 = COLORS.bg
    b.Text = "   " .. iconText .. "     " .. name
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.TextColor3 = COLORS.muted
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = side
    corner(b, 8)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() setTab(name) end)
end

local sideLabel = Instance.new("TextLabel")
sideLabel.BackgroundTransparency = 1
sideLabel.Position = UDim2.fromOffset(15, 8)
sideLabel.Size = UDim2.new(1, -25, 0, 18)
sideLabel.Text = "NAVIGATION"
sideLabel.Font = Enum.Font.GothamBold
sideLabel.TextSize = 9
sideLabel.TextColor3 = COLORS.muted
sideLabel.TextXAlignment = Enum.TextXAlignment.Left
sideLabel.Parent = side

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 7)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = side

local spacer = Instance.new("Frame")
spacer.LayoutOrder = 0
spacer.Size = UDim2.new(1, 0, 0, 24)
spacer.BackgroundTransparency = 1
spacer.Parent = side

addTab("Overview", "◆", 1)
addTab("Visual Lab", "◈", 2)
addTab("Settings", "⚙", 3)

local function section(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -4, 0, 24)
    l.BackgroundTransparency = 1
    l.Text = string.upper(text)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextColor3 = COLORS.gold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function card(parent, height)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, height or 54)
    f.BackgroundColor3 = COLORS.card
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 9)
    outline(f, COLORS.gold, 0.86, 1)
    return f
end

local function label(parent, text, pos, size, textSize, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Font = Enum.Font.Gotham
    l.Text = text
    l.TextSize = textSize or 12
    l.TextColor3 = color or COLORS.white
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function toggle(parent, titleText, description, defaultValue, callback)
    local f = card(parent, 58)
    label(f, titleText, UDim2.fromOffset(13, 8), UDim2.new(1, -80, 0, 18), 12, COLORS.white)
    if description then
        label(f, description, UDim2.fromOffset(13, 29), UDim2.new(1, -80, 0, 16), 9, COLORS.muted)
    end
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -12, 0.5, 0)
    button.Size = UDim2.fromOffset(42, 22)
    button.Text = ""
    button.AutoButtonColor = false
    button.BackgroundColor3 = defaultValue and COLORS.gold or COLORS.card2
    button.Parent = f
    corner(button, 20)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(16, 16)
    dot.Position = defaultValue and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = COLORS.white
    dot.Parent = button
    corner(dot, 20)
    local state = defaultValue
    button.MouseButton1Click:Connect(function()
        state = not state
        tween(button, 0.15, {BackgroundColor3 = state and COLORS.gold or COLORS.card2})
        tween(dot, 0.15, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        if callback then callback(state) end
    end)
    return function() return state end
end

local function slider(parent, titleText, minValue, maxValue, initial, callback)
    local f = card(parent, 67)
    label(f, titleText, UDim2.fromOffset(13, 7), UDim2.new(0.7, 0, 0, 18), 11, COLORS.white)
    local valueLabel = label(f, tostring(initial), UDim2.new(0.75, 0, 0, 7), UDim2.new(0.2, -8, 0, 18), 11, COLORS.gold)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local bar = Instance.new("TextButton")
    bar.Position = UDim2.fromOffset(13, 39)
    bar.Size = UDim2.new(1, -26, 0, 7)
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.BackgroundColor3 = COLORS.card2
    bar.Parent = f
    corner(bar, 5)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial-minValue)/(maxValue-minValue), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.gold
    fill.Parent = bar
    corner(fill, 5)
    local value = initial
    local function setX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor((minValue + alpha * (maxValue-minValue)) * 10 + 0.5) / 10
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        if callback then callback(value) end
    end
    bar.MouseButton1Down:Connect(function()
        setX(UserInputService:GetMouseLocation().X)
        local move, ended
        move = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                setX(UserInputService:GetMouseLocation().X)
            end
        end)
        ended = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                move:Disconnect()
                ended:Disconnect()
            end
        end)
    end)
    return function() return value end
end

local overview = newPage("Overview")
section(overview, "Welcome back")
local welcome = card(overview, 94)
label(welcome, "THE DARK KNIGHT INTERFACE", UDim2.fromOffset(15, 13), UDim2.new(1, -30, 0, 20), 15, COLORS.gold2)
label(welcome, "ALASHBAT is loaded successfully.", UDim2.fromOffset(15, 40), UDim2.new(1, -30, 0, 18), 11, COLORS.white)
label(welcome, "Use the tabs to customize the local visual demo.", UDim2.fromOffset(15, 62), UDim2.new(1, -30, 0, 17), 9, COLORS.muted)
section(overview, "Quick controls")
toggle(overview, "Animated gold accents", "Animate the interface highlight", true)
toggle(overview, "Compact interface", "Visual preference preview only", false, function(on)
    tween(main, 0.2, {Size = on and UDim2.fromOffset(560, 390) or UDim2.fromOffset(620, 420)})
end)
local info = card(overview, 55)
label(info, "F1", UDim2.fromOffset(14, 8), UDim2.fromOffset(35, 18), 12, COLORS.gold)
label(info, "Hide / show the ALASHBAT window", UDim2.fromOffset(52, 8), UDim2.new(1, -65, 0, 18), 10, COLORS.muted)
label(info, "Drag the top bar to move the interface.", UDim2.fromOffset(14, 30), UDim2.new(1, -25, 0, 16), 9, COLORS.muted)

local visual = newPage("Visual Lab")
section(visual, "Local visual preferences")
toggle(visual, "Local highlight preview", "Changes only your own character's outline", false, function(on)
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChild("ALASHBAT_LocalPreview")
    if on and not h then
        h = Instance.new("Highlight")
        h.Name = "ALASHBAT_LocalPreview"
        h.FillColor = COLORS.gold
        h.OutlineColor = COLORS.gold2
        h.FillTransparency = 0.88
        h.OutlineTransparency = 0.05
        h.Adornee = char
        h.Parent = char
    elseif not on and h then
        h:Destroy()
    end
end)
toggle(visual, "Show local status label", "A small label above your own character", false, function(on)
    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    local existing = head:FindFirstChild("ALASHBAT_LocalLabel")
    if on and not existing then
        local bb = Instance.new("BillboardGui")
        bb.Name = "ALASHBAT_LocalLabel"
        bb.Size = UDim2.fromOffset(150, 28)
        bb.StudsOffset = Vector3.new(0, 2.7, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        local tx = Instance.new("TextLabel")
        tx.Size = UDim2.fromScale(1, 1)
        tx.BackgroundTransparency = 1
        tx.Text = "ALASHBAT"
        tx.Font = Enum.Font.GothamBold
        tx.TextSize = 12
        tx.TextColor3 = COLORS.gold
        tx.TextStrokeTransparency = 0.35
        tx.Parent = bb
    elseif not on and existing then
        existing:Destroy()
    end
end)
local visualNote = card(visual, 76)
label(visualNote, "Visual Lab is intentionally local-only.", UDim2.fromOffset(13, 12), UDim2.new(1, -25, 0, 18), 11, COLORS.gold2)
label(visualNote, "It does not reveal, mark, or track other players.", UDim2.fromOffset(13, 36), UDim2.new(1, -25, 0, 18), 9, COLORS.muted)

local settings = newPage("Settings")
section(settings, "Interface settings")
local opacityValue = slider(settings, "Window transparency", 0, 0.35, 0, function(v)
    main.BackgroundTransparency = v
end)
local scaleValue = slider(settings, "UI scale", 0.8, 1.2, 1, function(v)
    local scale = main:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Parent = main
    end
    scale.Scale = v
end)
toggle(settings, "Gold color mode", "Keep the Batman-inspired black and gold palette", true)
local reset = Instance.new("TextButton")
reset.Size = UDim2.new(1, -6, 0, 38)
reset.BackgroundColor3 = Color3.fromRGB(65, 40, 26)
reset.Text = "RESET INTERFACE"
reset.Font = Enum.Font.GothamBold
reset.TextSize = 11
reset.TextColor3 = COLORS.gold2
reset.AutoButtonColor = false
reset.Parent = settings
corner(reset, 8)
reset.MouseButton1Click:Connect(function()
    main.BackgroundTransparency = 0
    local scale = main:FindFirstChildOfClass("UIScale")
    if scale then scale.Scale = 1 end
end)

-- Animated accent sweep
local accentBar = Instance.new("Frame")
accentBar.Position = UDim2.new(0, 0, 0, 61)
accentBar.Size = UDim2.new(0.35, 0, 0, 2)
accentBar.BackgroundColor3 = COLORS.gold
accentBar.BorderSizePixel = 0
accentBar.Parent = main
local accentGrad = Instance.new("UIGradient")
accentGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1)
})
accentGrad.Parent = accentBar

task.spawn(function()
    while alive and accentBar.Parent do
        accentBar.Position = UDim2.new(-0.35, 0, 0, 61)
        tween(accentBar, 1.8, {Position = UDim2.new(1, 0, 0, 61)}, Enum.EasingStyle.Linear)
        task.wait(1.85)
    end
end)

-- Drag window from header
do
    local dragging, dragStart, startPos = false, nil, nil
    connect(top.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local visible = true
local function setVisible(value)
    visible = value
    main.Visible = value
end

connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F1 then
        setVisible(not visible)
    end
end)

local function unload()
    if not alive then return end
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChild("ALASHBAT_LocalPreview")
        if h then h:Destroy() end
        local head = char:FindFirstChild("Head")
        local bb = head and head:FindFirstChild("ALASHBAT_LocalLabel")
        if bb then bb:Destroy() end
    end
    if gui then gui:Destroy() end
    env.ALASHBAT_UNLOAD = nil
end

close.MouseButton1Click:Connect(unload)
env.ALASHBAT_UNLOAD = unload
setTab("Overview")
