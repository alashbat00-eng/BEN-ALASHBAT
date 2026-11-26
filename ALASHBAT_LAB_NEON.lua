-- ALASHBAT LAB — BATMAN CLIENT EDITION
-- Complete self-contained script for Roblox Executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.ALASHBAT_BAT_UNLOAD then
	pcall(env.ALASHBAT_BAT_UNLOAD)
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

local function randTag(prefix)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local out = { prefix or "U" }
	for i = 1, 8 do
		local idx = math.random(1, #chars)
		table.insert(out, string.sub(chars, idx, idx))
	end
	return table.concat(out)
end

local GUI_NAME = randTag("BAT_")
local TAG_NAME = randTag("T_")
local CHAM_NAME = randTag("C_")

-- الإعدادات الموحدة
local S = {
	lang = "AR", -- "AR" | "EN"
	menuOpen = true,

	-- Aimbot & Recoil
	aimEnabled = false,
	rotateCharacter = true,
	aimPart = "Head",
	aimFov = 145,
	aimSmooth = 0.28,
	aimBehavior = "HOLD", -- "HOLD" | "TOGGLE"
	aimBindType = "MouseButton", -- "MouseButton" | "KeyCode"
	aimKeyName = "MouseButton2",
	noRecoilEnabled = true,
	noRecoilStrength = 0.8,

	-- Visuals (Eye-friendly)
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

	-- Hitbox
	hitboxEnabled = false,
	hitboxSize = 5,
	hitboxTrans = 0.9,

	-- TriggerBot
	triggerEnabled = false,
	triggerDelay = 0.04,

	-- Protection & Filters
	teamCheck = true,
	maxRange = 800,
	safeMode = true
}

local aimToggled = false

local function T(ar, en)
	return S.lang == "AR" and ar or en
end

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
		probe.Name = randTag("P_")
		probe.Parent = game:GetService("CoreGui")
		probe:Destroy()
		return game:GetService("CoreGui")
	end)
	if okCore and core then return core end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
end

local uiParent = resolveUiParent()
if not uiParent then return end

-- ثيم باتمان داكن ومريح للعين
local P = {
	bg = Color3.fromRGB(10, 11, 14),
	side = Color3.fromRGB(14, 15, 19),
	card = Color3.fromRGB(19, 21, 27),
	cardHover = Color3.fromRGB(25, 28, 36),
	trackOff = Color3.fromRGB(48, 52, 64),
	batGold = Color3.fromRGB(242, 196, 42),
	batGoldSoft = Color3.fromRGB(175, 138, 26),
	text = Color3.fromRGB(232, 234, 240),
	sub = Color3.fromRGB(140, 146, 160),
	border = Color3.fromRGB(36, 39, 48),
	ok = Color3.fromRGB(72, 205, 132),
	danger = Color3.fromRGB(235, 92, 102)
}

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end

