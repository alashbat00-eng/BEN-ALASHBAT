-- ALASHBAT LAB — GOTHAM EDITION
-- Complete self-contained script for Roblox Executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.ALASHBAT_GOTHAM_UNLOAD then
	pcall(env.ALASHBAT_GOTHAM_UNLOAD)
end

local isRunning = true
local connections = {}
local listeningForKey = false

local function hook(conn)
	if conn then
		table.insert(connections, conn)
	end
	return conn
end

local function randId(prefix)
	local pool = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local t = { prefix or "G" }
	for _ = 1, 8 do
		local idx = math.random(1, #pool)
		table.insert(t, string.sub(pool, idx, idx))
	end
	return table.concat(t)
end

local GUI_NAME = randId("G_")
local TAG_NAME = randId("T_")
local CHAM_NAME = randId("C_")
local CONFIG_FOLDER = "AlashbatGothamCfg"
local CONFIG_PATHS = {
	CONFIG_FOLDER .. "/settings.json",
	"AlashbatGotham_settings.json"
}

local S = {
	lang = "AR", -- "AR" | "EN"
	menuOpen = true,

	-- Aimbot & Recoil
	aimEnabled = false,
	rotateCharacter = true,
	aimPart = "Head",
	aimFov = 145,
	aimSmooth = 0.45,
	aimBehavior = "HOLD", -- "HOLD" | "TOGGLE"
	aimBindType = "MouseButton", -- "MouseButton" | "KeyCode"
	aimKeyName = "MouseButton2",
	noRecoilEnabled = true,
	noRecoilStrength = 0.8,

	-- Visuals
	espEnabled = true,
	espNames = true,
	espDistance = true,
	espHealthBar = true,
	espCham = true,
	espCircle = true,

	-- Movement
	moveEnabled = false,
	walkSpeed = 28,
	jumpPower = 75,

	-- Hitbox & Trigger
	hitboxEnabled = false,
	hitboxSize = 6,
	hitboxTrans = 0.9,
	triggerEnabled = false,
	triggerDelay = 0.03,

	-- Filters
	teamCheck = true,
	maxRange = 800,
	eyeComfort = true
}

local aimToggled = false

local function T(ar, en)
	return S.lang == "AR" and ar or en
end

local function applyDecodedSettings(decoded)
	if typeof(decoded) ~= "table" then return false end
	for k, v in pairs(decoded) do
		if S[k] ~= nil and type(v) == type(S[k]) then
			S[k] = v
		end
	end
	return true
end

local function saveConfig()
	local payload = HttpService:JSONEncode(S)
	env.ALASHBAT_SAVED_CONFIG = payload

	local fileSaved = false
	pcall(function()
		if typeof(makefolder) == "function" then
			local hasFolder = false
			if typeof(isfolder) == "function" then
				local okF, resF = pcall(isfolder, CONFIG_FOLDER)
				hasFolder = (okF and resF == true)
			end
			if not hasFolder then
				pcall(makefolder, CONFIG_FOLDER)
			end
		end
	end)

	if typeof(writefile) == "function" then
		for _, p in ipairs(CONFIG_PATHS) do
			local okW = pcall(writefile, p, payload)
			if okW then
				fileSaved = true
			end
		end
	end

	return fileSaved, true
end

local function loadConfig()
	local loaded = false

	if typeof(readfile) == "function" then
		for _, p in ipairs(CONFIG_PATHS) do
			local exists = true
			if typeof(isfile) == "function" then
				local okEx, resEx = pcall(isfile, p)
				exists = (okEx and resEx == true)
			end
			if exists then
				local okR, raw = pcall(readfile, p)
				if okR and type(raw) == "string" and #raw > 2 then
					local okJ, decoded = pcall(function()
						return HttpService:JSONDecode(raw)
					end)
					if okJ and applyDecodedSettings(decoded) then
						loaded = true
						break
					end
				end
			end
		end
	end

	if not loaded and type(env.ALASHBAT_SAVED_CONFIG) == "string" then
		local okJ, decoded = pcall(function()
			return HttpService:JSONDecode(env.ALASHBAT_SAVED_CONFIG)
		end)
		if okJ then
			applyDecodedSettings(decoded)
		end
	end
end

loadConfig()

local function getAimBindDisplay()
	if S.aimKeyName == "MouseButton2" then
		return T("كليك يمين (RMB)", "Right Click (RMB)")
	elseif S.aimKeyName == "MouseButton1" then
		return T("كليك يسار (LMB)", "Left Click (LMB)")
	elseif S.aimKeyName == "MouseButton3" then
		return T("عجلة الماوس (MMB)", "Middle Click (MMB)")
	end
	return S.aimKeyName
end

local function isAimBindPressed()
	if listeningForKey then return false end
	if S.aimBindType == "MouseButton" then
		local enumItem = Enum.UserInputType[S.aimKeyName]
		return enumItem and UserInputService:IsMouseButtonPressed(enumItem) or false
	else
		local enumItem = Enum.KeyCode[S.aimKeyName]
		return enumItem and UserInputService:IsKeyDown(enumItem) or false
	end
end

local function matchesAimInput(input)
	if S.aimBindType == "MouseButton" then
		return input.UserInputType.Name == S.aimKeyName
	else
		return input.KeyCode.Name == S.aimKeyName
	end
end

local function resolveUiParent()
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local okCore, core = pcall(function()
		local probe = Instance.new("Folder")
		probe.Name = randId("P_")
		probe.Parent = game:GetService("CoreGui")
		probe:Destroy()
		return game:GetService("CoreGui")
	end)
	if okCore and core then return core end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
end

local uiParent = resolveUiParent()
if not uiParent then return end

-- لوحة ألوان هادئة ومريحة للعين مستوحاة من الصورة + لمسة باتمان الذهبية
local C = {
	outerBg = Color3.fromRGB(16, 17, 20),
	sideBg = Color3.fromRGB(20, 21, 25),
	cardBg = Color3.fromRGB(26, 28, 33),
	rowBg = Color3.fromRGB(32, 34, 40),
	trackOff = Color3.fromRGB(62, 66, 76),
	sliderBg = Color3.fromRGB(46, 49, 58),
	accent = Color3.fromRGB(218, 176, 56),
	accentSoft = Color3.fromRGB(145, 118, 42),
	text = Color3.fromRGB(228, 230, 236),
	muted = Color3.fromRGB(138, 143, 156),
	line = Color3.fromRGB(46, 49, 58),
	ok = Color3.fromRGB(84, 198, 132),
	danger = Color3.fromRGB(224, 96, 106)
}

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end

local function stroke(inst, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = col or C.line
	s.Thickness = thick or 1
	s.Transparency = trans or 0.35
	s.Parent = inst
	return s
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 2500
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screenGui)
	elseif protect_gui then
		protect_gui(screenGui)
	end
end)
screenGui.Parent = uiParent

