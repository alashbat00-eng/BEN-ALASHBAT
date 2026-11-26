-- ALASHBAT NPC LAB
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts in YOUR Roblox game.
-- Targets NPC/Dummy models only. It deliberately ignores all player characters.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local plr = Players.LocalPlayer
local camera = Workspace.CurrentCamera
if not plr then return end

local S = {
    lang = "EN", aim = false, aimPart = "Head", fov = 130, smooth = 0.18,
    esp = false, boxes = false, distance = true, circle = true, maxRange = 500,
    teamCheck = false
}
local function T(en, ar) return S.lang == "AR" and ar or en end
local function npc(m)
    return m:IsA("Model") and not Players:GetPlayerFromCharacter(m)
        and m:FindFirstChildOfClass("Humanoid") ~= nil
        and m:FindFirstChild("HumanoidRootPart") ~= nil
end
local function getNPCs()
    local t = {}
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and npc(v) then table.insert(t,v) end
    end
    return t
end

local gui = Instance.new("ScreenGui")
gui.Name = "ALASHBAT_NPC_LAB"
gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function make(class, parent, props)
    local x = Instance.new(class)
    for k,v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end
local function round(x, radius)
    make("UICorner", x, {CornerRadius=UDim.new(0,radius or 8)})
end
local gold = Color3.fromRGB(225,178,62)
local white = Color3.fromRGB(238,239,242)
local muted = Color3.fromRGB(155,158,166)
local panel = Color3.fromRGB(19,20,25)

local win = make("Frame",gui,{Size=UDim2.fromOffset(540,390),Position=UDim2.new(.5,-270,.5,-195),BackgroundColor3=Color3.fromRGB(10,11,14),BorderSizePixel=0})
round(win,12)
make("UIStroke",win,{Color=gold,Thickness=1.3})
local top = make("Frame",win,{Size=UDim2.new(1,0,0,48),BackgroundColor3=Color3.fromRGB(24,25,30),BorderSizePixel=0})
round(top,12)
make("TextLabel",top,{BackgroundTransparency=1,Position=UDim2.fromOffset(15,0),Size=UDim2.new(1,-150,1,0),Font=Enum.Font.GothamBlack,Text="ALASHBAT  /  NPC LAB",TextColor3=gold,TextSize=17,TextXAlignment=Enum.TextXAlignment.Left})

local function button(parent,text,size,pos)
    local b=make("TextButton",parent,{Size=size,Position=pos,BackgroundColor3=Color3.fromRGB(38,39,45),BorderSizePixel=0,Text=text,TextColor3=white,Font=Enum.Font.GothamBold,TextSize=12})
    round(b,7)
    return b
end
local lang=button(top,"EN / AR",UDim2.fromOffset(65,28),UDim2.new(1,-145,0,10))
local mini=button(top,"—",UDim2.fromOffset(28,28),UDim2.new(1,-72,0,10))
local close=button(top,"×",UDim2.fromOffset(28,28),UDim2.new(1,-37,0,10))
local side=make("Frame",win,{Position=UDim2.fromOffset(10,58),Size=UDim2.fromOffset(135,320),BackgroundColor3=panel,BorderSizePixel=0}); round(side,9)
local content=make("Frame",win,{Position=UDim2.fromOffset(154,58),Size=UDim2.new(1,-164,1,-68),BackgroundColor3=panel,BorderSizePixel=0}); round(content,9)

