-- ALASHBAT LAB — FULL EXECUTOR EDITION
-- Ready for Roblox Executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.ALASHBAT_FULL_UNLOAD then
	pcall(env.ALASHBAT_FULL_UNLOAD)
end

local isRunning = true
local connections = {}

local function hook(conn)
	if conn then
		table.insert(connections, conn)
	end
	return conn
end

local S = {
	-- Aim Assist
	aimEnabled = false,
	aimPart = "Head",
	aimFov = 135,
	aimSmooth = 0.22,
	aimHoldRmb = true,

	-- ESP & Cham
	espEnabled = true,
	espNames = true,
	espDistance = true,
	espHealthBar = true,
	espCham = true,
	espCircle = true,

	-- Hitbox
	hitboxEnabled = false,
	hitboxSize = 5,
	hitboxTrans = 0.88,

	-- TriggerBot
	triggerEnabled = false,
	triggerDelay = 0.04,

	-- General
	teamCheck = true,
	maxRange = 750
}

local function resolveUiParent()
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local okCore, core = pcall(function()
		local f = Instance.new("Folder")
		f.Name = "_AlashbatChk_" .. tostring(math.random(1000, 9999))
		f.Parent = game:GetService("CoreGui")
		f:Destroy()
		return game:GetService("CoreGui")
	end)
	if okCore and core then return core end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
end

local uiParent = resolveUiParent()
if not uiParent then return end

local C = {
	bg = Color3.fromRGB(10, 11, 14),
	panel = Color3.fromRGB(16, 17, 22),
	surface = Color3.fromRGB(23, 25, 32),
	raised = Color3.fromRGB(32, 35, 44),
	gold = Color3.fromRGB(245, 196, 48),
	text = Color3.fromRGB(238, 240, 244),
	muted = Color3.fromRGB(145, 150, 162),
	stroke = Color3.fromRGB(45, 48, 58),
	ok = Color3.fromRGB(80, 215, 130),
	warn = Color3.fromRGB(245, 105, 105),
	off = Color3.fromRGB(54, 57, 68)
}

local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 7)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or C.stroke
	s.Thickness = thickness or 1
	s.Transparency = trans or 0.25
	s.Parent = inst
	return s
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ALASHBAT_LAB_GUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 1500
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screenGui)
	end
end)
screenGui.Parent = uiParent

-- شعار البداية في المنتصف فقط (بيضاوي أصفر + خفاش أسود + ALASHBAT أصفر)
do
	local splash = Instance.new("Frame")
	splash.Name = "BatSplash"
	splash.AnchorPoint = Vector2.new(0.5, 0.5)
	splash.Position = UDim2.fromScale(0.5, 0.5)
	splash.Size = UDim2.fromOffset(270, 145)
	splash.BackgroundColor3 = C.gold
	splash.BorderSizePixel = 0
	splash.ZIndex = 60
	splash.Parent = screenGui
	corner(splash, 72)

	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -12, 1, -12)
	inner.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	inner.BorderSizePixel = 0
	inner.ZIndex = 61
	inner.Parent = splash
	corner(inner, 66)

	-- جسم الخفاش الأسود + الأجنحة
	local body = Instance.new("Frame")
	body.AnchorPoint = Vector2.new(0.5, 0.5)
	body.Position = UDim2.new(0.5, 0, 0.56, 0)
	body.Size = UDim2.fromOffset(195, 52)
	body.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	body.BorderSizePixel = 0
	body.ZIndex = 62
	body.Parent = inner
	corner(body, 26)

	local leftWing = Instance.new("Frame")
	leftWing.AnchorPoint = Vector2.new(0.5, 0.5)
	leftWing.Position = UDim2.new(0.26, 0, 0.44, 0)
	leftWing.Size = UDim2.fromOffset(78, 44)
	leftWing.Rotation = -14
	leftWing.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	leftWing.BorderSizePixel = 0
	leftWing.ZIndex = 62
	leftWing.Parent = inner
	corner(leftWing, 22)

	local rightWing = Instance.new("Frame")
	rightWing.AnchorPoint = Vector2.new(0.5, 0.5)
	rightWing.Position = UDim2.new(0.74, 0, 0.44, 0)
	rightWing.Size = UDim2.fromOffset(78, 44)
	rightWing.Rotation = 14
	rightWing.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	rightWing.BorderSizePixel = 0
	rightWing.ZIndex = 62
	rightWing.Parent = inner
	corner(rightWing, 22)

	local head = Instance.new("Frame")
	head.AnchorPoint = Vector2.new(0.5, 0.5)
	head.Position = UDim2.new(0.5, 0, 0.34, 0)
	head.Size = UDim2.fromOffset(26, 22)
	head.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	head.BorderSizePixel = 0
	head.ZIndex = 63
	head.Parent = inner
	corner(head, 8)

	local earL = Instance.new("Frame")
	earL.Position = UDim2.fromOffset(2, -6)
	earL.Size = UDim2.fromOffset(7, 10)
	earL.Rotation = -12
	earL.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	earL.BorderSizePixel = 0
	earL.ZIndex = 63
	earL.Parent = head

	local earR = Instance.new("Frame")
	earR.Position = UDim2.fromOffset(17, -6)
	earR.Size = UDim2.fromOffset(7, 10)
	earR.Rotation = 12
	earR.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	earR.BorderSizePixel = 0
	earR.ZIndex = 63
	earR.Parent = head

	local batText = Instance.new("TextLabel")
	batText.AnchorPoint = Vector2.new(0.5, 0.5)
	batText.Position = UDim2.new(0.5, 0, 0.57, 0)
	batText.Size = UDim2.new(0.9, 0, 0, 24)
	batText.BackgroundTransparency = 1
	batText.Font = Enum.Font.GothamBlack
	batText.Text = "ALASHBAT"
	batText.TextColor3 = C.gold
	batText.TextSize = 15
	batText.ZIndex = 65
	batText.Parent = inner

	task.delay(2.2, function()
		if splash and splash.Parent then
			local tw = TweenService:Create(splash, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
				GroupTransparency = 1
			})
			pcall(function() tw:Play() end)
			splash:Destroy()
		end
	end)