-- فحص الأعداء والفرق
local function isEnemy(player)
	if not player or player == LocalPlayer then return false end
	if not S.teamCheck then return true end
	if LocalPlayer.Team and player.Team then
		return player.Team ~= LocalPlayer.Team
	end
	return true
end

local function getEspColor(player)
	if player.Team and player.TeamColor and not S.eyeComfort then
		return player.TeamColor.Color
	end
	return Color3.fromRGB(226, 192, 88)
end

local function getTargets()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if isEnemy(p) and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and hrp then
				table.insert(out, { player = p, char = p.Character, hum = hum, hrp = hrp })
			end
		end
	end
	return out
end

-- دائرة FOV مريحة للعين
local fovCircle = Instance.new("Frame")
fovCircle.Name = randId("F_")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = S.espCircle
fovCircle.Parent = screenGui
round(fovCircle, 999)
stroke(fovCircle, C.accent, 1.2, 0.4)

-- نظام ESP + شريط صحة عمودي بجانب اللاعب + Cham
local espMap = {}

local function clearPlayerEsp(p)
	local pack = espMap[p]
	if pack then
		pcall(function()
			if pack.highlight then pack.highlight:Destroy() end
			if pack.billboard then pack.billboard:Destroy() end
		end)
		espMap[p] = nil
	end
end

local function clearAllEsp()
	for p in pairs(espMap) do
		clearPlayerEsp(p)
	end
end

local function refreshSideHealth(pack, hum)
	if not pack or not pack.hpBg or not pack.hpFill then return end
	pack.hpBg.Visible = S.espHealthBar and hum ~= nil
	if hum then
		local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		pack.hpFill.Size = UDim2.new(1, 0, ratio, 0)
		pack.hpFill.Position = UDim2.new(0, 0, 1 - ratio, 0)
		pack.hpFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(92, 198, 138) or (ratio > 0.25 and C.accent or Color3.fromRGB(220, 104, 112))
	end
end

local function updateEsp()
	if not isRunning or not screenGui.Parent then return end

	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local active = {}

	for _, entry in ipairs(getTargets()) do
		local p = entry.player
		local char = entry.char
		local hum = entry.hum
		local hrp = entry.hrp

		local dist = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
		if dist <= S.maxRange then
			active[p] = true
			local col = getEspColor(p)

			local pack = espMap[p]
			if not pack or pack.char ~= char then
				clearPlayerEsp(p)
				pack = { char = char }
				espMap[p] = pack
			end

			if S.espCham then
				if not pack.highlight or not pack.highlight.Parent then
					local hl = Instance.new("Highlight")
					hl.Name = CHAM_NAME
					hl.Adornee = char
					hl.FillColor = col
					hl.OutlineColor = C.accent
					hl.FillTransparency = 0.76
					hl.OutlineTransparency = 0.2
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = char
					pack.highlight = hl
				else
					pack.highlight.Adornee = char
					pack.highlight.FillColor = col
					pack.highlight.Enabled = true
				end
			elseif pack.highlight then
				pack.highlight:Destroy()
				pack.highlight = nil
			end

			if S.espEnabled or S.espHealthBar then
				if not pack.billboard or not pack.billboard.Parent then
					local bb = Instance.new("BillboardGui")
					bb.Name = TAG_NAME
					bb.AlwaysOnTop = true
					bb.Size = UDim2.fromOffset(170, 68)
					bb.StudsOffset = Vector3.new(0, 0.3, 0)
					bb.Adornee = hrp
					bb.Parent = screenGui

					local lbl = Instance.new("TextLabel")
					lbl.Name = "Label"
					lbl.BackgroundTransparency = 1
					lbl.Position = UDim2.fromOffset(0, 0)
					lbl.Size = UDim2.new(1, 0, 0, 18)
					lbl.Font = Enum.Font.GothamMedium
					lbl.TextSize = 12
					lbl.TextColor3 = col
					lbl.TextStrokeTransparency = 0.5
					lbl.Parent = bb

					local hpBg = Instance.new("Frame")
					hpBg.Name = "SideHPBg"
					hpBg.Position = UDim2.fromOffset(20, 20)
					hpBg.Size = UDim2.fromOffset(5, 44)
					hpBg.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
					hpBg.BorderSizePixel = 0
					hpBg.Parent = bb
					round(hpBg, 2)

					local hpFill = Instance.new("Frame")
					hpFill.Name = "SideHPFill"
					hpFill.Size = UDim2.fromScale(1, 1)
					hpFill.BackgroundColor3 = Color3.fromRGB(92, 198, 138)
					hpFill.BorderSizePixel = 0
					hpFill.Parent = hpBg
					round(hpFill, 2)

					pack.billboard = bb
					pack.lbl = lbl
					pack.hpBg = hpBg
					pack.hpFill = hpFill
				else
					pack.billboard.Adornee = hrp
				end

				pack.billboard.Enabled = true
				if pack.lbl then
					pack.lbl.Visible = S.espEnabled and (S.espNames or S.espDistance)
					local info = {}
					if S.espNames then table.insert(info, p.DisplayName) end
					if S.espDistance then table.insert(info, math.floor(dist) .. "m") end
					pack.lbl.Text = table.concat(info, " · ")
					pack.lbl.TextColor3 = col
				end
				refreshSideHealth(pack, hum)
			elseif pack.billboard then
				pack.billboard:Destroy()
				pack.billboard = nil
				pack.lbl = nil
				pack.hpBg = nil
				pack.hpFill = nil
			end
		else
			clearPlayerEsp(p)
		end
	end

	for p in pairs(espMap) do
		if not active[p] then
			clearPlayerEsp(p)
		end
	end
