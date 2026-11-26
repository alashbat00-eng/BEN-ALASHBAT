--[[
    ALASHBAT UI
    Cosmetic interface + local visual debugging scaffold.
    Safe scope: UI, language toggle, local character highlight/label.
    It does NOT include player aimbot, TriggerBot, hitbox expansion,
    or player tracking/ESP for public games.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

if not player then return end

local old
pcall(function()
    old = (gethui and gethui():FindFirstChild("ALASHBAT_UI")) or CoreGui:FindFirstChild("ALASHBAT_UI")
end)
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ALASHBAT_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local parented = false
pcall(function()
    if gethui then
        gui.Parent = gethui()
        parented = true
    end
end)
if not parented then
    pcall(function()
        gui.Parent = CoreGui
        parented = true
    end)
end
if not parented then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local BLACK = Color3.fromRGB(10, 11, 14)
local PANEL = Color3.fromRGB(19, 21, 26)
local PANEL2 = Color3.fromRGB(27, 29, 35)
local GOLD = Color3.fromRGB(225, 178, 62)
local WHITE = Color3.fromRGB(239, 240, 243)
local MUTED = Color3.fromRGB(150, 153, 162)

local language = "EN"
local function tr(en, ar)
    return language == "AR" and ar or en
end

-- Center-only intro overlay: transparent background, no screen dimming.
local intro = Instance.new("Frame")
intro.Name = "Intro"
intro.AnchorPoint = Vector2.new(0.5, 0.5)
intro.Position = UDim2.fromScale(0.5, 0.5)
intro.Size = UDim2.fromOffset(230, 190)
intro.BackgroundTransparency = 1
intro.Parent = gui

-- Stylized bat silhouette built from UI geometry (not an emoji).
local bat = Instance.new("ImageLabel")
bat.Name = "BatMark"
bat.BackgroundTransparency = 1
bat.AnchorPoint = Vector2.new(0.5, 0.5)
bat.Position = UDim2.fromScale(0.5, 0.43)
bat.Size = UDim2.fromOffset(190, 110)
bat.Image = "rbxassetid://0" -- Replace with your own uploaded bat silhouette image.
bat.ImageColor3 = Color3.fromRGB(8, 8, 10)
bat.ScaleType = Enum.ScaleType.Fit
bat.Parent = intro

-- If no custom image is uploaded, use a clean abstract bat mark.
local wings = Instance.new("TextLabel")
wings.BackgroundTransparency = 1
wings.Size = UDim2.fromScale(1, 0.72)
wings.Position = UDim2.fromScale(0, 0)
wings.Font = Enum.Font.GothamBlack
wings.Text = "◢◣"
wings.TextSize = 1
wings.TextTransparency = 1
wings.Parent = intro

local chest = Instance.new("TextLabel")
chest.BackgroundTransparency = 1
chest.AnchorPoint = Vector2.new(0.5, 0.5)
chest.Position = UDim2.fromScale(0.5, 0.47)
chest.Size = UDim2.fromOffset(170, 34)
chest.Font = Enum.Font.GothamBlack
chest.Text = "ALASHBAT"
chest.TextColor3 = GOLD
chest.TextSize = 20
chest.TextStrokeTransparency = 0.35
chest.Parent = intro

-- A minimal custom bat emblem made from polygons.
local function makeWing(name, pos, rotation)
    local f = Instance.new("Frame")
    f.Name = name
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = pos
    f.Size = UDim2.fromOffset(88, 42)
    f.BackgroundColor3 = Color3.fromRGB(7, 8, 10)
    f.BorderSizePixel = 0
    f.Rotation = rotation
    f.Parent = intro
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = f
    return f
end
makeWing("LeftWing", UDim2.fromScale(0.29, 0.34), -18)
makeWing("RightWing", UDim2.fromScale(0.71, 0.34), 18)
local body = Instance.new("Frame")
body.AnchorPoint = Vector2.new(0.5, 0.5)
body.Position = UDim2.fromScale(0.5, 0.36)
body.Size = UDim2.fromOffset(35, 78)
body.BackgroundColor3 = Color3.fromRGB(7, 8, 10)
body.BorderSizePixel = 0
body.Parent = intro
local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0.5, 0)
bodyCorner.Parent = body
chest.ZIndex = 5

task.wait(4)
local fade = TweenService:Create(intro, TweenInfo.new(0.35), {GroupTransparency = 1})
-- Frames do not support GroupTransparency; destroy cleanly after the intro.
task.wait(0.35)
intro:Destroy()

-- Main window
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(570, 390)
main.Position = UDim2.new(0.5, -285, 0.5, -195)
main.BackgroundColor3 = BLACK
main.BorderSizePixel = 0
main.Parent = gui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main
local stroke = Instance.new("UIStroke")
stroke.Color = GOLD
stroke.Thickness = 1.2
stroke.Transparency = 0.2
stroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 52)
top.BackgroundColor3 = PANEL
top.BorderSizePixel = 0
top.Parent = main
local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = top

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(17, 0)
title.Size = UDim2.new(1, -190, 1, 0)
title.Font = Enum.Font.GothamBlack
title.Text = "ALASHBAT"
title.TextColor3 = GOLD
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local function button(parent, text, size, pos)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = PANEL2
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.AutoButtonColor = true
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b
    return b