end

-- فحص الفرق والأهداف
local function isEnemy(player)
	if not player or player == LocalPlayer then return false end
	if not S.teamCheck then return true end
	if LocalPlayer.Team and player.Team then
		return player.Team ~= LocalPlayer.Team
	end
	return true
end

local function getTeamColor(player)
	if player.Team and player.TeamColor then
		return player.TeamColor.Color
	end
	return C.gold
end

local function getTargetPlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if isEnemy(p) and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and hrp then
				table.insert(list, { player = p, char = p.Character, hum = hum, hrp = hrp })
			end
		end
	end
	return list
end

-- دائرة FOV
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = S.espCircle
fovCircle.Parent = screenGui
corner(fovCircle, 999)
stroke(fovCircle, C.gold, 1.3, 0.2)

-- نظام ESP + شريط صحة عمودي بجانب اللاعب + Cham عبر الجدران
local visualsMap = {}

local function clearPlayerVisual(player)
	local pack = visualsMap[player]
	if pack then
		pcall(function()
			if pack.highlight then pack.highlight:Destroy() end
			if pack.billboard then pack.billboard:Destroy() end
		end)
		visualsMap[player] = nil
	end
end

local function clearAllVisuals()
	for p in pairs(visualsMap) do
		clearPlayerVisual(p)
	end
end

local function updateHealthSideBar(pack, hum)
	if not pack or not pack.hpBg or not pack.hpFill then return end
	pack.hpBg.Visible = S.espHealthBar and hum ~= nil
	if hum then
		local maxHp = math.max(hum.MaxHealth, 1)
		local ratio = math.clamp(hum.Health / maxHp, 0, 1)
		-- شريط عمودي يتقلص من الأعلى للأسفل بجانب اللاعب
		pack.hpFill.Size = UDim2.new(1, 0, ratio, 0)
		pack.hpFill.Position = UDim2.new(0, 0, 1 - ratio, 0)
		pack.hpFill.BackgroundColor3 = ratio > 0.45 and C.ok or (ratio > 0.2 and C.gold or C.warn)
	end
end