end

-- نظام الحركة
local moveBackup = { hum = nil, ws = nil, jp = nil, jh = nil, ujp = nil }
local function restoreMove()
	local hum = moveBackup.hum
	if hum and hum.Parent then
		pcall(function()
			if moveBackup.ws then hum.WalkSpeed = moveBackup.ws end
			if moveBackup.ujp ~= nil then hum.UseJumpPower = moveBackup.ujp end
			if moveBackup.jp then hum.JumpPower = moveBackup.jp end
			if moveBackup.jh then hum.JumpHeight = moveBackup.jh end
		end)
	end
	moveBackup.hum, moveBackup.ws, moveBackup.jp, moveBackup.jh, moveBackup.ujp = nil, nil, nil, nil, nil
end

local function applyMove()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if not S.moveEnabled then
		restoreMove()
		return
	end
	if moveBackup.hum ~= hum then
		restoreMove()
		moveBackup.hum = hum
		moveBackup.ws = hum.WalkSpeed
		moveBackup.ujp = hum.UseJumpPower
		moveBackup.jp = hum.JumpPower
		moveBackup.jh = hum.JumpHeight
	end
	pcall(function()
		hum.WalkSpeed = S.walkSpeed
		hum.UseJumpPower = true
		hum.JumpPower = S.jumpPower
	end)
end

-- نظام Hitbox
local hbSaved = {}
local function restoreHbPart(hrp)
	local orig = hbSaved[hrp]
	if orig and hrp and hrp.Parent then
		pcall(function()
			hrp.Size = orig.Size
			hrp.Transparency = orig.Transparency
			hrp.CanCollide = orig.CanCollide
		end)
	end
	hbSaved[hrp] = nil
end

local function restoreAllHb()
	for hrp in pairs(hbSaved) do
		restoreHbPart(hrp)
	end
end

local function applyHb()
	if not S.hitboxEnabled then
		restoreAllHb()
		return
	end
	local sz = math.clamp(S.hitboxSize, 2, 22)
	for _, entry in ipairs(getTargets()) do
		local hrp = entry.hrp
		if hrp and hrp.Parent then
			if not hbSaved[hrp] then
				hbSaved[hrp] = { Size = hrp.Size, Transparency = hrp.Transparency, CanCollide = hrp.CanCollide }
			end
			pcall(function()
				hrp.Size = Vector3.new(sz, sz, sz)
				hrp.Transparency = S.hitboxTrans
				hrp.CanCollide = false
			end)
		end
	end
end

-- نظام Aimbot حقيقي (توجيه الكاميرا + لف الشخصية + مواءمة موضع الماوس) + No Recoil
local function getBestTargetPart()
	Camera = Workspace.CurrentCamera
	if not Camera then return nil, nil end
	local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	local bestPart, bestRoot, bestDist = nil, nil, math.huge
	for _, entry in ipairs(getTargets()) do
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
						bestRoot = hrp
					end
				end
			end
		end
	end
	return bestPart, bestRoot
end

local lastCamCFrame = nil
local function applyNoRecoil(cam)
	if not S.noRecoilEnabled or not cam then
		lastCamCFrame = cam and cam.CFrame or nil
		return
	end
	local shooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	if shooting and lastCamCFrame then
		local pos = cam.CFrame.Position
		local prevLook = lastCamCFrame.LookVector
		local curLook = cam.CFrame.LookVector
		local dampedLook = curLook:Lerp(prevLook, math.clamp(S.noRecoilStrength * 0.45, 0, 0.85)).Unit
		cam.CFrame = CFrame.lookAt(pos, pos + dampedLook)
	end
	lastCamCFrame = cam.CFrame
end

local function applyAimbot(cam)
	local active = (S.aimBehavior == "HOLD" and isAimBindPressed()) or (S.aimBehavior == "TOGGLE" and aimToggled)
	if not S.aimEnabled or not active or not cam then return end

	local targetPart, targetRoot = getBestTargetPart()
	if not targetPart then return end

	local alpha = math.clamp(S.aimSmooth, 0.05, 1)
	local camGoal = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
	cam.CFrame = cam.CFrame:Lerp(camGoal, alpha)

	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local focusPos = targetRoot and targetRoot.Position or targetPart.Position
	if S.rotateCharacter and myRoot then
		local flatTarget = Vector3.new(focusPos.X, myRoot.Position.Y, focusPos.Z)
		if (flatTarget - myRoot.Position).Magnitude > 0.05 then
			local charGoal = CFrame.lookAt(myRoot.Position, flatTarget)
			myRoot.CFrame = myRoot.CFrame:Lerp(charGoal, math.clamp(alpha * 1.35, 0.08, 1))
		end
	end

	local proj, onScreen = cam:WorldToViewportPoint(targetPart.Position)
	if onScreen and proj.Z > 0 and typeof(mousemoverel) == "function" then
		local curMouse = UserInputService:GetMouseLocation()
		local dx = (proj.X - curMouse.X) * math.clamp(alpha * 0.65, 0.05, 0.75)
		local dy = (proj.Y - curMouse.Y) * math.clamp(alpha * 0.65, 0.05, 0.75)
		if math.abs(dx) > 0.5 or math.abs(dy) > 0.5 then
			pcall(mousemoverel, dx, dy)
		end
	end