end

local langBtn = button(top, "EN / AR", UDim2.fromOffset(68, 29), UDim2.new(1, -150, 0, 11))
local hideBtn = button(top, "—", UDim2.fromOffset(30, 29), UDim2.new(1, -75, 0, 11))
local closeBtn = button(top, "×", UDim2.fromOffset(30, 29), UDim2.new(1, -38, 0, 11))
langBtn.TextColor3 = GOLD

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(12, 65)
sidebar.Size = UDim2.fromOffset(145, 312)
sidebar.BackgroundColor3 = PANEL
sidebar.BorderSizePixel = 0
sidebar.Parent = main
local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 9)
sideCorner.Parent = sidebar

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(169, 65)
content.Size = UDim2.new(1, -181, 1, -78)
content.BackgroundColor3 = PANEL
content.BorderSizePixel = 0
content.Parent = main
local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 9)
contentCorner.Parent = content

local pages = {}
local currentPage
local function newPage(key)
    local page = Instance.new("Frame")
    page.Name = key
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content
    pages[key] = page
    return page
end

local overview = newPage("Overview")
local visual = newPage("Visual")
local settings = newPage("Settings")

local function label(parent, text, pos, size, color, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Font = Enum.Font.Gotham
    l.Text = text
    l.TextColor3 = color or WHITE
    l.TextSize = textSize or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

label(overview, "ALASHBAT CONTROL CENTER", UDim2.fromOffset(18, 18), UDim2.new(1, -36, 0, 28), GOLD, 16).Font = Enum.Font.GothamBold
label(overview, "Interface loaded successfully.", UDim2.fromOffset(18, 54), UDim2.new(1, -36, 0, 25), MUTED, 12)
label(overview, "Use the Visual Lab for local character debugging.", UDim2.fromOffset(18, 82), UDim2.new(1, -36, 0, 40), WHITE, 12)

local localHighlight
local localBillboard
local function setLocalHighlight(enabled)
    local character = player.Character
    if not character then return end
    if enabled then
        if not localHighlight then
            localHighlight = Instance.new("Highlight")
            localHighlight.Name = "ALASHBAT_LocalHighlight"
            localHighlight.FillColor = GOLD
            localHighlight.OutlineColor = WHITE
            localHighlight.FillTransparency = 0.72
            localHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
        end
        localHighlight.Parent = character
    elseif localHighlight then
        localHighlight:Destroy()
        localHighlight = nil
    end
end

local function setLocalLabel(enabled)
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if enabled and head then
        if localBillboard then localBillboard:Destroy() end
        localBillboard = Instance.new("BillboardGui")
        localBillboard.Name = "ALASHBAT_LocalLabel"
        localBillboard.Size = UDim2.fromOffset(150, 28)
        localBillboard.StudsOffset = Vector3.new(0, 2.4, 0)
        localBillboard.AlwaysOnTop = false
        localBillboard.Adornee = head
        localBillboard.Parent = head
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromScale(1, 1)
        t.BackgroundTransparency = 1
        t.Text = "ALASHBAT | " .. player.Name
        t.TextColor3 = GOLD
        t.TextStrokeTransparency = 0.35
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.Parent = localBillboard
    elseif localBillboard then
        localBillboard:Destroy()
        localBillboard = nil
    end
end

local function toggleRow(parent, y, en, ar, callback)
    local state = false
    local b = button(parent, "OFF", UDim2.fromOffset(64, 27), UDim2.new(1, -82, 0, y))
    label(parent, tr(en, ar), UDim2.fromOffset(16, y), UDim2.new(1, -110, 0, 27), WHITE, 12)
    b.MouseButton1Click:Connect(function()
        state = not state
        b.Text = state and "ON" or "OFF"
        b.TextColor3 = state and GOLD or WHITE
        callback(state)
    end)
    return b
end

label(visual, "LOCAL VISUAL DEBUG", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 26), GOLD, 15).Font = Enum.Font.GothamBold
toggleRow(visual, 55, "Highlight my character", "تحديد شخصيتي", setLocalHighlight)
toggleRow(visual, 96, "Show my local label", "إظهار اسمي فوق شخصيتي", setLocalLabel)
label(visual, "These options affect only your own character.", UDim2.fromOffset(16, 145), UDim2.new(1, -32, 0, 35), MUTED, 11)