local function updateVisuals()
	if not isRunning or not screenGui.Parent then return end

	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local active = {}

	for _, entry in ipairs(getTargetPlayers()) do
		local p = entry.player
		local char = entry.char
		local hum = entry.hum
		local hrp = entry.hrp

		local dist = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
		if dist <= S.maxRange then
			active[p] = true
			local tCol = getTeamColor(p)

			local pack = visualsMap[p]
			if not pack or pack.char ~= char then
				clearPlayerVisual(p)
				pack = { char = char }
				visualsMap[p] = pack
			end

			-- Player Cham عبر الجدران (AlwaysOnTop)
			if S.espCham then
				if not pack.highlight or not pack.highlight.Parent then
					local hl = Instance.new("Highlight")
					hl.Name = "AlashbatCham"
					hl.Adornee = char
					hl.FillColor = tCol
					hl.OutlineColor = C.text
					hl.FillTransparency = 0.55
					hl.OutlineTransparency = 0
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = char
					pack.highlight = hl
				else
					pack.highlight.Adornee = char
					pack.highlight.FillColor = tCol
					pack.highlight.Enabled = true
				end
			elseif pack.highlight then
				pack.highlight:Destroy()
				pack.highlight = nil
			end

			-- الاسم + المسافة + شريط الصحة العمودي بجانب اللاعب
			if S.espEnabled or S.espHealthBar then
				if not pack.billboard or not pack.billboard.Parent then
					local bb = Instance.new("BillboardGui")
					bb.Name = "AlashbatTag"
					bb.AlwaysOnTop = true
					bb.Size = UDim2.fromOffset(170, 72)
					bb.StudsOffset = Vector3.new(0, 0.5, 0)
					bb.Adornee = hrp
					bb.Parent = screenGui

					local nameLbl = Instance.new("TextLabel")
					nameLbl.Name = "NameLbl"
					nameLbl.BackgroundTransparency = 1
					nameLbl.Position = UDim2.fromOffset(0, 0)
					nameLbl.Size = UDim2.new(1, 0, 0, 18)
					nameLbl.Font = Enum.Font.GothamBold
					nameLbl.TextSize = 12
					nameLbl.TextColor3 = tCol
					nameLbl.TextStrokeTransparency = 0.25
					nameLbl.Parent = bb

					-- شريط الصحة الطولي على يسار اللاعب
					local hpBg = Instance.new("Frame")
					hpBg.Name = "SideHPBg"
					hpBg.Position = UDim2.fromOffset(22, 20)
					hpBg.Size = UDim2.fromOffset(6, 48)
					hpBg.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
					hpBg.BorderSizePixel = 0
					hpBg.Parent = bb
					corner(hpBg, 3)

					local hpFill = Instance.new("Frame")
					hpFill.Name = "SideHPFill"
					hpFill.Size = UDim2.fromScale(1, 1)
					hpFill.BackgroundColor3 = C.ok
					hpFill.BorderSizePixel = 0
					hpFill.Parent = hpBg
					corner(hpFill, 3)

					pack.billboard = bb
					pack.nameLbl = nameLbl
					pack.hpBg = hpBg
					pack.hpFill = hpFill
				else
					pack.billboard.Adornee = hrp
				end

				pack.billboard.Enabled = true
				if pack.nameLbl then
					pack.nameLbl.Visible = S.espEnabled and (S.espNames or S.espDistance)
					local parts = {}
					if S.espNames then table.insert(parts, p.DisplayName) end
					if S.espDistance then table.insert(parts, "[" .. math.floor(dist) .. "]") end
					pack.nameLbl.Text = table.concat(parts, " ")
					pack.nameLbl.TextColor3 = tCol
				end
				updateHealthSideBar(pack, hum)
			elseif pack.billboard then
				pack.billboard:Destroy()
				pack.billboard = nil
				pack.nameLbl = nil
				pack.hpBg = nil
				pack.hpFill = nil
			end
		else
			clearPlayerVisual(p)
		end
	end

	for p in pairs(visualsMap) do
		if not active[p] then
			clearPlayerVisual(p)
		end
	end
end

-- نظام Hitbox
local hitboxSaved = {}

local function restorePart(hrp)
	local orig = hitboxSaved[hrp]
	if orig and hrp and hrp.Parent then
		pcall(function()
			hrp.Size = orig.Size
			hrp.Transparency = orig.Transparency
			hrp.CanCollide = orig.CanCollide
		end)
	end
	hitboxSaved[hrp] = nil
end

local function restoreAllHitboxes()
	for hrp in pairs(hitboxSaved) do
		restorePart(hrp)
	end
end

