--[[
	BEN ALASHBAT
	Hitbox + TriggerBot + ESP in one menu.
	Hide / show with F1 (Fn). Features keep running while the menu is hidden.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local env = (getgenv and getgenv()) or _G
if env.BEN_ALASHBAT_UNLOAD then
	pcall(env.BEN_ALASHBAT_UNLOAD)
end

local triggerEnabled = false
local triggerRunning = false
local teamCheck = true
local delay = 0.01

local hitboxEnabled = false
local hitboxSize = 5
local hitboxSaved = {}

local espEnabled = false
local espNames = true
local espHighlight = true
local espFolder = {}

local guiVisible = true
local connections = {}

local C = {
	bg = Color3.fromRGB(9, 9, 11),
	panel = Color3.fromRGB(12, 12, 14),
	surface = Color3.fromRGB(18, 18, 22),
	raised = Color3.fromRGB(26, 26, 32),
	accent = Color3.fromRGB(197, 164, 78),
	text = Color3.fromRGB(237, 236, 232),
	muted = Color3.fromRGB(138, 138, 146),
	stroke = Color3.fromRGB(40, 40, 46),
	off = Color3.fromRGB(52, 52, 60),
}

local function hook(conn)
	table.insert(connections, conn)
	return conn
end

local function getUiParent()
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and hui then
		return hui
	end
	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and core then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function fireClick()
	if typeof(mouse1click) == "function" then
		mouse1click()
		return
	end
	local pos = UserInputService:GetMouseLocation()
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
	end)
end

local notify

local CONFIG_FOLDER = "TriggerBotTest"
local CONFIG_FILE = "TriggerBotConfig.json"

local function saveConfig()
	pcall(function()
		if makefolder and isfolder and not isfolder(CONFIG_FOLDER) then
			makefolder(CONFIG_FOLDER)
		end
		if writefile then
			writefile(
				CONFIG_FOLDER .. "/" .. CONFIG_FILE,
				HttpService:JSONEncode({
					TriggerToggle = triggerEnabled,
					TeamCheck = teamCheck,
					DelaySlider = delay,
					HitboxEnabled = hitboxEnabled,
					HitboxSize = hitboxSize,
					EspEnabled = espEnabled,
					EspNames = espNames,
					EspHighlight = espHighlight,
				})
			)
		end
	end)
end

local function restoreHitboxPart(hrp)
	local orig = hitboxSaved[hrp]
	if orig and hrp and hrp.Parent then
		pcall(function()
			hrp.Size = orig.Size
			hrp.Transparency = orig.Transparency
			hrp.Color = orig.Color
			hrp.Material = orig.Material
			hrp.CanCollide = orig.CanCollide
		end)
	end
	hitboxSaved[hrp] = nil
end

local function restoreAllHitboxes()
	for hrp in pairs(hitboxSaved) do
		restoreHitboxPart(hrp)
	end
end

local function applyHitbox()
	if not hitboxEnabled then
		restoreAllHitboxes()
		return
	end
	local size = tonumber(hitboxSize)
	if not size or size <= 0 then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				if not hitboxSaved[hrp] then
					hitboxSaved[hrp] = {
						Size = hrp.Size,
						Transparency = hrp.Transparency,
						Color = hrp.Color,
						Material = hrp.Material,
						CanCollide = hrp.CanCollide,
					}
				end
				pcall(function()
					hrp.Size = Vector3.new(size, size, size)
					hrp.Transparency = 0.9
					hrp.Color = Color3.new(1, 1, 1)
					hrp.Material = Enum.Material.Neon
					hrp.CanCollide = false
				end)
			end
		end
	end
end

local function checkTrigger()
	while triggerEnabled do
		task.wait(delay)
		local target = Mouse.Target
		if target and target.Parent then
			local character = target.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if not player and character.Parent then
				player = Players:GetPlayerFromCharacter(character.Parent)
			end
			if player and player ~= LocalPlayer then
				if not teamCheck or player.Team ~= LocalPlayer.Team then
					fireClick()
					task.wait(0.05)
				end
			end
		end
	end
end

local function setTriggerEnabled(value)
	triggerEnabled = value and true or false
	saveConfig()
	if triggerEnabled and not triggerRunning then
		triggerRunning = true
		task.spawn(function()
			checkTrigger()
			triggerRunning = false
		end)
	end
end

local function destroyEsp(player)
	local pack = espFolder[player]
	if pack then
		pcall(function()
			if pack.highlight then
				pack.highlight:Destroy()
			end
			if pack.billboard then
				pack.billboard:Destroy()
			end
		end)
		espFolder[player] = nil
	end
end

local function clearEsp()
	for player in pairs(espFolder) do
		destroyEsp(player)
	end
end

local function applyEsp(player)
	if player == LocalPlayer then
		return
	end
	if not espEnabled then
		destroyEsp(player)
		return
	end
	local character = player.Character
	if not character then
		destroyEsp(player)
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not hrp then
		return
	end

	local pack = espFolder[player]
	if pack and pack.character ~= character then
		destroyEsp(player)
		pack = nil
	end
	if not pack then
		pack = { character = character }
		espFolder[player] = pack
	end

	if espHighlight then
		if not pack.highlight or pack.highlight.Parent == nil then
			local hl = Instance.new("Highlight")
			hl.Name = "BEN_ALASHBAT_HL"
			hl.Adornee = character
			hl.FillColor = Color3.new(1, 1, 1)
			hl.OutlineColor = Color3.new(1, 1, 1)
			hl.FillTransparency = 0.82
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = character
			pack.highlight = hl
		else
			pack.highlight.Adornee = character
			pack.highlight.Enabled = true
		end
	elseif pack.highlight then
		pack.highlight:Destroy()
		pack.highlight = nil
	end

	if espNames then
		local adorn = head or hrp
		if not pack.billboard or pack.billboard.Parent == nil then
			local bb = Instance.new("BillboardGui")
			bb.Name = "BEN_ALASHBAT_NAME"
			bb.AlwaysOnTop = true
			bb.Size = UDim2.new(0, 140, 0, 18)
			bb.StudsOffset = Vector3.new(0, 3.1, 0)
			bb.MaxDistance = 500
			bb.ResetOnSpawn = false
			bb.Adornee = adorn
			bb.Parent = adorn
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, 1, 0)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 12
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.45
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.Text = player.DisplayName
			label.Parent = bb
			pack.billboard = bb
			pack.label = label
		else
			pack.billboard.Adornee = adorn
			pack.billboard.Enabled = true
			if pack.label then
				pack.label.Text = player.DisplayName
			end
		end
	elseif pack.billboard then
		pack.billboard:Destroy()
		pack.billboard = nil
		pack.label = nil
	end