local function stroke(inst, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = col or P.border
	s.Thickness = thick or 1
	s.Transparency = trans or 0.25
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

local function getEyeFriendlyColor(player)
	if player.Team and player.TeamColor and not S.safeMode then
		return player.TeamColor.Color
	end
	return Color3.fromRGB(245, 204, 72)
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
fovCircle.Name = randTag("F_")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = S.espCircle
fovCircle.Parent = screenGui
round(fovCircle, 999)
stroke(fovCircle, P.batGold, 1.3, 0.35)

-- نظام الكشف المريح للعين + شريط صحة عمودي بجانب اللاعب + Cham
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
		pack.hpFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(95, 214, 146) or (ratio > 0.25 and P.batGold or Color3.fromRGB(232, 108, 114))
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
			local col = getEyeFriendlyColor(p)

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
					hl.OutlineColor = P.batGold
					hl.FillTransparency = 0.72
					hl.OutlineTransparency = 0.15
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
					lbl.TextStrokeTransparency = 0.45
					lbl.Parent = bb

					local hpBg = Instance.new("Frame")
					hpBg.Name = "SideHPBg"
					hpBg.Position = UDim2.fromOffset(20, 20)
					hpBg.Size = UDim2.fromOffset(5, 44)
					hpBg.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
					hpBg.BorderSizePixel = 0
					hpBg.Parent = bb
					round(hpBg, 2)

					local hpFill = Instance.new("Frame")
					hpFill.Name = "SideHPFill"
					hpFill.Size = UDim2.fromScale(1, 1)
					hpFill.BackgroundColor3 = Color3.fromRGB(95, 214, 146)
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

-- نظام Aimbot الفعلي (توجيه الكاميرا + لف الشخصية نحو الهدف) + No Recoil
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
		local dampedLook = curLook:Lerp(prevLook, math.clamp(S.noRecoilStrength * 0.5, 0, 0.88)).Unit
		cam.CFrame = CFrame.lookAt(pos, pos + dampedLook)
	end
	lastCamCFrame = cam.CFrame
end

local function applyAimbot(cam)
	local active = (S.aimBehavior == "HOLD" and isAimBindPressed()) or (S.aimBehavior == "TOGGLE" and aimToggled)
	if not S.aimEnabled or not active or not cam then return end

	local targetPart, targetRoot = getBestTargetPart()
	if not targetPart then return end

	local alpha = math.clamp(S.aimSmooth, 0.02, 1)
	local camGoal = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
	cam.CFrame = cam.CFrame:Lerp(camGoal, alpha)

	-- لف شخصية اللاعب فعلياً نحو الهدف حتى يتطابق اتجاه الضرب مع الكاميرا
	if S.rotateCharacter then
		local myChar = LocalPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local focusPos = targetRoot and targetRoot.Position or targetPart.Position
		if myRoot then
			local flatTarget = Vector3.new(focusPos.X, myRoot.Position.Y, focusPos.Z)
			if (flatTarget - myRoot.Position).Magnitude > 0.05 then
				local charGoal = CFrame.lookAt(myRoot.Position, flatTarget)
				myRoot.CFrame = myRoot.CFrame:Lerp(charGoal, math.clamp(alpha * 1.25, 0.04, 1))
			end
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

-- الواجهة الحديثة على طراز البطاقات المقسّمة مع ثيم باتمان
local win = Instance.new("Frame")
win.Name = randTag("W_")
win.Active = true
win.BackgroundColor3 = P.bg
win.Position = UDim2.new(0.5, -390, 0.5, -230)
win.Size = UDim2.fromOffset(780, 460)
win.ClipsDescendants = true
win.Parent = screenGui
round(win, 16)
stroke(win, P.batGold, 1.4, 0.25)

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

-- الشريط الجانبي الأيسر (ثيم باتمان)
local sidebar = Instance.new("Frame")
sidebar.BackgroundColor3 = P.side
sidebar.Position = UDim2.fromOffset(12, 12)
sidebar.Size = UDim2.fromOffset(186, 436)
sidebar.BorderSizePixel = 0
sidebar.Parent = win
round(sidebar, 12)
stroke(sidebar, P.border, 1, 0.2)

-- شارة باتمان الصغيرة في أعلى القائمة الجانبية
local batBadge = Instance.new("Frame")
batBadge.BackgroundColor3 = P.card
batBadge.Position = UDim2.fromOffset(12, 12)
batBadge.Size = UDim2.new(1, -24, 0, 54)
batBadge.BorderSizePixel = 0
batBadge.Parent = sidebar
round(batBadge, 10)
stroke(batBadge, P.batGold, 1, 0.45)

local emblem = Instance.new("Frame")
emblem.AnchorPoint = Vector2.new(0, 0.5)
emblem.Position = UDim2.new(0, 10, 0.5, 0)
emblem.Size = UDim2.fromOffset(52, 28)
emblem.BackgroundColor3 = P.batGold
emblem.BorderSizePixel = 0
emblem.Parent = batBadge
round(emblem, 14)

local emblemInner = Instance.new("Frame")
emblemInner.AnchorPoint = Vector2.new(0.5, 0.5)
emblemInner.Position = UDim2.fromScale(0.5, 0.5)
emblemInner.Size = UDim2.new(1, -4, 1, -4)
emblemInner.BackgroundColor3 = Color3.fromRGB(9, 10, 13)
emblemInner.BorderSizePixel = 0
emblemInner.Parent = emblem
round(emblemInner, 12)

local emblemTag = Instance.new("TextLabel")
emblemTag.Size = UDim2.fromScale(1, 1)
emblemTag.BackgroundTransparency = 1
emblemTag.Font = Enum.Font.GothamBlack
emblemTag.Text = "BAT"
emblemTag.TextColor3 = P.batGold
emblemTag.TextSize = 9
emblemTag.Parent = emblemInner

local brandTitle = Instance.new("TextLabel")
brandTitle.BackgroundTransparency = 1
brandTitle.Position = UDim2.fromOffset(70, 9)
brandTitle.Size = UDim2.new(1, -78, 0, 18)
brandTitle.Font = Enum.Font.GothamBold
brandTitle.Text = "ALASHBAT"
brandTitle.TextColor3 = P.batGold
brandTitle.TextSize = 13
brandTitle.TextXAlignment = Enum.TextXAlignment.Left
brandTitle.Parent = batBadge

local brandSub = Instance.new("TextLabel")
brandSub.BackgroundTransparency = 1
brandSub.Position = UDim2.fromOffset(70, 27)
brandSub.Size = UDim2.new(1, -78, 0, 16)
brandSub.Font = Enum.Font.Gotham
brandSub.Text = "Gotham Client"
brandSub.TextColor3 = P.sub
brandSub.TextSize = 10
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = batBadge

-- منطقة المحتوى اليمنى
local mainArea = Instance.new("Frame")
mainArea.BackgroundTransparency = 1
mainArea.Position = UDim2.fromOffset(208, 12)
mainArea.Size = UDim2.new(1, -220, 1, -24)
mainArea.Parent = win

local topStrip = Instance.new("Frame")
topStrip.BackgroundColor3 = P.side
topStrip.Position = UDim2.fromOffset(0, 0)
topStrip.Size = UDim2.new(1, 0, 0, 42)
topStrip.Parent = mainArea
round(topStrip, 10)
stroke(topStrip, P.border, 1, 0.25)

local pageHeader = Instance.new("TextLabel")
pageHeader.BackgroundTransparency = 1
pageHeader.Position = UDim2.fromOffset(14, 0)
pageHeader.Size = UDim2.new(1, -150, 1, 0)
pageHeader.Font = Enum.Font.GothamBold
pageHeader.TextSize = 14
pageHeader.TextColor3 = P.text
pageHeader.TextXAlignment = Enum.TextXAlignment.Left
pageHeader.Parent = topStrip

local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.fromOffset(68, 26)
langBtn.Position = UDim2.new(1, -108, 0.5, -13)
langBtn.BackgroundColor3 = P.card
langBtn.Font = Enum.Font.GothamBold
langBtn.Text = "AR / EN"
langBtn.TextColor3 = P.batGold
langBtn.TextSize = 11
langBtn.Parent = topStrip
round(langBtn, 6)
stroke(langBtn, P.batGoldSoft, 1, 0.35)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 26)
closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
closeBtn.BackgroundColor3 = P.card
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = P.danger
closeBtn.TextSize = 15
closeBtn.Parent = topStrip
round(closeBtn, 6)
stroke(closeBtn, P.border, 1, 0.25)