label(settings, "PREFERENCES", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 26), GOLD, 15).Font = Enum.Font.GothamBold
local compact = false
toggleRow(settings, 55, "Compact interface", "واجهة مصغّرة", function(on)
    compact = on
    main.Size = on and UDim2.fromOffset(500, 340) or UDim2.fromOffset(570, 390)
end)
label(settings, "F1  -  Hide / show menu", UDim2.fromOffset(16, 105), UDim2.new(1, -32, 0, 24), MUTED, 11)
label(settings, "Drag the top bar to move the window.", UDim2.fromOffset(16, 130), UDim2.new(1, -32, 0, 24), MUTED, 11)

local tabButtons = {}
local function showPage(key)
    for name, page in pairs(pages) do page.Visible = name == key end
    currentPage = key
    for name, b in pairs(tabButtons) do
        b.BackgroundColor3 = name == key and Color3.fromRGB(54, 43, 22) or PANEL2
        b.TextColor3 = name == key and GOLD or WHITE
    end
end

local tabData = {
    {"Overview", "Overview", "الرئيسية"},
    {"Visual", "Visual Lab", "المظهر"},
    {"Settings", "Settings", "الإعدادات"}
}
for i, data in ipairs(tabData) do
    local key = data[1]
    local b = button(sidebar, tr(data[2], data[3]), UDim2.new(1, -16, 0, 37), UDim2.fromOffset(8, 12 + (i-1)*47))
    tabButtons[key] = b
    b.MouseButton1Click:Connect(function() showPage(key) end)
end

local function refreshLanguage()
    title.Text = "ALASHBAT"
    langBtn.Text = language == "EN" and "EN / AR" or "AR / EN"
    for i, data in ipairs(tabData) do
        tabButtons[data[1]].Text = tr(data[2], data[3])
    end
end
langBtn.MouseButton1Click:Connect(function()
    language = language == "EN" and "AR" or "EN"
    refreshLanguage()
end)

showPage("Overview")

-- Drag window from title bar.
local dragging, dragInput, dragStart, startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
top.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local hidden = false
hideBtn.MouseButton1Click:Connect(function()
    hidden = true
    main.Visible = false
end)
closeBtn.MouseButton1Click:Connect(function()
    if localHighlight then localHighlight:Destroy() end
    if localBillboard then localBillboard:Destroy() end
    gui:Destroy()
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F1 then
        hidden = not hidden
        main.Visible = not hidden
    end
end)

player.CharacterAdded:Connect(function()
    if localHighlight then localHighlight = nil end
    if localBillboard then localBillboard:Destroy(); localBillboard = nil end
end)