local pages,tabs={},{}
local function page(key)
    local p=make("Frame",content,{Name=key,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
    pages[key]=p
    return p
end
local home,aim,visual,settings=page("Home"),page("Aim"),page("Visual"),page("Settings")
local function label(parent,text,y,color)
    return make("TextLabel",parent,{BackgroundTransparency=1,Position=UDim2.fromOffset(15,y),Size=UDim2.new(1,-30,0,28),Font=Enum.Font.Gotham,Text=text,TextColor3=color or white,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left})
end
local function heading(p,text) local l=label(p,text,10,gold); l.Font=Enum.Font.GothamBold; l.TextSize=15 end
local function show(key)
    for k,p in pairs(pages) do p.Visible=(k==key) end
    for k,b in pairs(tabs) do b.BackgroundColor3=(k==key) and Color3.fromRGB(66,50,24) or Color3.fromRGB(38,39,45); b.TextColor3=(k==key) and gold or white end
end
local tabInfo={{"Home","Overview","الرئيسية"},{"Aim","Aim Assist","مساعد التصويب"},{"Visual","NPC Visuals","عرض الشخصيات"},{"Settings","Settings","الإعدادات"}}
for i,d in ipairs(tabInfo) do
    local b=button(side,T(d[2],d[3]),UDim2.new(1,-14,0,36),UDim2.fromOffset(7,10+(i-1)*44))
    tabs[d[1]]=b
    b.MouseButton1Click:Connect(function() show(d[1]) end)
end
local function toggle(p,y,en,ar,key)
    local l=label(p,T(en,ar),y)
    local b=button(p,S[key] and "ON" or "OFF",UDim2.fromOffset(65,26),UDim2.new(1,-80,0,y+1))
    local function refresh() l.Text=T(en,ar); b.Text=S[key] and "ON" or "OFF"; b.TextColor3=S[key] and gold or white end
    b.MouseButton1Click:Connect(function() S[key]=not S[key]; refresh() end)
    return refresh
end
local function cycle(p,y,en,ar,key,choices)
    local l=label(p,T(en,ar),y)
    local b=button(p,S[key],UDim2.fromOffset(105,26),UDim2.new(1,-120,0,y+1))
    b.MouseButton1Click:Connect(function()
        local i=table.find(choices,S[key]) or 1
        S[key]=choices[i%#choices+1]; b.Text=S[key]
    end)
    return function() l.Text=T(en,ar); b.Text=S[key] end
end

heading(home,"TRAINING DASHBOARD")
label(home,"NPC / Dummy tools for your own experience.",45,muted)
local count=label(home,"NPCs found: 0",82,gold)
local scan=button(home,"Rescan NPCs",UDim2.fromOffset(125,31),UDim2.fromOffset(15,120))

heading(aim,"NPC AIM TRAINING")
toggle(aim,48,"Aim assist (NPC only)","مساعد التصويب (NPC فقط)","aim")
cycle(aim,88,"Target part","جزء الاستهداف","aimPart",{"Head","HumanoidRootPart","UpperTorso","Torso"})
label(aim,"FOV radius: +/- buttons",132,muted)
local fovText=label(aim,"130",155,gold)
local minus=button(aim,"−",UDim2.fromOffset(32,26),UDim2.new(1,-115,0,155))
local plus=button(aim,"+",UDim2.fromOffset(32,26),UDim2.new(1,-75,0,155))
minus.MouseButton1Click:Connect(function() S.fov=math.max(30,S.fov-10); fovText.Text=tostring(S.fov) end)
plus.MouseButton1Click:Connect(function() S.fov=math.min(500,S.fov+10); fovText.Text=tostring(S.fov) end)
label(aim,"Smoothness: +/- buttons",195,muted)
local smoothText=label(aim,string.format("%.2f",S.smooth),218,gold)
local sm=button(aim,"−",UDim2.fromOffset(32,26),UDim2.new(1,-115,0,218))
local sp=button(aim,"+",UDim2.fromOffset(32,26),UDim2.new(1,-75,0,218))
sm.MouseButton1Click:Connect(function() S.smooth=math.clamp(S.smooth-.03,.03,1); smoothText.Text=string.format("%.2f",S.smooth) end)
sp.MouseButton1Click:Connect(function() S.smooth=math.clamp(S.smooth+.03,.03,1); smoothText.Text=string.format("%.2f",S.smooth) end)
label(aim,"Hold RIGHT MOUSE to assist NPC aiming.",270,muted)

heading(visual,"NPC VISUAL DEBUG")
toggle(visual,48,"NPC ESP labels","أسماء NPC","esp")
toggle(visual,88,"Hitbox debug boxes","إظهار صناديق Hitbox","boxes")
toggle(visual,128,"Show distance","إظهار المسافة","distance")
toggle(visual,168,"Show FOV circle","إظهار دائرة FOV","circle")
label(visual,"Only NPC / Dummy models are included.",215,muted)

heading(settings,"PREFERENCES")
toggle(settings,48,"Team check (NPC attribute)","فحص الفريق","teamCheck")
label(settings,"Maximum range",95,muted)
local rangeText=label(settings,tostring(S.maxRange),122,gold)
local rm=button(settings,"−",UDim2.fromOffset(32,26),UDim2.new(1,-115,0,122))
local rp=button(settings,"+",UDim2.fromOffset(32,26),UDim2.new(1,-75,0,122))
rm.MouseButton1Click:Connect(function() S.maxRange=math.max(50,S.maxRange-50); rangeText.Text=tostring(S.maxRange) end)
rp.MouseButton1Click:Connect(function() S.maxRange=math.min(2000,S.maxRange+50); rangeText.Text=tostring(S.maxRange) end)
label(settings,"F1 = hide / show menu",175,muted)

local marks,labels,boxes={},{},{}
local function clearVisuals()
    for _,v in pairs(marks) do v:Destroy() end
    for _,v in pairs(labels) do v:Destroy() end
    for _,v in pairs(boxes) do v:Destroy() end
    table.clear(marks); table.clear(labels); table.clear(boxes)
end
local function updateVisuals()
    local char=plr.Character
    local myRoot=char and char:FindFirstChild("HumanoidRootPart")
    local alive={}
    for _,m in ipairs(getNPCs()) do
        local hum=m:FindFirstChildOfClass("Humanoid")
        local hrp=m:FindFirstChild("HumanoidRootPart")
        local dist=myRoot and (myRoot.Position-hrp.Position).Magnitude or 0
        if hum and hum.Health>0 and dist<=S.maxRange then
            alive[m]=true
            if S.esp then
                if not marks[m] then
                    marks[m]=make("Highlight",m,{Name="ALASHBAT_NPC_Highlight",FillColor=gold,OutlineColor=white,FillTransparency=.78,DepthMode=Enum.HighlightDepthMode.Occluded})
                end
                if not labels[m] then
                    local bb=make("BillboardGui",gui,{Name="ALASHBAT_NPC_Label",Size=UDim2.fromOffset(180,28),StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=false,Adornee=hrp})
                    labels[m]=make("TextLabel",bb,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=gold,TextStrokeTransparency=.3})
                end
                labels[m].Text=m.Name..(S.distance and (" ["..math.floor(dist).."m]") or "")
            else
                if marks[m] then marks[m]:Destroy(); marks[m]=nil end
                if labels[m] then labels[m].Parent:Destroy(); labels[m]=nil end
            end
            if S.boxes then
                for _,part in ipairs(m:GetDescendants()) do
                    if part:IsA("BasePart") and (part.Name=="Head" or part.Name=="HumanoidRootPart" or part.Name=="UpperTorso" or part.Name=="Torso") and not boxes[part] then
                        boxes[part]=make("SelectionBox",gui,{Adornee=part,Color3=Color3.fromRGB(70,190,255),LineThickness=.035,SurfaceTransparency=.9})
                    end
                end
            end
        end
    end
    for m,v in pairs(marks) do if not alive[m] or not S.esp then v:Destroy(); marks[m]=nil end end
    for m,v in pairs(labels) do if not alive[m] or not S.esp then v.Parent:Destroy(); labels[m]=nil end end
    for p,v in pairs(boxes) do if not p.Parent or not S.boxes then v:Destroy(); boxes[p]=nil end end
end

local circle=make("Frame",gui,{Name="FOV",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(S.fov*2,S.fov*2),BackgroundTransparency=1})
make("UICorner",circle,{CornerRadius=UDim.new(1,0)})
make("UIStroke",circle,{Color=gold,Thickness=1.2,Transparency=.2})

local function bestTarget()
    local center=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local myChar=plr.Character
    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
    local best,bd
    for _,m in ipairs(getNPCs()) do
        local h=m:FindFirstChildOfClass("Humanoid")
        local hrp=m:FindFirstChild("HumanoidRootPart")
        local part=m:FindFirstChild(S.aimPart)
        local same=S.teamCheck and m:GetAttribute("Team")~=nil and m:GetAttribute("Team")==plr:GetAttribute("Team")
        if h and h.Health>0 and hrp and part and not same then
            local dist=myRoot and (myRoot.Position-hrp.Position).Magnitude or 0
            local p,on=camera:WorldToViewportPoint(part.Position)
            if on and dist<=S.maxRange then
                local d=(Vector2.new(p.X,p.Y)-center).Magnitude
                if d<=S.fov and (not bd or d<bd) then best,bd=part,d end
            end
        end
    end
    return best
end

scan.MouseButton1Click:Connect(function() count.Text="NPCs found: "..#getNPCs() end)
lang.MouseButton1Click:Connect(function()
    S.lang=S.lang=="EN" and "AR" or "EN"
    lang.Text=S.lang=="EN" and "EN / AR" or "AR / EN"
    for i,d in ipairs(tabInfo) do tabs[d[1]].Text=T(d[2],d[3]) end
    show("Home")
end)
local minimized=false
mini.MouseButton1Click:Connect(function()
    minimized=not minimized
    side.Visible=not minimized; content.Visible=not minimized
    win.Size=minimized and UDim2.fromOffset(540,48) or UDim2.fromOffset(540,390)
    mini.Text=minimized and "+" or "—"
end)
close.MouseButton1Click:Connect(function() clearVisuals(); gui:Destroy() end)

local dragging,dragStart,startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPos=win.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-dragStart
        win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
local hidden=false
UIS.InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.F1 then hidden=not hidden; win.Visible=not hidden end
end)

RunService.RenderStepped:Connect(function()
    if not gui.Parent then return end
    circle.Visible=S.circle
    circle.Size=UDim2.fromOffset(S.fov*2,S.fov*2)
    if S.aim and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target=bestTarget()
        if target then
            local goal=CFrame.new(camera.CFrame.Position,target.Position)
            camera.CFrame=camera.CFrame:Lerp(goal,S.smooth)
        end
    end
end)
task.spawn(function()
    while gui.Parent do
        updateVisuals()
        count.Text="NPCs found: "..#getNPCs()
        task.wait(.4)
    end
end)
show("Home")