local bodyArea = Instance.new("Frame")
bodyArea.BackgroundTransparency = 1
bodyArea.Position = UDim2.fromOffset(0, 50)
bodyArea.Size = UDim2.new(1, 0, 1, -50)
bodyArea.Parent = mainArea

local pages, navBtns = {}, {}
local uiRefreshers = {}
local currentTab = "Aimbot"

local function registerRefresh(fn)
	table.insert(uiRefreshers, fn)
end

local function makeSectionCard(parent, pos, size, titleAr, titleEn)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = P.card
	card.Position = pos
	card.Size = size
	card.Parent = parent
	round(card, 12)
	stroke(card, P.border, 1, 0.25)

	local h = Instance.new("TextLabel")
	h.BackgroundTransparency = 1
	h.Position = UDim2.fromOffset(14, 10)
	h.Size = UDim2.new(1, -28, 0, 20)
	h.Font = Enum.Font.GothamBold
	h.TextSize = 13
	h.TextColor3 = P.batGold
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Parent = card

	registerRefresh(function()
		h.Text = T(titleAr, titleEn)
	end)

	local inner = Instance.new("Frame")
	inner.BackgroundTransparency = 1
	inner.Position = UDim2.fromOffset(10, 34)
	inner.Size = UDim2.new(1, -20, 1, -42)
	inner.Parent = card
	return card, inner
