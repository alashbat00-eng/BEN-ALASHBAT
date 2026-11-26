-- ALASHBAT PLAYER LAB — EXECUTOR EDITION
-- Ready for direct execution in a Roblox Executor environment

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
if not plr then return end

local connections = {}
local isRunning = true

local function trackConn(conn)
	if conn then
		table.insert(connections, conn)
	end
	return conn
end

local S = {
	lang = "EN",
	esp = true,
	boxes = false,
	distance = true,
	health = true,
	circle = true,
	fov = 135,
	maxRange = 750,
	teamCheck = true
}

local function T(en, ar)
	return S.lang == "AR" and ar or en
end

local function resolveGuiParent()
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then
			return h
		end
	end

	local okCore, resCore = pcall(function()
		local testFolder = Instance.new("Folder")
		testFolder.Name = "_Test_" .. tostring(math.random(1000, 9999))
		testFolder.Parent = CoreGui
		testFolder:Destroy()
		return CoreGui
	end)
	if okCore and resCore then
		return resCore
	end

	local pg = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 10)
	return pg
end

local guiParent = resolveGuiParent()
if not guiParent then return end

local gui = Instance.new("ScreenGui")
gui.Name = "ALASHBAT_PLAYER_LAB_EXEC"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10000
gui.Parent = guiParent