end

-- نظام TriggerBot
local lastShotTime = 0
local function triggerClick()
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

local function updateTrigger()
	if not S.triggerEnabled then return end
	local now = os.clock()
	if (now - lastShotTime) < S.triggerDelay then return end
	local t = Mouse.Target
	if t and t.Parent then
		local char = t.Parent
		local p = Players:GetPlayerFromCharacter(char)
		if not p and char.Parent then
			p = Players:GetPlayerFromCharacter(char.Parent)
		end
		if p and isEnemy(p) then
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				lastShotTime = now
				triggerClick()
			end
		end
	end
end

-- الواجهة الهادئة المطابقة لترتيب الصورة مع ثيم باتمان الذهبي الخفيف
local win = Instance.new("Frame")
win.Name = randId("W_")
win.Active = true
win.BackgroundColor3 = C.outerBg
win.Position = UDim2.new(0.5, -400, 0.5, -235)
win.Size = UDim2.fromOffset(800, 470)
win.ClipsDescendants = true
win.Parent = screenGui
round(win, 18)
stroke(win, C.line, 1.2, 0.25)

do
	local dragging, dragStart, startPos = false, nil, nil
	hook(win.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = win.Position
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
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
end

local sidebar = Instance.new("Frame")
sidebar.BackgroundColor3 = C.sideBg
sidebar.Position = UDim2.fromOffset(12, 12)
sidebar.Size = UDim2.fromOffset(192, 446)
sidebar.BorderSizePixel = 0
sidebar.Parent = win
round(sidebar, 14)
stroke(sidebar, C.line, 1, 0.35)

local headerCard = Instance.new("Frame")
headerCard.BackgroundColor3 = C.cardBg
headerCard.Position = UDim2.fromOffset(12, 12)
headerCard.Size = UDim2.new(1, -24, 0, 56)
headerCard.BorderSizePixel = 0
headerCard.Parent = sidebar
round(headerCard, 10)
stroke(headerCard, C.line, 1, 0.4)

local batOval = Instance.new("Frame")
batOval.AnchorPoint = Vector2.new(0, 0.5)
batOval.Position = UDim2.new(0, 10, 0.5, 0)
batOval.Size = UDim2.fromOffset(48, 28)
batOval.BackgroundColor3 = C.accent
batOval.BorderSizePixel = 0
batOval.Parent = headerCard
round(batOval, 14)

local batCore = Instance.new("Frame")
batCore.AnchorPoint = Vector2.new(0.5, 0.5)
batCore.Position = UDim2.fromScale(0.5, 0.5)
batCore.Size = UDim2.new(1, -4, 1, -4)
batCore.BackgroundColor3 = C.outerBg
batCore.BorderSizePixel = 0
batCore.Parent = batOval
round(batCore, 12)

local batTag = Instance.new("TextLabel")
batTag.Size = UDim2.fromScale(1, 1)
batTag.BackgroundTransparency = 1
batTag.Font = Enum.Font.GothamBlack
batTag.Text = "BAT"
batTag.TextColor3 = C.accent
batTag.TextSize = 9
batTag.Parent = batCore

local brandTitle = Instance.new("TextLabel")
brandTitle.BackgroundTransparency = 1
brandTitle.Position = UDim2.fromOffset(66, 9)
brandTitle.Size = UDim2.new(1, -74, 0, 18)
brandTitle.Font = Enum.Font.GothamBold
brandTitle.Text = "ALASHBAT"
brandTitle.TextColor3 = C.text
brandTitle.TextSize = 13
brandTitle.TextXAlignment = Enum.TextXAlignment.Left
brandTitle.Parent = headerCard

local brandSub = Instance.new("TextLabel")
brandSub.BackgroundTransparency = 1
brandSub.Position = UDim2.fromOffset(66, 28)
brandSub.Size = UDim2.new(1, -74, 0, 16)
brandSub.Font = Enum.Font.Gotham
brandSub.Text = "Gotham Client"
brandSub.TextColor3 = C.muted
brandSub.TextSize = 10
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = headerCard

local mainArea = Instance.new("Frame")
mainArea.BackgroundTransparency = 1
mainArea.Position = UDim2.fromOffset(214, 12)
mainArea.Size = UDim2.new(1, -226, 1, -24)
mainArea.Parent = win

local topStrip = Instance.new("Frame")
topStrip.BackgroundColor3 = C.sideBg
topStrip.Position = UDim2.fromOffset(0, 0)
topStrip.Size = UDim2.new(1, 0, 0, 44)
topStrip.Parent = mainArea
round(topStrip, 12)
stroke(topStrip, C.line, 1, 0.35)

local pageTitle = Instance.new("TextLabel")
pageTitle.BackgroundTransparency = 1
pageTitle.Position = UDim2.fromOffset(14, 0)
pageTitle.Size = UDim2.new(1, -230, 1, 0)
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextSize = 14
pageTitle.TextColor3 = C.text
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Parent = topStrip

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.fromOffset(102, 26)
saveBtn.Position = UDim2.new(1, -216, 0.5, -13)
saveBtn.BackgroundColor3 = C.cardBg
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 10
saveBtn.TextColor3 = C.ok
saveBtn.Parent = topStrip
round(saveBtn, 6)
stroke(saveBtn, C.line, 1, 0.3)

local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.fromOffset(68, 26)
langBtn.Position = UDim2.new(1, -106, 0.5, -13)
langBtn.BackgroundColor3 = C.cardBg
langBtn.Font = Enum.Font.GothamBold
langBtn.Text = "AR / EN"
langBtn.TextColor3 = C.accent
langBtn.TextSize = 11
langBtn.Parent = topStrip
round(langBtn, 6)
stroke(langBtn, C.line, 1, 0.3)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 26)
closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
closeBtn.BackgroundColor3 = C.cardBg
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = C.danger
closeBtn.TextSize = 15
closeBtn.Parent = topStrip
round(closeBtn, 6)
stroke(closeBtn, C.line, 1, 0.3)