local function applyHitbox()
	if not S.hitboxEnabled then
		restoreAllHitboxes()
		return
	end
	local sz = math.clamp(tonumber(S.hitboxSize) or 5, 1, 25)
	for _, entry in ipairs(getTargetPlayers()) do
		local hrp = entry.hrp
		if hrp and hrp.Parent then
			if not hitboxSaved[hrp] then
				hitboxSaved[hrp] = {
					Size = hrp.Size,
					Transparency = hrp.Transparency,
					CanCollide = hrp.CanCollide
				}
			end
			pcall(function()
				hrp.Size = Vector3.new(sz, sz, sz)
				hrp.Transparency = S.hitboxTrans
				hrp.CanCollide = false
			end)
		end
	end
end

-- نظام Aim Assist
local function getBestAimTarget()
	Camera = Workspace.CurrentCamera
	if not Camera then return nil end
	local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	local bestPart = nil
	local bestDist = math.huge

	for _, entry in ipairs(getTargetPlayers()) do
		local char = entry.char
		local hrp = entry.hrp
		local part = char:FindFirstChild(S.aimPart) or hrp
		if part and part:IsA("BasePart") then
			local worldDist = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
			if worldDist <= S.maxRange then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen and screenPos.Z > 0 then
					local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if d <= S.aimFov and d < bestDist then
						bestDist = d
						bestPart = part
					end
				end
			end
		end
	end

	return bestPart
end

-- نظام TriggerBot
local lastTriggerFire = 0
local function fireClick()
	if typeof(mouse1click) == "function" then
		pcall(mouse1click)
		return
	end
	local loc = UserInputService:GetMouseLocation()
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(loc.X, loc.Y, 0, true, game, 1)
		VirtualInputManager:SendMouseButtonEvent(loc.X, loc.Y, 0, false, game, 1)
	end)
end

local function checkTriggerBot()
	if not S.triggerEnabled then return end
	local now = os.clock()
	if (now - lastTriggerFire) < S.triggerDelay then return end

	local target = Mouse.Target
	if target and target.Parent then
		local char = target.Parent
		local p = Players:GetPlayerFromCharacter(char)
		if not p and char.Parent then
			p = Players:GetPlayerFromCharacter(char.Parent)
		end
		if p and isEnemy(p) then
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				lastTriggerFire = now
				fireClick()
			end
		end
	end
end

-- بناء الواجهة المقسمة
local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Active = true
main.BackgroundColor3 = C.panel
main.Position = UDim2.new(0.5, -240, 0.5, -185)
main.Size = UDim2.fromOffset(480, 370)
main.ClipsDescendants = true
main.Parent = screenGui
corner(main, 10)
stroke(main, C.gold, 1.2, 0.25)

do
	local dragging, dragStart, startPos = false, nil, nil
	hook(main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))
	hook(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
end

local topBar = Instance.new("Frame")
topBar.BackgroundColor3 = C.bg
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BorderSizePixel = 0
topBar.Parent = main

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.fromOffset(14, 0)
titleLbl.Size = UDim2.new(1, -90, 1, 0)
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.Text = "ALASHBAT  //  HUB"
titleLbl.TextColor3 = C.gold
titleLbl.TextSize = 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 24)
closeBtn.Position = UDim2.new(1, -34, 0.5, -12)
closeBtn.BackgroundColor3 = C.surface
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = C.warn
closeBtn.TextSize = 14
closeBtn.Parent = topBar
corner(closeBtn, 6)

local side = Instance.new("Frame")
side.BackgroundColor3 = C.bg
side.Position = UDim2.fromOffset(8, 44)
side.Size = UDim2.fromOffset(122, 318)
side.BorderSizePixel = 0
side.Parent = main
corner(side, 8)
stroke(side, C.stroke, 1, 0.4)

local content = Instance.new("Frame")
content.BackgroundColor3 = C.surface
content.Position = UDim2.fromOffset(136, 44)
content.Size = UDim2.new(1, -144, 1, -52)
content.BorderSizePixel = 0
content.Parent = main
corner(content, 8)
stroke(content, C.stroke, 1, 0.4)