end

local function refreshEsp()
	if not espEnabled then
		clearEsp()
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		applyEsp(player)
	end
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or C.stroke
	s.Thickness = thickness or 1
	s.Transparency = trans or 0.35
	s.Parent = parent
	return s
end

local uiParent = getUiParent()
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BEN_ALASHBAT"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 1200
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screenGui)
	end
end)
screenGui.Parent = uiParent

local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.BackgroundTransparency = 1
toastHolder.Size = UDim2.new(1, 0, 1, 0)
toastHolder.ZIndex = 20
toastHolder.Parent = screenGui

notify = function(titleText, content, duration)
	duration = duration or 3
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 18)
	card.Size = UDim2.new(0, 240, 0, 52)
	card.BackgroundColor3 = C.panel
	card.ZIndex = 21
	card.Parent = toastHolder
	corner(card, 8)
	stroke(card, C.accent, 1, 0.45)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.new(0, 12, 0, 6)
	t.Size = UDim2.new(1, -24, 0, 16)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = C.accent
	t.Text = titleText
	t.ZIndex = 22
	t.Parent = card
	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Position = UDim2.new(0, 12, 0, 24)
	d.Size = UDim2.new(1, -24, 0, 20)
	d.Font = Enum.Font.Gotham
	d.TextSize = 11
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextColor3 = C.text
	d.TextWrapped = true
	d.Text = content
	d.ZIndex = 22
	d.Parent = card
	task.delay(duration, function()
		if card then
			card:Destroy()
		end
	end)
end

local main = Instance.new("Frame")
main.Name = "Main"
main.Active = true
main.BackgroundColor3 = C.panel
main.Position = UDim2.new(0, 20, 0.5, -154)
main.Size = UDim2.new(0, 268, 0, 308)
main.Parent = screenGui
corner(main, 10)
stroke(main, C.accent, 1, 0.55)