local bodyArea = Instance.new("Frame")
bodyArea.BackgroundTransparency = 1
bodyArea.Position = UDim2.fromOffset(0, 52)
bodyArea.Size = UDim2.new(1, 0, 1, -52)
bodyArea.Parent = mainArea

local pages, navBtns = {}, {}
local refreshers = {}
local currentTab = "Aimbot"

local function registerRefresh(fn)
	table.insert(refreshers, fn)
end

local function makeCard(parent, pos, size, titleAr, titleEn)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = C.cardBg
	card.Position = pos
	card.Size = size
	card.Parent = parent
	round(card, 14)
	stroke(card, C.line, 1, 0.3)

	local h = Instance.new("TextLabel")
	h.BackgroundTransparency = 1
	h.Position = UDim2.fromOffset(14, 10)
	h.Size = UDim2.new(1, -28, 0, 20)
	h.Font = Enum.Font.GothamBold
	h.TextSize = 13
	h.TextColor3 = C.text
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Parent = card

	registerRefresh(function()
		h.Text = T(titleAr, titleEn)
	end)

	local inner = Instance.new("Frame")
	inner.BackgroundTransparency = 1
	inner.Position = UDim2.fromOffset(12, 34)
	inner.Size = UDim2.new(1, -24, 1, -44)
	inner.Parent = card
	return card, inner
end

local function makeSwitch(parent, y, titleAr, titleEn, subAr, subEn, getFn, setFn, onChanged)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = C.rowBg
	row.Position = UDim2.new(0, 0, 0, y)
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Parent = parent
	round(row, 10)
	stroke(row, C.line, 1, 0.5)

	local tLbl = Instance.new("TextLabel")
	tLbl.BackgroundTransparency = 1
	tLbl.Position = UDim2.fromOffset(12, 5)
	tLbl.Size = UDim2.new(1, -72, 0, 17)
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 12
	tLbl.TextColor3 = C.text
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Parent = row

	local sLbl = Instance.new("TextLabel")
	sLbl.BackgroundTransparency = 1
	sLbl.Position = UDim2.fromOffset(12, 22)
	sLbl.Size = UDim2.new(1, -72, 0, 15)
	sLbl.Font = Enum.Font.Gotham
	sLbl.TextSize = 10
	sLbl.TextColor3 = C.muted
	sLbl.TextXAlignment = Enum.TextXAlignment.Left
	sLbl.Parent = row

	local pill = Instance.new("TextButton")
	pill.AutoButtonColor = false
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -12, 0.5, 0)
	pill.Size = UDim2.fromOffset(42, 22)
	pill.Text = ""
	pill.Parent = row
	round(pill, 11)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = UDim2.new(0, 3, 0.5, -8)
	knob.BackgroundColor3 = C.text
	knob.BorderSizePixel = 0
	knob.Parent = pill
	round(knob, 8)

	local function sync()
		tLbl.Text = T(titleAr, titleEn)
		sLbl.Text = T(subAr, subEn)
		local active = getFn()
		pill.BackgroundColor3 = active and C.accent or C.trackOff
		knob.Position = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	end

	registerRefresh(sync)
	hook(pill.MouseButton1Click:Connect(function()
		local nextVal = not getFn()
		setFn(nextVal)
		sync()
		if onChanged then onChanged(nextVal) end
	end))
	sync()
	return sync
end

local function makeSlider(parent, y, titleAr, titleEn, minV, maxV, step, getFn, setFn, fmtFn, onChanged)
	local wrap = Instance.new("Frame")
	wrap.BackgroundColor3 = C.rowBg
	wrap.Position = UDim2.new(0, 0, 0, y)
	wrap.Size = UDim2.new(1, 0, 0, 44)
	wrap.Parent = parent
	round(wrap, 10)
	stroke(wrap, C.line, 1, 0.5)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(12, 5)
	lbl.Size = UDim2.new(0.7, -12, 0, 16)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = C.text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = wrap

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Position = UDim2.new(0.7, 0, 0, 5)
	valLbl.Size = UDim2.new(0.3, -12, 0, 16)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 11
	valLbl.TextColor3 = C.accent
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = wrap

	local track = Instance.new("TextButton")
	track.AutoButtonColor = false
	track.Position = UDim2.fromOffset(12, 27)
	track.Size = UDim2.new(1, -24, 0, 8)
	track.BackgroundColor3 = C.sliderBg
	track.Text = ""
	track.Parent = wrap
	round(track, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = C.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	round(fill, 4)

	local function syncVisual()
		lbl.Text = T(titleAr, titleEn)
		local v = getFn()
		valLbl.Text = fmtFn(v)
		local span = math.max(maxV - minV, 0.0001)
		local alpha = math.clamp((v - minV) / span, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
	end

	local function applyFromScreenX(px)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		if absW <= 0 then return end
		local alpha = math.clamp((px - absX) / absW, 0, 1)
		local raw = minV + alpha * (maxV - minV)
		local snapped = math.floor(raw / step + 0.5) * step
		snapped = math.clamp(snapped, minV, maxV)
		setFn(snapped)
		syncVisual()
		if onChanged then onChanged(snapped) end
	end

	hook(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			applyFromScreenX(input.Position.X)
			local moveConn, endConn
			moveConn = UserInputService.InputChanged:Connect(function(mInput)
				if mInput.UserInputType == Enum.UserInputType.MouseMovement or mInput.UserInputType == Enum.UserInputType.Touch then
					applyFromScreenX(mInput.Position.X)
				end
			end)
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if moveConn then moveConn:Disconnect() end
					if endConn then endConn:Disconnect() end
				end
			end)
		end
	end))

	registerRefresh(syncVisual)
	syncVisual()
	return syncVisual