local pages, tabBtns = {}, {}
local function makePage(key)
	local p = Instance.new("ScrollingFrame")
	p.Name = key
	p.Size = UDim2.fromScale(1, 1)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.ScrollBarThickness = 3
	p.ScrollBarImageColor3 = C.gold
	p.CanvasSize = UDim2.fromOffset(0, 320)
	p.Visible = false
	p.Parent = content
	pages[key] = p
	return p
end

local function selectTab(key)
	for k, p in pairs(pages) do p.Visible = (k == key) end
	for k, b in pairs(tabBtns) do
		local active = (k == key)
		b.BackgroundColor3 = active and Color3.fromRGB(56, 44, 16) or C.surface
		b.TextColor3 = active and C.gold or C.text
	end
end

local tabList = {
	{ "Home", "الكل / الرئيسية" },
	{ "Aim", "الأيم بوت" },
	{ "ESP", "الكشف و Cham" },
	{ "Hitbox", "الهيت بوكس" },
	{ "Trigger", "التريقر بوت" },
	{ "Settings", "الإعدادات" }
}

for i, info in ipairs(tabList) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 32)
	btn.Position = UDim2.fromOffset(5, 6 + (i - 1) * 38)
	btn.BackgroundColor3 = C.surface
	btn.Font = Enum.Font.GothamBold
	btn.Text = info[2]
	btn.TextColor3 = C.text
	btn.TextSize = 11
	btn.Parent = side
	corner(btn, 6)
	tabBtns[info[1]] = btn
	hook(btn.MouseButton1Click:Connect(function()
		selectTab(info[1])
	end))
end

local toggleSyncs = {}
local function addToggleRow(parent, y, labelText, getFn, setFn, onToggle)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = C.panel
	row.Position = UDim2.fromOffset(10, y)
	row.Size = UDim2.new(1, -20, 0, 30)
	row.Parent = parent
	corner(row, 6)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.Size = UDim2.new(1, -92, 1, 0)
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = labelText
	lbl.TextColor3 = C.text
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(72, 22)
	btn.Position = UDim2.new(1, -80, 0.5, -11)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = row
	corner(btn, 5)

	local function sync()
		local active = getFn()
		btn.Text = active and "مفعل" or "معطل"
		btn.TextColor3 = active and C.ok or C.muted
		btn.BackgroundColor3 = active and Color3.fromRGB(22, 48, 34) or C.off
	end

	table.insert(toggleSyncs, sync)
	hook(btn.MouseButton1Click:Connect(function()
		local nextVal = not getFn()
		setFn(nextVal)
		sync()
		if onToggle then onToggle(nextVal) end
	end))
	sync()
	return sync
end

local function addStepperRow(parent, y, labelText, getFn, setFn, step, minV, maxV, fmtFn, onChange)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = C.panel
	row.Position = UDim2.fromOffset(10, y)
	row.Size = UDim2.new(1, -20, 0, 30)
	row.Parent = parent
	corner(row, 6)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.Size = UDim2.new(1, -155, 1, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.Text = labelText
	lbl.TextColor3 = C.text
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Position = UDim2.new(1, -142, 0, 0)
	valLbl.Size = UDim2.fromOffset(56, 30)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.Text = fmtFn(getFn())
	valLbl.TextColor3 = C.gold
	valLbl.TextSize = 11
	valLbl.Parent = row

	local minus = Instance.new("TextButton")
	minus.Size = UDim2.fromOffset(26, 22)
	minus.Position = UDim2.new(1, -82, 0.5, -11)
	minus.BackgroundColor3 = C.surface
	minus.Font = Enum.Font.GothamBold
	minus.Text = "−"
	minus.TextColor3 = C.text
	minus.TextSize = 12
	minus.Parent = row
	corner(minus, 5)

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.fromOffset(26, 22)
	plus.Position = UDim2.new(1, -52, 0.5, -11)
	plus.BackgroundColor3 = C.surface
	plus.Font = Enum.Font.GothamBold
	plus.Text = "+"
	plus.TextColor3 = C.text
	plus.TextSize = 12
	plus.Parent = row
	corner(plus, 5)

	local function updateText()
		valLbl.Text = fmtFn(getFn())
	end

	hook(minus.MouseButton1Click:Connect(function()
		local v = math.clamp(getFn() - step, minV, maxV)
		setFn(v)
		updateText()
		if onChange then onChange(v) end
	end))
	hook(plus.MouseButton1Click:Connect(function()
		local v = math.clamp(getFn() + step, minV, maxV)
		setFn(v)
		updateText()
		if onChange then onChange(v) end
	end))
end

local function syncAllToggles()
	for _, fn in ipairs(toggleSyncs) do fn() end
end

-- 1) قائمة الكل / الرئيسية (زر تفعيل/إلغاء مستقل لكل ميزة)
local homeP = makePage("Home")
addToggleRow(homeP, 10, "تفعيل / إلغاء الأيم بوت", function() return S.aimEnabled end, function(v) S.aimEnabled = v end, syncAllToggles)
addToggleRow(homeP, 46, "تفعيل / إلغاء الكشف + Cham", function() return S.espEnabled or S.espCham end, function(v) S.espEnabled = v; S.espCham = v end, function() updateVisuals(); syncAllToggles() end)
addToggleRow(homeP, 82, "تفعيل / إلغاء الهيت بوكس", function() return S.hitboxEnabled end, function(v) S.hitboxEnabled = v end, function() applyHitbox(); syncAllToggles() end)
addToggleRow(homeP, 118, "تفعيل / إلغاء التريقر بوت", function() return S.triggerEnabled end, function(v) S.triggerEnabled = v end, syncAllToggles)
homeP.CanvasSize = UDim2.fromOffset(0, 175)