end

local function makeSwitchRow(parent, y, titleAr, titleEn, descAr, descEn, getFn, setFn, onChanged)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = P.side
	row.Position = UDim2.new(0, 0, 0, y)
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Parent = parent
	round(row, 8)
	stroke(row, P.border, 1, 0.45)

	local tLbl = Instance.new("TextLabel")
	tLbl.BackgroundTransparency = 1
	tLbl.Position = UDim2.fromOffset(12, 5)
	tLbl.Size = UDim2.new(1, -74, 0, 18)
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 12
	tLbl.TextColor3 = P.text
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Parent = row

	local dLbl = Instance.new("TextLabel")
	dLbl.BackgroundTransparency = 1
	dLbl.Position = UDim2.fromOffset(12, 22)
	dLbl.Size = UDim2.new(1, -74, 0, 16)
	dLbl.Font = Enum.Font.Gotham
	dLbl.TextSize = 10
	dLbl.TextColor3 = P.sub
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.Parent = row

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
	knob.BackgroundColor3 = P.bg
	knob.BorderSizePixel = 0
	knob.Parent = pill
	round(knob, 8)

	local function sync()
		tLbl.Text = T(titleAr, titleEn)
		dLbl.Text = T(descAr, descEn)
		local active = getFn()
		pill.BackgroundColor3 = active and P.batGold or P.trackOff
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

local function makeStepperRow(parent, y, titleAr, titleEn, getFn, setFn, step, minV, maxV, fmtFn, onChanged)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = P.side
	row.Position = UDim2.new(0, 0, 0, y)
	row.Size = UDim2.new(1, 0, 0, 38)
	row.Parent = parent
	round(row, 8)
	stroke(row, P.border, 1, 0.45)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(12, 0)
	lbl.Size = UDim2.new(1, -162, 1, 0)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextColor3 = P.text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Position = UDim2.new(1, -148, 0, 0)
	valLbl.Size = UDim2.fromOffset(62, 38)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 11
	valLbl.TextColor3 = P.batGold
	valLbl.Parent = row

	local minus = Instance.new("TextButton")
	minus.Size = UDim2.fromOffset(28, 24)
	minus.Position = UDim2.new(1, -82, 0.5, -12)
	minus.BackgroundColor3 = P.card
	minus.Font = Enum.Font.GothamBold
	minus.Text = "−"
	minus.TextColor3 = P.text
	minus.TextSize = 13
	minus.Parent = row
	round(minus, 6)
	stroke(minus, P.border, 1, 0.3)

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.fromOffset(28, 24)
	plus.Position = UDim2.new(1, -50, 0.5, -12)
	plus.BackgroundColor3 = P.card
	plus.Font = Enum.Font.GothamBold
	plus.Text = "+"
	plus.TextColor3 = P.text
	plus.TextSize = 13
	plus.Parent = row
	round(plus, 6)
	stroke(plus, P.border, 1, 0.3)

	local function sync()
		lbl.Text = T(titleAr, titleEn)
		valLbl.Text = fmtFn(getFn())
	end

	registerRefresh(sync)
	hook(minus.MouseButton1Click:Connect(function()
		local v = math.clamp(getFn() - step, minV, maxV)
		setFn(v)
		sync()
		if onChanged then onChanged(v) end
	end))
	hook(plus.MouseButton1Click:Connect(function()
		local v = math.clamp(getFn() + step, minV, maxV)
		setFn(v)
		sync()
		if onChanged then onChanged(v) end
	end))
	sync()
	return sync
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
		b.BackgroundColor3 = sel and Color3.fromRGB(36, 31, 14) or Color3.fromRGB(0, 0, 0)
		b.BackgroundTransparency = sel and 0 or 1
		b.TextColor3 = sel and P.batGold or P.sub
	end
	for _, item in ipairs(navItems) do
		if item.id == id then
			pageHeader.Text = T(item.ar, item.en)
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
	b.Position = UDim2.fromOffset(10, 78 + (i - 1) * 40)
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
			pageHeader.Text = T(item.ar, item.en)
		end
	end)

	hook(b.MouseButton1Click:Connect(function()
		setPage(item.id)
	end))