do
	local dragging = false
	local dragStart, startPos
	hook(main.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
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
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))
end

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundColor3 = C.bg
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.Parent = main
corner(titleBar, 10)
local titleMask = Instance.new("Frame")
titleMask.BackgroundColor3 = C.bg
titleMask.BorderSizePixel = 0
titleMask.Position = UDim2.new(0, 0, 1, -10)
titleMask.Size = UDim2.new(1, 0, 0, 10)
titleMask.Parent = titleBar

local accentLine = Instance.new("Frame")
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel = 0
accentLine.Position = UDim2.new(0, 0, 1, 0)
accentLine.Size = UDim2.new(1, 0, 0, 1)
accentLine.Parent = titleBar

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 0)
title.Size = UDim2.new(1, -36, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "BEN ALASHBAT"
title.TextColor3 = C.accent
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local hideBtn = Instance.new("TextButton")
hideBtn.BackgroundTransparency = 1
hideBtn.Position = UDim2.new(1, -28, 0, 2)
hideBtn.Size = UDim2.new(0, 26, 0, 26)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.Text = "-"
hideBtn.TextColor3 = C.muted
hideBtn.TextSize = 16
hideBtn.AutoButtonColor = false
hideBtn.Parent = titleBar

local tabBar = Instance.new("Frame")
tabBar.BackgroundColor3 = C.bg
tabBar.BorderSizePixel = 0
tabBar.Position = UDim2.new(0, 0, 0, 33)
tabBar.Size = UDim2.new(1, 0, 0, 28)
tabBar.Parent = main

local tabNames = { "Home", "Hitbox", "Trigger", "ESP" }
local tabButtons = {}
local pages = {}

local function setTab(name)
	for id, btn in pairs(tabButtons) do
		local on = id == name
		btn.TextColor3 = on and C.bg or C.muted
		btn.BackgroundColor3 = on and C.accent or C.surface
	end
	for id, page in pairs(pages) do
		page.Visible = id == name
	end
end

for i, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = C.surface
	btn.Position = UDim2.new(0, 6 + (i - 1) * 64, 0, 4)
	btn.Size = UDim2.new(0, 61, 0, 20)
	btn.Font = Enum.Font.GothamBold
	btn.Text = name
	btn.TextColor3 = C.muted
	btn.TextSize = 10
	btn.Parent = tabBar
	corner(btn, 4)
	tabButtons[name] = btn
	btn.MouseButton1Click:Connect(function()
		setTab(name)
	end)
end

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 62)
content.Size = UDim2.new(1, 0, 1, -84)
content.Parent = main

local function makePage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Visible = false
	page.Parent = content
	pages[name] = page
	return page
end

local function makeToggle(parent, y, label, default, callback)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 12, 0, y)
	row.Size = UDim2.new(1, -24, 0, 26)
	row.Parent = parent

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, -52, 1, 0)
	text.Font = Enum.Font.Gotham
	text.Text = label
	text.TextColor3 = C.text
	text.TextSize = 12
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = row

	local track = Instance.new("TextButton")
	track.AutoButtonColor = false
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, 0, 0.5, 0)
	track.Size = UDim2.new(0, 40, 0, 20)
	track.BackgroundColor3 = default and C.accent or C.off
	track.Text = ""
	track.Parent = row
	corner(track, 10)

	local knob = Instance.new("Frame")
	knob.BackgroundColor3 = C.bg
	knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Parent = track
	corner(knob, 8)

	local state = default
	local function render()
		track.BackgroundColor3 = state and C.accent or C.off
		knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	end
	track.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)
	return {
		set = function(v)
			state = v and true or false
			render()
		end,
	}
end