end

local navItems = {
	{ id = "Aimbot", ar = "الأيم بوت", en = "Aimbot" },
	{ id = "Visual", ar = "الكشف المريح", en = "Visual" },
	{ id = "Movement", ar = "الحركة والقفز", en = "Movement" },
	{ id = "Combat", ar = "الهيت والتريقر", en = "Hitbox & Trigger" },
	{ id = "Settings", ar = "الإعدادات", en = "Settings" }
}

local function setPage(id)
	currentTab = id
	for k, p in pairs(pages) do
		p.Visible = (k == id)
	end
	for k, b in pairs(navBtns) do
		local sel = (k == id)
		b.BackgroundColor3 = C.cardBg
		b.BackgroundTransparency = sel and 0.15 or 1
		b.TextColor3 = sel and C.accent or C.muted
	end
	for _, item in ipairs(navItems) do
		if item.id == id then
			pageTitle.Text = T(item.ar, item.en)
			break
		end
	end
end

for i, item in ipairs(navItems) do
	local p = Instance.new("Frame")
	p.Name = item.id
	p.BackgroundTransparency = 1
	p.Size = UDim2.fromScale(1, 1)
	p.Visible = false
	p.Parent = bodyArea
	pages[item.id] = p

	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Position = UDim2.fromOffset(10, 80 + (i - 1) * 40)
	b.Size = UDim2.new(1, -20, 0, 34)
	b.BackgroundTransparency = 1
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = sidebar
	round(b, 8)
	navBtns[item.id] = b

	registerRefresh(function()
		b.Text = "  " .. T(item.ar, item.en)
		if currentTab == item.id then
			pageTitle.Text = T(item.ar, item.en)
		end
	end)

	hook(b.MouseButton1Click:Connect(function()
		setPage(item.id)
	end))
end

-- 1) صفحة الأيم بوت
local _, aimLeft = makeCard(pages.Aimbot, UDim2.fromOffset(0, 0), UDim2.new(0.54, -6, 1, 0), "الأيم بوت", "Aimbot")
local _, aimRight = makeCard(pages.Aimbot, UDim2.new(0.54, 6, 0, 0), UDim2.new(0.46, -6, 1, 0), "إعدادات التتبع والارتداد", "Aim & Recoil Settings")

makeSwitch(aimLeft, 0, "تفعيل الأيم بوت", "Enable Aimbot", "توجيه الكاميرا واللاعب والماوس نحو الهدف", "Aligns camera, character & aim direction", function() return S.aimEnabled end, function(v)
	S.aimEnabled = v
	if not v then aimToggled = false end
end)
makeSwitch(aimLeft, 50, "لف شخصية اللاعب فعلياً", "Rotate Character", "تدوير الجسم ليتطابق مع الضرب", "Turns character toward target", function() return S.rotateCharacter end, function(v) S.rotateCharacter = v end)
makeSwitch(aimLeft, 100, "تثبيت من ضغطة (Toggle)", "Toggle Mode", "ضغطة للتثبيت أو ضغط مستمر (Hold)", "Toggle lock or hold bind", function() return S.aimBehavior == "TOGGLE" end, function(v)
	S.aimBehavior = v and "TOGGLE" or "HOLD"
	if not v then aimToggled = false end
end)

local bindBtn = Instance.new("TextButton")
bindBtn.Position = UDim2.new(0, 0, 0, 152)
bindBtn.Size = UDim2.new(1, 0, 0, 36)
bindBtn.BackgroundColor3 = C.rowBg
bindBtn.Font = Enum.Font.GothamBold
bindBtn.TextSize = 11
bindBtn.TextColor3 = C.accent
bindBtn.Parent = aimLeft
round(bindBtn, 8)
stroke(bindBtn, C.line, 1, 0.45)

local function refreshBindText()
	if listeningForKey then
		bindBtn.Text = T("اضغط أي زر في الكيبورد أو الماوس...", "Press any key or mouse button...")
	else
		bindBtn.Text = T("زر التفعيل: ", "Bind: ") .. getAimBindDisplay()
	end
end
registerRefresh(refreshBindText)
refreshBindText()

hook(bindBtn.MouseButton1Click:Connect(function()
	listeningForKey = true
	refreshBindText()
end))

local boneBtn = Instance.new("TextButton")
boneBtn.Position = UDim2.new(0, 0, 0, 194)
boneBtn.Size = UDim2.new(1, 0, 0, 36)
boneBtn.BackgroundColor3 = C.rowBg
boneBtn.Font = Enum.Font.GothamBold
boneBtn.TextSize = 11
boneBtn.TextColor3 = C.text
boneBtn.Parent = aimLeft
round(boneBtn, 8)
stroke(boneBtn, C.line, 1, 0.45)