end

-- 1) صفحة الأيم بوت (توجيه حقيقي + لف اللاعب + تسجيل زر مباشر + هولد/تثبيت + No Recoil)
local _, aimLeft = makeSectionCard(pages.Aimbot, UDim2.fromOffset(0, 0), UDim2.new(0.56, -6, 1, 0), "توجيه الأيم بوت", "Aimbot Control")
local _, aimRight = makeSectionCard(pages.Aimbot, UDim2.new(0.56, 6, 0, 0), UDim2.new(0.44, -6, 1, 0), "إعدادات التثبيت والارتداد", "Aim & Recoil Settings")

makeSwitchRow(aimLeft, 0, "تفعيل الأيم بوت", "Enable Aimbot", "توجيه الكاميرا واللاعب نحو الهدف", "Smoothly aligns camera & character", function() return S.aimEnabled end, function(v)
	S.aimEnabled = v
	if not v then aimToggled = false end
end)
makeSwitchRow(aimLeft, 50, "لف شخصية اللاعب فعلياً", "Rotate Character", "تدوير الجسم ليتطابق مع الضرب", "Turns character toward target", function() return S.rotateCharacter end, function(v) S.rotateCharacter = v end)
makeSwitchRow(aimLeft, 100, "وضع التثبيت (Toggle)", "Toggle Mode", "ضغطة للتثبيت وضغطة للإلغاء (الافتراضي Hold)", "Press to lock/unlock (default Hold)", function() return S.aimBehavior == "TOGGLE" end, function(v)
	S.aimBehavior = v and "TOGGLE" or "HOLD"
	if not v then aimToggled = false end
end)

-- زر تسجيل أي زر من الكيبورد أو الماوس
local bindBtn = Instance.new("TextButton")
bindBtn.Position = UDim2.new(0, 0, 0, 152)
bindBtn.Size = UDim2.new(1, 0, 0, 38)
bindBtn.BackgroundColor3 = P.side
bindBtn.Font = Enum.Font.GothamBold
bindBtn.TextSize = 11
bindBtn.TextColor3 = P.batGold
bindBtn.Parent = aimLeft
round(bindBtn, 8)
stroke(bindBtn, P.batGoldSoft, 1, 0.35)

local function refreshBindText()
	if listeningForKey then
		bindBtn.Text = T("اضغط أي زر في الكيبورد أو الماوس...", "Press any key or mouse button...")
	else
		bindBtn.Text = T("زر التفعيل الحالي: ", "Current Bind: ") .. getAimBindDisplay() .. T(" (اضغط للتغيير)", " (Click to set)")
	end
end
registerRefresh(refreshBindText)
refreshBindText()

hook(bindBtn.MouseButton1Click:Connect(function()
	listeningForKey = true
	refreshBindText()
end))