local function make(class, parent, props)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function round(inst, radius)
	make("UICorner", inst, { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(inst, color, thickness, transparency)
	return make("UIStroke", inst, {
		Color = color or Color3.fromRGB(225, 178, 62),
		Thickness = thickness or 1,
		Transparency = transparency or 0
	})
end

local theme = {
	bg = Color3.fromRGB(11, 12, 16),
	panel = Color3.fromRGB(18, 20, 26),
	card = Color3.fromRGB(25, 28, 36),
	top = Color3.fromRGB(20, 22, 29),
	gold = Color3.fromRGB(225, 178, 62),
	accent = Color3.fromRGB(80, 175, 255),
	white = Color3.fromRGB(240, 242, 245),
	muted = Color3.fromRGB(150, 156, 170),
	ok = Color3.fromRGB(85, 215, 130),
	warn = Color3.fromRGB(245, 110, 110)
}

local WIN_SIZE = UDim2.fromOffset(580, 410)
local MINI_SIZE = UDim2.fromOffset(580, 48)

local win = make("Frame", gui, {
	Name = "MainWindow",
	Size = WIN_SIZE,
	Position = UDim2.new(0.5, -290, 0.5, -205),
	BackgroundColor3 = theme.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true
})
round(win, 12)
stroke(win, theme.gold, 1.3, 0.15)

make("UISizeConstraint", win, {
	MinSize = Vector2.new(360, 48),
	MaxSize = Vector2.new(920, 720)
})

local top = make("Frame", win, {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = theme.top,
	BorderSizePixel = 0
})
round(top, 12)

local titleLbl = make("TextLabel", top, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(1, -175, 1, 0),
	Font = Enum.Font.GothamBlack,
	Text = "ALASHBAT  /  PLAYER LAB",
	TextColor3 = theme.gold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left
})

local function makeBtn(parent, text, size, pos, bgColor)
	local b = make("TextButton", parent, {
		Size = size,
		Position = pos,
		BackgroundColor3 = bgColor or theme.card,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = theme.white,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = true
	})
	round(b, 7)
	return b
end

local langBtn = makeBtn(top, "EN / AR", UDim2.fromOffset(68, 28), UDim2.new(1, -154, 0, 10))
local miniBtn = makeBtn(top, "—", UDim2.fromOffset(28, 28), UDim2.new(1, -78, 0, 10))
local closeBtn = makeBtn(top, "×", UDim2.fromOffset(28, 28), UDim2.new(1, -42, 0, 10), Color3.fromRGB(52, 26, 30))

local side = make("Frame", win, {
	Name = "Sidebar",
	Position = UDim2.fromOffset(10, 58),
	Size = UDim2.fromOffset(152, 342),
	BackgroundColor3 = theme.panel,
	BorderSizePixel = 0
})
round(side, 10)
stroke(side, theme.gold, 1, 0.75)

local content = make("Frame", win, {
	Name = "Content",
	Position = UDim2.fromOffset(172, 58),
	Size = UDim2.new(1, -182, 1, -68),
	BackgroundColor3 = theme.panel,
	BorderSizePixel = 0
})
round(content, 10)
stroke(content, theme.gold, 1, 0.75)

local pages, tabs = {}, {}
local refreshCallbacks = {}

local function createPage(key)
	local p = make("ScrollingFrame", content, {
		Name = key,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.gold,
		CanvasSize = UDim2.fromOffset(0, 340),
		Visible = false
	})
	pages[key] = p
	return p
end

local homePage = createPage("Home")
local visualPage = createPage("Visual")
local settingsPage = createPage("Settings")

local function addSection(parent, y, en, ar)
	local card = make("Frame", parent, {
		Position = UDim2.fromOffset(10, y),
		Size = UDim2.new(1, -20, 0, 30),
		BackgroundColor3 = theme.card,
		BorderSizePixel = 0
	})
	round(card, 7)
	local lbl = make("TextLabel", card, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = T(en, ar),
		TextColor3 = theme.gold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	table.insert(refreshCallbacks, function()
		lbl.Text = T(en, ar)
	end)
	return lbl
end

local function addRowLabel(parent, y, en, ar, color)
	local lbl = make("TextLabel", parent, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, y),
		Size = UDim2.new(1, -165, 0, 28),
		Font = Enum.Font.Gotham,
		Text = T(en, ar),
		TextColor3 = color or theme.white,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	table.insert(refreshCallbacks, function()
		lbl.Text = T(en, ar)
	end)
	return lbl
end

local function addToggle(parent, y, en, ar, key, onChanged)
	local lbl = addRowLabel(parent, y, en, ar)
	local btn = makeBtn(parent, "", UDim2.fromOffset(72, 26), UDim2.new(1, -86, 0, y + 1))

	local function sync()
		lbl.Text = T(en, ar)
		btn.Text = S[key] and T("ON", "مفعل") or T("OFF", "معطل")
		btn.TextColor3 = S[key] and theme.ok or theme.muted
		btn.BackgroundColor3 = S[key] and Color3.fromRGB(24, 46, 35) or theme.card
	end

	trackConn(btn.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		sync()
		if onChanged then onChanged(S[key]) end
	end))

	table.insert(refreshCallbacks, sync)
	return sync
end

local function addStepper(parent, y, en, ar, getVal, setVal, step, minVal, maxVal, formatFn, onChanged)
	local lbl = addRowLabel(parent, y, en, ar)
	local valLbl = make("TextLabel", parent, {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -166, 0, y),
		Size = UDim2.fromOffset(54, 28),
		Font = Enum.Font.GothamBold,
		Text = formatFn(getVal()),
		TextColor3 = theme.gold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center
	})

	local minus = makeBtn(parent, "−", UDim2.fromOffset(28, 26), UDim2.new(1, -108, 0, y + 1))
	local plus = makeBtn(parent, "+", UDim2.fromOffset(28, 26), UDim2.new(1, -74, 0, y + 1))

	local function refreshVal()
		lbl.Text = T(en, ar)
		valLbl.Text = formatFn(getVal())
	end

	trackConn(minus.MouseButton1Click:Connect(function()
		local nextVal = math.clamp(getVal() - step, minVal, maxVal)
		setVal(nextVal)
		refreshVal()
		if onChanged then onChanged(nextVal) end
	end))

	trackConn(plus.MouseButton1Click:Connect(function()
		local nextVal = math.clamp(getVal() + step, minVal, maxVal)
		setVal(nextVal)
		refreshVal()
		if onChanged then onChanged(nextVal) end
	end))

	table.insert(refreshCallbacks, refreshVal)
end

local function showPage(key)
	for k, p in pairs(pages) do
		p.Visible = (k == key)
	end
	for k, b in pairs(tabs) do
		local active = (k == key)
		b.BackgroundColor3 = active and Color3.fromRGB(58, 45, 22) or theme.card
		b.TextColor3 = active and theme.gold or theme.white
	end
end