local function makeSlider(parent, y, label, minV, maxV, step, default, callback)
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Position = UDim2.new(0, 12, 0, y)
	wrap.Size = UDim2.new(1, -24, 0, 40)
	wrap.Parent = parent

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(0.7, 0, 0, 16)
	text.Font = Enum.Font.Gotham
	text.Text = label
	text.TextColor3 = C.text
	text.TextSize = 12
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = wrap

	local valueLbl = Instance.new("TextLabel")
	valueLbl.BackgroundTransparency = 1
	valueLbl.Position = UDim2.new(0.7, 0, 0, 0)
	valueLbl.Size = UDim2.new(0.3, 0, 0, 16)
	valueLbl.Font = Enum.Font.GothamBold
	valueLbl.TextColor3 = C.accent
	valueLbl.TextSize = 12
	valueLbl.TextXAlignment = Enum.TextXAlignment.Right
	valueLbl.Parent = wrap

	local bar = Instance.new("TextButton")
	bar.AutoButtonColor = false
	bar.BackgroundColor3 = C.raised
	bar.Position = UDim2.new(0, 0, 0, 22)
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Text = ""
	bar.Parent = wrap
	corner(bar, 4)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = C.accent
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = bar
	corner(fill, 4)

	local value = default
	local function render()
		local span = maxV - minV
		local alpha = span == 0 and 0 or (value - minV) / span
		fill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
		valueLbl.Text = string.format("%.2f", value)
	end
	local function setFromX(x)
		local absPos = bar.AbsolutePosition.X
		local absSize = bar.AbsoluteSize.X
		if absSize <= 0 then
			return
		end
		local a = math.clamp((x - absPos) / absSize, 0, 1)
		local raw = minV + a * (maxV - minV)
		value = math.floor(raw / step + 0.5) * step
		if value < minV then
			value = minV
		end
		if value > maxV then
			value = maxV
		end
		render()
		callback(value)
	end
	bar.MouseButton1Down:Connect(function()
		setFromX(UserInputService:GetMouseLocation().X)
		local move, up
		move = UserInputService.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				setFromX(UserInputService:GetMouseLocation().X)
			end
		end)
		up = UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				move:Disconnect()
				up:Disconnect()
			end
		end)
	end)
	render()
	return {
		set = function(v)
			value = v
			render()
		end,
	}
end

local function makeButton(parent, y, label, callback)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = C.surface
	btn.Position = UDim2.new(0, 12, 0, y)
	btn.Size = UDim2.new(1, -24, 0, 28)
	btn.Font = Enum.Font.GothamBold
	btn.Text = label
	btn.TextColor3 = C.text
	btn.TextSize = 12
	btn.Parent = parent
	corner(btn, 6)
	stroke(btn, C.stroke, 1, 0.2)
	btn.MouseButton1Click:Connect(callback)
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = C.raised
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = C.surface
	end)
	return btn
end

local home = makePage("Home")
local homeTitle = Instance.new("TextLabel")
homeTitle.BackgroundTransparency = 1
homeTitle.Position = UDim2.new(0, 12, 0, 8)
homeTitle.Size = UDim2.new(1, -24, 0, 22)
homeTitle.Font = Enum.Font.GothamBold
homeTitle.Text = "BEN ALASHBAT"
homeTitle.TextColor3 = C.text
homeTitle.TextSize = 16
homeTitle.TextXAlignment = Enum.TextXAlignment.Left
homeTitle.Parent = home

local homeSub = Instance.new("TextLabel")
homeSub.BackgroundTransparency = 1
homeSub.Position = UDim2.new(0, 12, 0, 30)
homeSub.Size = UDim2.new(1, -24, 0, 16)
homeSub.Font = Enum.Font.Gotham
homeSub.Text = "Hitbox  ·  TriggerBot  ·  ESP"
homeSub.TextColor3 = C.muted
homeSub.TextSize = 11
homeSub.TextXAlignment = Enum.TextXAlignment.Left
homeSub.Parent = home

local statusBox = Instance.new("Frame")
statusBox.BackgroundColor3 = C.surface
statusBox.Position = UDim2.new(0, 12, 0, 56)
statusBox.Size = UDim2.new(1, -24, 0, 78)
statusBox.Parent = home
corner(statusBox, 8)
stroke(statusBox, C.stroke, 1, 0.25)

local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Position = UDim2.new(0, 10, 0, 8)
statusLbl.Size = UDim2.new(1, -20, 1, -16)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 12
statusLbl.TextColor3 = C.text
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextYAlignment = Enum.TextYAlignment.Top
statusLbl.Parent = statusBox

local function refreshStatus()
	statusLbl.Text = string.format(
		"Hitbox      %s\nTriggerBot  %s\nESP         %s",
		hitboxEnabled and "ON" or "OFF",
		triggerEnabled and "ON" or "OFF",
		espEnabled and "ON" or "OFF"
	)
end

local homeHint = Instance.new("TextLabel")
homeHint.BackgroundTransparency = 1
homeHint.Position = UDim2.new(0, 12, 1, -48)
homeHint.Size = UDim2.new(1, -24, 0, 40)
homeHint.Font = Enum.Font.Gotham
homeHint.Text = "Press F1 (Fn) to hide or show this menu.\nActive features keep running."
homeHint.TextColor3 = C.muted
homeHint.TextSize = 11
homeHint.TextWrapped = true
homeHint.TextXAlignment = Enum.TextXAlignment.Left
homeHint.Parent = home