local boneBtn = Instance.new("TextButton")
boneBtn.Position = UDim2.new(0, 0, 0, 196)
boneBtn.Size = UDim2.new(1, 0, 0, 36)
boneBtn.BackgroundColor3 = P.side
boneBtn.Font = Enum.Font.GothamBold
boneBtn.TextSize = 11
boneBtn.TextColor3 = P.text
boneBtn.Parent = aimLeft
round(boneBtn, 8)
stroke(boneBtn, P.border, 1, 0.4)

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

makeStepperRow(aimRight, 0, "نطاق الدائرة (FOV)", "FOV Radius", function() return S.aimFov end, function(v) S.aimFov = v end, 10, 40, 450, function(v) return tostring(v) .. "px" end, function(v)
	fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
makeStepperRow(aimRight, 44, "سرعة التوجيه", "Aim Smooth", function() return S.aimSmooth end, function(v) S.aimSmooth = v end, 0.04, 0.04, 1, function(v) return string.format("%.2f", v) end)
makeSwitchRow(aimRight, 90, "منع اهتزاز السلاح (No Recoil)", "No Recoil", "تثبيت الكاميرا أثناء الضرب", "Reduces camera kick while firing", function() return S.noRecoilEnabled end, function(v) S.noRecoilEnabled = v end)
makeStepperRow(aimRight, 140, "قوة منع الارتداد", "Recoil Damp", function() return S.noRecoilStrength end, function(v) S.noRecoilStrength = v end, 0.05, 0.1, 1, function(v) return string.format("%.2f", v) end)

-- 2) صفحة الكشف المريح للعين
local _, visLeft = makeSectionCard(pages.Visual, UDim2.fromOffset(0, 0), UDim2.new(0.56, -6, 1, 0), "عناصر الكشف", "Visual Elements")
local _, visRight = makeSectionCard(pages.Visual, UDim2.new(0.56, 6, 0, 0), UDim2.new(0.44, -6, 1, 0), "راحة العين والمدى", "Comfort & Range")

makeSwitchRow(visLeft, 0, "الأسماء والمسافة", "Name & Distance", "ألوان هادئة وواضحة", "Clean readable labels", function() return S.espEnabled end, function(v) S.espEnabled = v; updateEsp() end)
makeSwitchRow(visLeft, 50, "Player Cham (عبر الجدران)", "Player Cham", "إظهار اللاعب من خلف الجدران", "See players behind walls", function() return S.espCham end, function(v) S.espCham = v; updateEsp() end)
makeSwitchRow(visLeft, 100, "شريط الصحة الطولي", "Side Health Bar", "شريط عمودي بجانب اللاعب", "Vertical bar beside player", function() return S.espHealthBar end, function(v) S.espHealthBar = v; updateEsp() end)
makeSwitchRow(visLeft, 150, "إظهار دائرة FOV", "Show FOV Circle", "دائرة المنتصف للتصويب", "Center aim circle", function() return S.espCircle end, function(v) S.espCircle = v; fovCircle.Visible = v end)

makeSwitchRow(visRight, 0, "وضع مريح للعين", "Eye Comfort Tone", "ألوان ذهبية هادئة بدون إجهاد", "Soft gold palette for eye comfort", function() return S.safeMode end, function(v) S.safeMode = v; updateEsp() end)
makeStepperRow(visRight, 50, "أقصى مسافة", "Max Distance", function() return S.maxRange end, function(v) S.maxRange = v end, 50, 100, 2500, function(v) return tostring(v) .. "m" end, function() updateEsp() end)