local tabDefs = {
	{ "Home", "Overview", "الرئيسية" },
	{ "Visual", "Visuals", "المرئيات" },
	{ "Settings", "Settings", "الإعدادات" }
}

for i, d in ipairs(tabDefs) do
	local b = makeBtn(side, T(d[2], d[3]), UDim2.new(1, -14, 0, 38), UDim2.fromOffset(7, 10 + (i - 1) * 46))
	tabs[d[1]] = b
	trackConn(b.MouseButton1Click:Connect(function()
		showPage(d[1])
	end))
	table.insert(refreshCallbacks, function()
		b.Text = T(d[2], d[3])
	end)
end

-- دائرة المنتصف
local uiHidden = false
local fovCircle = make("Frame", gui, {
	Name = "CenterCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(S.fov * 2, S.fov * 2),
	BackgroundTransparency = 1,
	Visible = S.circle
})
make("UICorner", fovCircle, { CornerRadius = UDim.new(1, 0) })
stroke(fovCircle, theme.gold, 1.3, 0.2)

local function syncCircle()
	fovCircle.Size = UDim2.fromOffset(S.fov * 2, S.fov * 2)
	fovCircle.Visible = (not uiHidden) and S.circle
end

-- الرئيسية
addSection(homePage, 10, "PLAYER OVERVIEW", "نظرة عامة على اللاعبين")
local playersCountLbl = addRowLabel(homePage, 48, "Players tracked: 0", "اللاعبون المتابعون: 0", theme.gold)
local teamStatusLbl = addRowLabel(homePage, 78, "Team check: ON", "فحص الفريق: مفعل", theme.muted)
local rescanBtn = makeBtn(homePage, "", UDim2.fromOffset(140, 30), UDim2.fromOffset(16, 118))
homePage.CanvasSize = UDim2.fromOffset(0, 180)

-- المرئيات
addSection(visualPage, 10, "PLAYER LABELS & MARKERS", "عناوين ومؤشرات اللاعبين")
addToggle(visualPage, 48, "Player Labels", "عناوين اللاعبين", "esp")
addToggle(visualPage, 82, "Show Distance (studs)", "إظهار المسافة (studs)", "distance")
addToggle(visualPage, 116, "Show Health Bar", "إظهار شريط الصحة", "health")
addToggle(visualPage, 150, "Part Outline Boxes", "إطارات حول الأجزاء", "boxes")
addToggle(visualPage, 184, "Show Center Circle", "إظهار دائرة المنتصف", "circle", function()
	syncCircle()
end)
addStepper(visualPage, 218, "Circle Radius", "نصف قطر الدائرة",
	function() return S.fov end,
	function(v) S.fov = v end,
	10, 30, 500,
	function(v) return tostring(math.floor(v)) .. "px" end,
	function() syncCircle() end
)
visualPage.CanvasSize = UDim2.fromOffset(0, 280)

-- الإعدادات
addSection(settingsPage, 10, "PREFERENCES", "التفضيلات")
addToggle(settingsPage, 48, "Team Check", "تجاهل نفس الفريق", "teamCheck")
addStepper(settingsPage, 84, "Max Distance", "أقصى مسافة",
	function() return S.maxRange end,
	function(v) S.maxRange = v end,
	50, 50, 3000,
	function(v) return tostring(math.floor(v)) .. " studs" end
)
local shortcutLbl = addRowLabel(settingsPage, 128, "Shortcut: [F1] Hide / Show UI", "الاختصار: [F1] إخفاء / إظهار الواجهة", theme.muted)
settingsPage.CanvasSize = UDim2.fromOffset(0, 190)

local function shouldIncludePlayer(targetPlr)
	if not targetPlr or targetPlr == plr then return false end
	if not S.teamCheck then return true end
	if plr.Team and targetPlr.Team then
		return targetPlr.Team ~= plr.Team
	end
	return true
end

local function getTeamColor(targetPlr)
	if targetPlr.Team and targetPlr.TeamColor then
		return targetPlr.TeamColor.Color
	end
	return theme.gold
end

local function getEligiblePlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if shouldIncludePlayer(p) and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and hrp then
				table.insert(list, { player = p, char = p.Character, hum = hum, hrp = hrp })
			end
		end
	end
	return list
end