-- 2) قائمة الأيم بوت
local aimP = makePage("Aim")
addToggleRow(aimP, 10, "تشغيل الأيم بوت", function() return S.aimEnabled end, function(v) S.aimEnabled = v end, syncAllToggles)
addToggleRow(aimP, 46, "التصويب عند كليك يمين فقط", function() return S.aimHoldRmb end, function(v) S.aimHoldRmb = v end)
addStepperRow(aimP, 82, "نطاق دائرة FOV", function() return S.aimFov end, function(v) S.aimFov = v end, 10, 30, 500, function(v) return tostring(v) .. "px" end, function(v)
	fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
addStepperRow(aimP, 118, "سرعة / نعومة التصويب", function() return S.aimSmooth end, function(v) S.aimSmooth = v end, 0.03, 0.03, 1, function(v) return string.format("%.2f", v) end)

local boneBtn = Instance.new("TextButton")
boneBtn.Size = UDim2.new(1, -20, 0, 28)
boneBtn.Position = UDim2.fromOffset(10, 154)
boneBtn.BackgroundColor3 = C.panel
boneBtn.Font = Enum.Font.GothamBold
boneBtn.Text = "جزء التصويب: " .. S.aimPart
boneBtn.TextColor3 = C.gold
boneBtn.TextSize = 11
boneBtn.Parent = aimP
corner(boneBtn, 6)
local bones = { "Head", "HumanoidRootPart", "UpperTorso" }
hook(boneBtn.MouseButton1Click:Connect(function()
	local idx = table.find(bones, S.aimPart) or 1
	S.aimPart = bones[(idx % #bones) + 1]
	boneBtn.Text = "جزء التصويب: " .. S.aimPart
end))
aimP.CanvasSize = UDim2.fromOffset(0, 210)

-- 3) قائمة الكشف و Cham
local espP = makePage("ESP")
addToggleRow(espP, 10, "إظهار الأسماء والمسافة", function() return S.espEnabled end, function(v) S.espEnabled = v end, function() updateVisuals(); syncAllToggles() end)
addToggleRow(espP, 46, "Player Cham (من وراء الجدار)", function() return S.espCham end, function(v) S.espCham = v end, function() updateVisuals(); syncAllToggles() end)
addToggleRow(espP, 82, "شريط الصحة الطولي بجانب اللاعب", function() return S.espHealthBar end, function(v) S.espHealthBar = v end, function() updateVisuals(); syncAllToggles() end)
addToggleRow(espP, 118, "إظهار دائرة FOV", function() return S.espCircle end, function(v) S.espCircle = v; fovCircle.Visible = v end, syncAllToggles)
espP.CanvasSize = UDim2.fromOffset(0, 180)

-- 4) قائمة الهيت بوكس
local hitP = makePage("Hitbox")
addToggleRow(hitP, 10, "تشغيل الهيت بوكس", function() return S.hitboxEnabled end, function(v) S.hitboxEnabled = v end, function() applyHitbox(); syncAllToggles() end)
addStepperRow(hitP, 46, "حجم الهيت بوكس", function() return S.hitboxSize end, function(v) S.hitboxSize = v end, 1, 2, 20, function(v) return tostring(v) end, function() applyHitbox() end)
addStepperRow(hitP, 82, "شفافية الهيت بوكس", function() return S.hitboxTrans end, function(v) S.hitboxTrans = v end, 0.05, 0.2, 0.98, function(v) return string.format("%.2f", v) end, function() applyHitbox() end)
hitP.CanvasSize = UDim2.fromOffset(0, 150)

-- 5) قائمة التريقر بوت
local trigP = makePage("Trigger")
addToggleRow(trigP, 10, "تشغيل التريقر بوت", function() return S.triggerEnabled end, function(v) S.triggerEnabled = v end, syncAllToggles)
addStepperRow(trigP, 46, "تأخير الإطلاق", function() return S.triggerDelay end, function(v) S.triggerDelay = v end, 0.01, 0, 0.3, function(v) return string.format("%.2fs", v) end)
trigP.CanvasSize = UDim2.fromOffset(0, 115)