-- 3) صفحة الحركة والقفز
local _, movCard = makeSectionCard(pages.Movement, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), "السرعة ومسافة القفز", "Speed & Jump")
makeSwitchRow(movCard, 0, "تفعيل السرعة والقفز", "Enable Movement", "تطبيق السرعة والقفز المحددة", "Apply custom speed & jump", function() return S.moveEnabled end, function(v) S.moveEnabled = v; applyMove() end)
makeStepperRow(movCard, 52, "السرعة (WalkSpeed)", "WalkSpeed", function() return S.walkSpeed end, function(v) S.walkSpeed = v end, 2, 16, 140, function(v) return tostring(v) end, function() applyMove() end)
makeStepperRow(movCard, 96, "مسافة / قوة القفز", "Jump Power", function() return S.jumpPower end, function(v) S.jumpPower = v end, 5, 50, 240, function(v) return tostring(v) end, function() applyMove() end)

-- 4) صفحة الهيت بوكس والتريقر بوت
local _, hbCard = makeSectionCard(pages.Combat, UDim2.fromOffset(0, 0), UDim2.new(0.5, -6, 1, 0), "الهيت بوكس (Hitbox)", "Hitbox")
local _, trCard = makeSectionCard(pages.Combat, UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -6, 1, 0), "التريقر بوت (TriggerBot)", "TriggerBot")

makeSwitchRow(hbCard, 0, "تفعيل الهيت بوكس", "Enable Hitbox", "توسيع منطقة الإصابة للخصوم", "Expand target root hitbox", function() return S.hitboxEnabled end, function(v) S.hitboxEnabled = v; applyHb() end)
makeStepperRow(hbCard, 52, "حجم الهيت بوكس", "Hitbox Size", function() return S.hitboxSize end, function(v) S.hitboxSize = v end, 1, 2, 20, function(v) return tostring(v) end, function() applyHb() end)
makeStepperRow(hbCard, 96, "شفافية الهيت بوكس", "Transparency", function() return S.hitboxTrans end, function(v) S.hitboxTrans = v end, 0.05, 0.25, 0.98, function(v) return string.format("%.2f", v) end, function() applyHb() end)

makeSwitchRow(trCard, 0, "تفعيل التريقر بوت", "Enable TriggerBot", "إطلاق تلقائي عند التوجيه على خصم", "Auto-fire when target is under aim", function() return S.triggerEnabled end, function(v) S.triggerEnabled = v end)
makeStepperRow(trCard, 52, "تأخير الإطلاق", "Trigger Delay", function() return S.triggerDelay end, function(v) S.triggerDelay = v end, 0.01, 0, 0.3, function(v) return string.format("%.2fs", v) end)

-- 5) صفحة الإعدادات والحماية
local _, setCard = makeSectionCard(pages.Settings, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), "الحماية والتفضيلات", "Protection & Preferences")
makeSwitchRow(setCard, 0, "تجاهل نفس الفريق", "Team Check", "عدم استهداف أو كشف أعضاء فريقك", "Ignore teammates", function() return S.teamCheck end, function(v) S.teamCheck = v; updateEsp() end)

local noteLbl = Instance.new("TextLabel")
noteLbl.BackgroundTransparency = 1
noteLbl.Position = UDim2.fromOffset(8, 56)
noteLbl.Size = UDim2.new(1, -16, 0, 90)
noteLbl.Font = Enum.Font.Gotham
noteLbl.TextSize = 11
noteLbl.TextColor3 = P.sub
noteLbl.TextWrapped = true
noteLbl.TextXAlignment = Enum.TextXAlignment.Left
noteLbl.Parent = setCard

registerRefresh(function()
	noteLbl.Text = T(
		"• F1 لإخفاء أو إظهار الواجهة.\n• تم استخدام أسماء عشوائية وتنظيف كامل للاتصالات والعناصر لتقليل البصمات الظاهرة على العميل.",
		"• F1 toggles the UI.\n• Randomized naming and full cleanup reduce client-side footprints."
	)
end)

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
	for _, fn in ipairs(uiRefreshers) do
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
	env.ALASHBAT_BAT_UNLOAD = nil
end

env.ALASHBAT_BAT_UNLOAD = unload
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

for _, fn in ipairs(uiRefreshers) do
	fn()
end
setPage("Aimbot")
updateEsp()