local espBillboards = {}
local partBoxes = {}

local function removePlayerVisuals(p)
	if espBillboards[p] then
		if espBillboards[p].Parent then
			espBillboards[p]:Destroy()
		end
		espBillboards[p] = nil
	end
	if partBoxes[p] then
		for _, box in ipairs(partBoxes[p]) do
			if box and box.Parent then
				box:Destroy()
			end
		end
		partBoxes[p] = nil
	end
end

local function clearAllVisuals()
	for p in pairs(espBillboards) do removePlayerVisuals(p) end
	for p in pairs(partBoxes) do removePlayerVisuals(p) end
end

local function updateHealthBarForPlayer(p, bb, hum)
	if not bb or not bb.Parent then return end
	local hpBg = bb:FindFirstChild("HPBg")
	if not hpBg then return end

	hpBg.Visible = S.health and hum ~= nil
	local hpFill = hpBg:FindFirstChild("HPFill")
	if hpFill and hum then
		local maxHp = math.max(hum.MaxHealth, 1)
		local ratio = math.clamp(hum.Health / maxHp, 0, 1)
		hpFill.Size = UDim2.fromScale(ratio, 1)
		hpFill.BackgroundColor3 = ratio > 0.45 and theme.ok or (ratio > 0.2 and theme.gold or theme.warn)
	end
end

local function updateVisuals()
	if not isRunning or not gui.Parent then return end

	local myChar = plr.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local activeSet = {}

	for _, entry in ipairs(getEligiblePlayers()) do
		local p = entry.player
		local char = entry.char
		local hum = entry.hum
		local hrp = entry.hrp

		local dist = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
		if dist <= S.maxRange then
			activeSet[p] = true
			local tColor = getTeamColor(p)

			if S.esp then
				local bb = espBillboards[p]
				if not bb or not bb.Parent then
					bb = make("BillboardGui", gui, {
						Name = "PlayerTag_" .. tostring(p.UserId),
						Size = UDim2.fromOffset(200, 40),
						StudsOffset = Vector3.new(0, 3.2, 0),
						AlwaysOnTop = true,
						Enabled = not uiHidden,
						Adornee = hrp
					})

					make("TextLabel", bb, {
						Name = "Title",
						Size = UDim2.new(1, 0, 0, 18),
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						TextSize = 12,
						TextColor3 = tColor,
						TextStrokeTransparency = 0.25
					})

					local hpBg = make("Frame", bb, {
						Name = "HPBg",
						Position = UDim2.fromOffset(40, 22),
						Size = UDim2.fromOffset(120, 5),
						BackgroundColor3 = Color3.fromRGB(25, 25, 30),
						BorderSizePixel = 0
					})
					round(hpBg, 3)

					local hpFill = make("Frame", hpBg, {
						Name = "HPFill",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = theme.ok,
						BorderSizePixel = 0
					})
					round(hpFill, 3)

					espBillboards[p] = bb
				end

				bb.Adornee = hrp
				bb.Enabled = not uiHidden
				local titleLbl = bb:FindFirstChild("Title")
				if titleLbl then
					local distStr = S.distance and (" [" .. math.floor(dist) .. " studs]") or ""
					titleLbl.Text = p.DisplayName .. distStr
					titleLbl.TextColor3 = tColor
				end
				updateHealthBarForPlayer(p, bb, hum)
			elseif espBillboards[p] then
				removePlayerVisuals(p)
			end

			if S.boxes then
				if not partBoxes[p] then
					partBoxes[p] = {}
					for _, partName in ipairs({ "Head", "HumanoidRootPart", "UpperTorso", "Torso" }) do
						local part = char:FindFirstChild(partName)
						if part and part:IsA("BasePart") then
							local box = make("SelectionBox", gui, {
								Adornee = part,
								Color3 = tColor,
								LineThickness = 0.03,
								SurfaceTransparency = 0.92,
								SurfaceColor3 = tColor,
								Visible = not uiHidden
							})
							table.insert(partBoxes[p], box)
						end
					end
				else
					for _, box in ipairs(partBoxes[p]) do
						if box then
							box.Color3 = tColor
							box.SurfaceColor3 = tColor
							box.Visible = not uiHidden
						end
					end
				end
			elseif partBoxes[p] then
				for _, box in ipairs(partBoxes[p]) do
					if box and box.Parent then box:Destroy() end
				end
				partBoxes[p] = nil
			end
		else
			removePlayerVisuals(p)
		end
	end

	for p in pairs(espBillboards) do
		if not activeSet[p] then removePlayerVisuals(p) end
	end
	for p in pairs(partBoxes) do
		if not activeSet[p] then removePlayerVisuals(p) end
	end