local hitPage = makePage("Hitbox")
local hitHead = Instance.new("TextLabel")
hitHead.BackgroundTransparency = 1
hitHead.Position = UDim2.new(0, 12, 0, 6)
hitHead.Size = UDim2.new(1, -24, 0, 18)
hitHead.Font = Enum.Font.GothamBold
hitHead.Text = "Hitbox"
hitHead.TextColor3 = C.text
hitHead.TextSize = 13
hitHead.TextXAlignment = Enum.TextXAlignment.Left
hitHead.Parent = hitPage

local hitNote = Instance.new("TextLabel")
hitNote.BackgroundTransparency = 1
hitNote.Position = UDim2.new(0, 12, 0, 24)
hitNote.Size = UDim2.new(1, -24, 0, 28)
hitNote.Font = Enum.Font.Gotham
hitNote.Text = "Resize other players' HumanoidRootPart."
hitNote.TextColor3 = C.muted
hitNote.TextSize = 11
hitNote.TextWrapped = true
hitNote.TextXAlignment = Enum.TextXAlignment.Left
hitNote.Parent = hitPage

local hitToggle = makeToggle(hitPage, 58, "Enable Hitbox", false, function(v)
	hitboxEnabled = v
	if not v then
		restoreAllHitboxes()
	end
	refreshStatus()
	saveConfig()
end)

local sizeLbl = Instance.new("TextLabel")
sizeLbl.BackgroundTransparency = 1
sizeLbl.Position = UDim2.new(0, 12, 0, 92)
sizeLbl.Size = UDim2.new(1, -24, 0, 16)
sizeLbl.Font = Enum.Font.Gotham
sizeLbl.Text = "Hitbox Size"
sizeLbl.TextColor3 = C.text
sizeLbl.TextSize = 12
sizeLbl.TextXAlignment = Enum.TextXAlignment.Left
sizeLbl.Parent = hitPage

local sizeBox = Instance.new("TextBox")
sizeBox.BackgroundColor3 = C.surface
sizeBox.Position = UDim2.new(0, 12, 0, 112)
sizeBox.Size = UDim2.new(1, -24, 0, 32)
sizeBox.Font = Enum.Font.GothamBold
sizeBox.PlaceholderText = "Put Number Here"
sizeBox.PlaceholderColor3 = C.muted
sizeBox.Text = tostring(hitboxSize)
sizeBox.TextColor3 = C.text
sizeBox.TextSize = 14
sizeBox.ClearTextOnFocus = false
sizeBox.Parent = hitPage
corner(sizeBox, 6)
stroke(sizeBox, C.stroke, 1, 0.2)

sizeBox.FocusLost:Connect(function()
	local n = tonumber(sizeBox.Text)
	if n and n > 0 then
		hitboxSize = n
		saveConfig()
	else
		sizeBox.Text = tostring(hitboxSize)
	end
end)

local trigPage = makePage("Trigger")
local trigHead = Instance.new("TextLabel")
trigHead.BackgroundTransparency = 1
trigHead.Position = UDim2.new(0, 12, 0, 4)
trigHead.Size = UDim2.new(1, -24, 0, 16)
trigHead.Font = Enum.Font.GothamBold
trigHead.Text = "TriggerBot"
trigHead.TextColor3 = C.text
trigHead.TextSize = 13
trigHead.TextXAlignment = Enum.TextXAlignment.Left
trigHead.Parent = trigPage

local trigToggle = makeToggle(trigPage, 28, "Enable TriggerBot", false, function(v)
	setTriggerEnabled(v)
	refreshStatus()
	if v then
		notify("TriggerBot", "Enabled - Aim at enemies and hold left click if needed", 3)
	end
end)

local teamToggle = makeToggle(trigPage, 58, "Team Check", true, function(v)
	teamCheck = v
	saveConfig()
end)

local delaySlider = makeSlider(trigPage, 90, "Trigger Delay", 0, 0.2, 0.01, delay, function(v)
	delay = v
	saveConfig()
end)

makeButton(trigPage, 148, "Test Notification", function()
	notify("Test", "TriggerBot script is working correctly!", 4)
end)