-- 6) قائمة الإعدادات
local setP = makePage("Settings")
addToggleRow(setP, 10, "فحص الفريق (Team Check)", function() return S.teamCheck end, function(v) S.teamCheck = v end, function() updateVisuals(); syncAllToggles() end)
addStepperRow(setP, 46, "أقصى مسافة للكشف والتصويب", function() return S.maxRange end, function(v) S.maxRange = v end, 50, 100, 2500, function(v) return tostring(v) .. " studs" end, function() updateVisuals() end)

local tipLbl = Instance.new("TextLabel")
tipLbl.BackgroundTransparency = 1
tipLbl.Position = UDim2.fromOffset(12, 86)
tipLbl.Size = UDim2.new(1, -24, 0, 40)
tipLbl.Font = Enum.Font.Gotham
tipLbl.Text = "F1 لإخفاء وإظهار القائمة مع بقاء الميزات شغالة."
tipLbl.TextColor3 = C.muted
tipLbl.TextSize = 11
tipLbl.TextWrapped = true
tipLbl.TextXAlignment = Enum.TextXAlignment.Left
tipLbl.Parent = setP
setP.CanvasSize = UDim2.fromOffset(0, 150)

local function unloadAll()
	if not isRunning then return end
	isRunning = false
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
	restoreAllHitboxes()
	clearAllVisuals()
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
	env.ALASHBAT_FULL_UNLOAD = nil
end

env.ALASHBAT_FULL_UNLOAD = unloadAll
hook(closeBtn.MouseButton1Click:Connect(unloadAll))
hook(screenGui.Destroying:Connect(unloadAll))

local menuVisible = true
hook(UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F1 then
		menuVisible = not menuVisible
		main.Visible = menuVisible
	end
end))

hook(Players.PlayerRemoving:Connect(function(p)
	clearPlayerVisual(p)
end))

local function attachPlayer(p)
	if p == LocalPlayer then return end
	hook(p.CharacterAdded:Connect(function(char)
		clearPlayerVisual(p)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hook(hum.Died:Connect(function()
				clearPlayerVisual(p)
			end))
			hook(hum.HealthChanged:Connect(function()
				local pack = visualsMap[p]
				if pack then
					updateHealthSideBar(pack, hum)
				end
			end))
		end
	end))
end

for _, p in ipairs(Players:GetPlayers()) do
	attachPlayer(p)
end
hook(Players.PlayerAdded:Connect(attachPlayer))

hook(RunService.RenderStepped:Connect(function()
	if not isRunning or not screenGui.Parent then return end

	fovCircle.Visible = S.espCircle
	fovCircle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)

	if S.hitboxEnabled then
		applyHitbox()
	end

	if S.aimEnabled and Camera then
		local allowAim = (not S.aimHoldRmb) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if allowAim then
			local targetPart = getBestAimTarget()
			if targetPart then
				local goal = CFrame.new(Camera.CFrame.Position, targetPart.Position)
				Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(S.aimSmooth, 0.01, 1))
			end
		end
	end

	checkTriggerBot()
end))

task.spawn(function()
	while isRunning and screenGui.Parent do
		pcall(updateVisuals)
		task.wait(0.25)
	end
end)

selectTab("Home")
updateVisuals()