end

local function refreshAllTexts()
	titleLbl.Text = "ALASHBAT  /  PLAYER LAB"
	langBtn.Text = S.lang == "EN" and "EN / AR" or "AR / EN"
	rescanBtn.Text = T("Refresh List", "تحديث القائمة")
	shortcutLbl.Text = T("Shortcut: [F1] Hide / Show UI", "الاختصار: [F1] إخفاء / إظهار الواجهة")
	for _, cb in ipairs(refreshCallbacks) do
		cb()
	end
	playersCountLbl.Text = T("Players tracked: ", "اللاعبون المتابعون: ") .. tostring(#getEligiblePlayers())
	teamStatusLbl.Text = T("Team check: ", "فحص الفريق: ") .. (S.teamCheck and T("ON", "مفعل") or T("OFF", "معطل"))
end

trackConn(langBtn.MouseButton1Click:Connect(function()
	S.lang = (S.lang == "EN") and "AR" or "EN"
	refreshAllTexts()
end))

local minimized = false
trackConn(miniBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	side.Visible = not minimized
	content.Visible = not minimized
	TweenService:Create(win, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = minimized and MINI_SIZE or WIN_SIZE
	}):Play()
	miniBtn.Text = minimized and "+" or "—"
end))

local function cleanupAll()
	if not isRunning then return end
	isRunning = false
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
	clearAllVisuals()
	if gui and gui.Parent then
		gui:Destroy()
	end
end

trackConn(closeBtn.MouseButton1Click:Connect(cleanupAll))
trackConn(gui.Destroying:Connect(cleanupAll))

trackConn(rescanBtn.MouseButton1Click:Connect(function()
	updateVisuals()
	refreshAllTexts()
end))

-- سحب النافذة
local dragging, dragStart, startPos = false, nil, nil
trackConn(top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = win.Position
		local endedConn
		endedConn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if endedConn then endedConn:Disconnect() end
			end
		end)
		trackConn(endedConn)
	end
end))

trackConn(UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end))

-- إخفاء وإظهار كامل مع F1
local function setUiVisibility(hidden)
	uiHidden = hidden
	win.Visible = not uiHidden
	syncCircle()
	for _, bb in pairs(espBillboards) do
		if bb and bb.Parent then bb.Enabled = not uiHidden end
	end
	for _, list in pairs(partBoxes) do
		for _, box in ipairs(list) do
			if box and box.Parent then box.Visible = not uiHidden end
		end
	end
end

trackConn(UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F1 then
		setUiVisibility(not uiHidden)
	end
end))

trackConn(Players.PlayerRemoving:Connect(function(p)
	removePlayerVisuals(p)
end))

local function hookPlayer(p)
	trackConn(p.CharacterAdded:Connect(function(char)
		removePlayerVisuals(p)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			trackConn(hum.Died:Connect(function()
				removePlayerVisuals(p)
			end))
			trackConn(hum.HealthChanged:Connect(function()
				if espBillboards[p] then
					updateHealthBarForPlayer(p, espBillboards[p], hum)
				end
			end))
		end
	end))
	trackConn(p.CharacterRemoving:Connect(function()
		removePlayerVisuals(p)
	end))
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= plr then hookPlayer(p) end
end
trackConn(Players.PlayerAdded:Connect(function(p)
	if p ~= plr then hookPlayer(p) end
end))

-- تحديث مرئي منظم بدون ثقل مستمر
task.spawn(function()
	while isRunning and gui.Parent do
		pcall(updateVisuals)
		pcall(refreshAllTexts)
		task.wait(0.5)
	end
end)

showPage("Home")
refreshAllTexts()
syncCircle()
updateVisuals()