local bones = { "Head", "HumanoidRootPart", "UpperTorso" }
local function refreshBoneText()
	boneBtn.Text = T("جزء التصويب: ", "Target Bone: ") .. S.aimPart
end
registerRefresh(refreshBoneText)
refreshBoneText()

hook(boneBtn.MouseButton1Click:Connect(function()
	local i = table.find(bones, S.aimPart) or 1
	S.aimPart = bones[(i % #bones) + 1]
	refreshBoneText()
end))

makeSlider(aimRight, 0, "نطاق الدائرة (FOV)", "FOV Radius", 40, 450, 10, function() return S.aimFov end, function(v) S.aimFov = v end, function(v) return tostring(math.floor(v)) .. "px" end, function(v)
	fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
makeSlider(aimRight, 50, "سرعة التتبع", "Aim Smooth", 0.05, 1, 0.05, function() return S.aimSmooth end, function(v) S.aimSmooth = v end, function(v) return string.format("%.2f", v) end)
makeSwitch(aimRight, 100, "منع اهتزاز السلاح (No Recoil)", "No Recoil", "تثبيت الكاميرا أثناء الضرب", "Reduces camera recoil kick", function() return S.noRecoilEnabled end, function(v) S.noRecoilEnabled = v end)
makeSlider(aimRight, 150, "قوة منع الارتداد", "Recoil Damp", 0.1, 1, 0.05, function() return S.noRecoilStrength end, function(v) S.noRecoilStrength = v end, function(v) return string.format("%.2f", v) end)

-- 2) صفحة الكشف المريح للعين
local _, visLeft = makeCard(pages.Visual, UDim2.fromOffset(0, 0), UDim2.new(0.54, -6, 1, 0), "عناصر الكشف", "Visual Elements")
local _, visRight = makeCard(pages.Visual, UDim2.new(0.54, 6, 0, 0), UDim2.new(0.46, -6, 1, 0), "راحة العين والمدى", "Comfort & Range")

makeSwitch(visLeft, 0, "الأسماء والمسافة", "Name & Distance", "عناوين هادئة وواضحة", "Clean readable tags", function() return S.espEnabled end, function(v) S.espEnabled = v; updateEsp() end)
makeSwitch(visLeft, 50, "Player Cham (عبر الجدران)", "Player Cham", "إظهار اللاعب من خلف الجدران", "Highlight through walls", function() return S.espCham end, function(v) S.espCham = v; updateEsp() end)
makeSwitch(visLeft, 100, "شريط الصحة الطولي", "Side Health Bar", "شريط عمودي بجانب اللاعب", "Vertical bar beside player", function() return S.espHealthBar end, function(v) S.espHealthBar = v; updateEsp() end)
makeSwitch(visLeft, 150, "إظهار دائرة FOV", "Show FOV Circle", "دائرة المنتصف للتصويب", "Center aim circle", function() return S.espCircle end, function(v) S.espCircle = v; fovCircle.Visible = v end)

makeSwitch(visRight, 0, "وضع مريح للعين", "Eye Comfort Tone", "ألوان ذهبية هادئة بدون إجهاد", "Soft eye-friendly palette", function() return S.eyeComfort end, function(v) S.eyeComfort = v; updateEsp() end)
makeSlider(visRight, 50, "أقصى مسافة", "Max Distance", 100, 2500, 50, function() return S.maxRange end, function(v) S.maxRange = v end, function(v) return tostring(math.floor(v)) .. "m" end, function() updateEsp() end)

-- 3) صفحة الحركة والقفز
local _, movCard = makeCard(pages.Movement, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), "الحركة والقفز", "Movement")
makeSwitch(movCard, 0, "تفعيل السرعة والقفز", "Enable Movement", "تطبيق السرعة والقفز المحددة", "Apply speed & jump settings", function() return S.moveEnabled end, function(v) S.moveEnabled = v; applyMove() end)
makeSlider(movCard, 52, "السرعة (WalkSpeed)", "WalkSpeed", 16, 140, 2, function() return S.walkSpeed end, function(v) S.walkSpeed = v end, function(v) return tostring(math.floor(v)) end, function() applyMove() end)
makeSlider(movCard, 104, "مسافة / قوة القفز", "Jump Power", 50, 240, 5, function() return S.jumpPower end, function(v) S.jumpPower = v end, function(v) return tostring(math.floor(v)) end, function() applyMove() end)

-- 4) صفحة الهيت بوكس والتريقر بوت
local _, hbCard = makeCard(pages.Combat, UDim2.fromOffset(0, 0), UDim2.new(0.5, -6, 1, 0), "الهيت بوكس", "Hitbox")
local _, trCard = makeCard(pages.Combat, UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -6, 1, 0), "التريقر بوت", "TriggerBot")

makeSwitch(hbCard, 0, "تفعيل الهيت بوكس", "Enable Hitbox", "توسيع منطقة الإصابة للخصوم", "Expand target root hitbox", function() return S.hitboxEnabled end, function(v) S.hitboxEnabled = v; applyHb() end)
makeSlider(hbCard, 52, "حجم الهيت بوكس", "Hitbox Size", 2, 20, 1, function() return S.hitboxSize end, function(v) S.hitboxSize = v end, function(v) return tostring(math.floor(v)) end, function() applyHb() end)
makeSlider(hbCard, 104, "شفافية الهيت بوكس", "Transparency", 0.25, 0.98, 0.05, function() return S.hitboxTrans end, function(v) S.hitboxTrans = v end, function(v) return string.format("%.2f", v) end, function() applyHb() end)