local espPage = makePage("ESP")
local espHead = Instance.new("TextLabel")
espHead.BackgroundTransparency = 1
espHead.Position = UDim2.new(0, 12, 0, 4)
espHead.Size = UDim2.new(1, -24, 0, 16)
espHead.Font = Enum.Font.GothamBold
espHead.Text = "ESP"
espHead.TextColor3 = C.text
espHead.TextSize = 13
espHead.TextXAlignment = Enum.TextXAlignment.Left
espHead.Parent = espPage

local espToggle = makeToggle(espPage, 28, "Enable ESP", false, function(v)
	espEnabled = v
	refreshEsp()
	refreshStatus()
	saveConfig()
end)

local namesToggle = makeToggle(espPage, 58, "Player Names", true, function(v)
	espNames = v
	refreshEsp()
	saveConfig()
end)

local hlToggle = makeToggle(espPage, 88, "White Highlight / Outline", true, function(v)
	espHighlight = v
	refreshEsp()
	saveConfig()
end)

local espNote = Instance.new("TextLabel")
espNote.BackgroundTransparency = 1
espNote.Position = UDim2.new(0, 12, 0, 124)
espNote.Size = UDim2.new(1, -24, 0, 48)
espNote.Font = Enum.Font.Gotham
espNote.Text =
	"Names sit above characters. Outline is white and light — disable ESP to clear everything."
espNote.TextColor3 = C.muted
espNote.TextSize = 11
espNote.TextWrapped = true
espNote.TextXAlignment = Enum.TextXAlignment.Left
espNote.Parent = espPage

local footer = Instance.new("TextLabel")
footer.BackgroundColor3 = C.bg
footer.Position = UDim2.new(0, 0, 1, -22)
footer.Size = UDim2.new(1, 0, 0, 22)
footer.Font = Enum.Font.Gotham
footer.Text = "F1  hide / show"
footer.TextColor3 = C.muted
footer.TextSize = 10
footer.Parent = main

setTab("Home")
refreshStatus()

local function setGuiVisible(vis)
	guiVisible = vis
	main.Visible = vis
end

hideBtn.MouseButton1Click:Connect(function()
	setGuiVisible(false)
end)

hook(UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F1 then
		setGuiVisible(not guiVisible)
	end
end))

hook(RunService.RenderStepped:Connect(function()
	if hitboxEnabled then
		applyHitbox()
	end
end))

local espAccum = 0
hook(RunService.Heartbeat:Connect(function(dt)
	if not espEnabled then
		return
	end
	espAccum += dt
	if espAccum < 0.15 then
		return
	end
	espAccum = 0
	refreshEsp()
end))

hook(Players.PlayerRemoving:Connect(function(player)
	destroyEsp(player)
end))

local function unload()
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	triggerEnabled = false
	hitboxEnabled = false
	espEnabled = false
	restoreAllHitboxes()
	clearEsp()
	if screenGui then
		screenGui:Destroy()
	end
	env.BEN_ALASHBAT_UNLOAD = nil
end
env.BEN_ALASHBAT_UNLOAD = unload

pcall(function()
	if not readfile then
		return
	end
	local path = CONFIG_FOLDER .. "/" .. CONFIG_FILE
	if isfile and not isfile(path) then
		return
	end
	local data = HttpService:JSONDecode(readfile(path))
	if typeof(data) ~= "table" then
		return
	end
	if data.TeamCheck ~= nil then
		teamCheck = data.TeamCheck
		teamToggle.set(teamCheck)
	end
	if typeof(data.DelaySlider) == "number" then
		delay = data.DelaySlider
		delaySlider.set(delay)
	end
	if typeof(data.HitboxSize) == "number" then
		hitboxSize = data.HitboxSize
		sizeBox.Text = tostring(hitboxSize)
	end
	if data.EspNames ~= nil then
		espNames = data.EspNames
		namesToggle.set(espNames)
	end
	if data.EspHighlight ~= nil then
		espHighlight = data.EspHighlight
		hlToggle.set(espHighlight)
	end
	if data.HitboxEnabled then
		hitboxEnabled = true
		hitToggle.set(true)
	end
	if data.EspEnabled then
		espEnabled = true
		espToggle.set(true)
		refreshEsp()
	end
	if data.TriggerToggle then
		trigToggle.set(true)
		setTriggerEnabled(true)
	end
	refreshStatus()
end)