makeSwitch(trCard, 0, "تفعيل التريقر بوت", "Enable TriggerBot", "إطلاق تلقائي عند التوجيه على خصم", "Auto-fire when aiming at enemy", function() return S.triggerEnabled end, function(v) S.triggerEnabled = v end)
makeSlider(trCard, 52, "تأخير الإطلاق", "Trigger Delay", 0, 0.3, 0.01, function() return S.triggerDelay end, function(v) S.triggerDelay = v end, function(v) return string.format("%.2fs", v) end)

-- 5) صفحة الإعدادات
local _, setCard = makeCard(pages.Settings, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), "الإعدادات", "Settings")
makeSwitch(setCard, 0, "تجاهل نفس الفريق", "Team Check", "عدم استهداف أو كشف أعضاء فريقك", "Ignore teammates", function() return S.teamCheck end, function(v) S.teamCheck = v; updateEsp() end)

local infoLbl = Instance.new("TextLabel")
infoLbl.BackgroundTransparency = 1
infoLbl.Position = UDim2.fromOffset(8, 56)
infoLbl.Size = UDim2.new(1, -16, 0, 80)
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 11
infoLbl.TextColor3 = C.muted
infoLbl.TextWrapped = true
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.Parent = setCard

local saveStatusNote = ""
registerRefresh(function()
	if saveStatusNote ~= "" then
		saveBtn.Text = saveStatusNote
	else
		saveBtn.Text = T("حفظ التفعيلات", "Save Config")
	end
	infoLbl.Text = T(
		"• اضغط (حفظ التفعيلات) لحفظ كل التفعيلات والعدادات.\n• اضغط F1 لإخفاء أو إظهار القائمة.",
		"• Click Save Config to store all toggles & sliders.\n• Press F1 to toggle the menu."
	)
end)

hook(saveBtn.MouseButton1Click:Connect(function()
	local fileSaved = saveConfig()
	saveStatusNote = fileSaved and T("تم الحفظ ✓", "Saved ✓") or T("حُفظ بالجلسة ✓", "Session Saved ✓")
	saveBtn.Text = saveStatusNote
	task.delay(1.5, function()
		if isRunning then
			saveStatusNote = ""
			saveBtn.Text = T("حفظ التفعيلات", "Save Config")
		end
	end)
end))

-- إدخال الأزرار وتسجيل زر الأيم بوت
hook(UserInputService.InputBegan:Connect(function(input, processed)
	if not isRunning then return end

	if listeningForKey then
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3 then
			S.aimBindType = "MouseButton"
			S.aimKeyName = input.UserInputType.Name
			listeningForKey = false
			aimToggled = false
			refreshBindText()
			return
		elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			if input.KeyCode ~= Enum.KeyCode.F1 then
				S.aimBindType = "KeyCode"
				S.aimKeyName = input.KeyCode.Name
			end
			listeningForKey = false
			aimToggled = false
			refreshBindText()
			return
		end
	end

	if not processed and input.KeyCode == Enum.KeyCode.F1 then
		S.menuOpen = not S.menuOpen
		win.Visible = S.menuOpen
		return
	end

	if not processed and S.aimEnabled and S.aimBehavior == "TOGGLE" and matchesAimInput(input) then
		aimToggled = not aimToggled
	end
end))

hook(langBtn.MouseButton1Click:Connect(function()
	S.lang = (S.lang == "AR") and "EN" or "AR"
	langBtn.Text = (S.lang == "AR") and "AR / EN" or "EN / AR"
	for _, fn in ipairs(refreshers) do
		fn()
	end
end))

local function unload()
	if not isRunning then return end
	isRunning = false
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
	restoreMove()
	restoreAllHb()
	clearAllEsp()
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
	env.ALASHBAT_GOTHAM_UNLOAD = nil
end

env.ALASHBAT_GOTHAM_UNLOAD = unload
hook(closeBtn.MouseButton1Click:Connect(unload))
hook(screenGui.Destroying:Connect(unload))

hook(LocalPlayer.CharacterAdded:Connect(function()
	moveBackup.hum = nil
	task.wait(0.1)
	if S.moveEnabled then
		applyMove()
	end
end))

hook(Players.PlayerRemoving:Connect(function(p)
	clearPlayerEsp(p)
end))

local function watchPlayer(p)
	if p == LocalPlayer then return end
	hook(p.CharacterAdded:Connect(function(char)
		clearPlayerEsp(p)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hook(hum.Died:Connect(function()
				clearPlayerEsp(p)
			end))
			hook(hum.HealthChanged:Connect(function()
				local pack = espMap[p]
				if pack then
					refreshSideHealth(pack, hum)
				end
			end))
		end
	end))
end

for _, p in ipairs(Players:GetPlayers()) do
	watchPlayer(p)
end
hook(Players.PlayerAdded:Connect(watchPlayer))

hook(RunService.RenderStepped:Connect(function()
	if not isRunning or not screenGui.Parent then return end

	fovCircle.Visible = S.espCircle
	fovCircle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)

	if S.moveEnabled then
		applyMove()
	end
	if S.hitboxEnabled then
		applyHb()
	end

	Camera = Workspace.CurrentCamera
	applyAimbot(Camera)
	applyNoRecoil(Camera)
	updateTrigger()
end))

task.spawn(function()
	while isRunning and screenGui.Parent do
		pcall(updateEsp)
		task.wait(0.25)
	end
end)

for _, fn in ipairs(refreshers) do
	fn()
end
setPage("Aimbot")
win.Visible = S.menuOpen
fovCircle.Visible = S.espCircle
fovCircle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)
if S.moveEnabled then applyMove() end
if S.hitboxEnabled then applyHb() end
updateEsp()
