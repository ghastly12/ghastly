local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
	AimbotEnabled = false,
	ESPEnabled = false,
	GUIEnabled = true,
	FOVRadius = 180,
	FOVColor = Color3.fromRGB(255, 255, 255),
	Stickiness = 3,
	BoneTarget = "Head",
	TargetMode = "Crosshair",
	RMBActivation = true,
	VisibilityCheck = false,
	ESPColor = Color3.fromRGB(255, 60, 60),
	ESPVisColor = Color3.fromRGB(60, 255, 60),
	ESPHiddenColor = Color3.fromRGB(255, 60, 60),
	ESPTransparency = 0.5,
	ESPVisCheck = false,
	CurrentTheme = "Default",
}

local Themes = {
	Default = {Main = Color3.fromRGB(25,25,30), Accent = Color3.fromRGB(40,10,60), Button = Color3.fromRGB(50,15,80), Text = Color3.fromRGB(255,255,255), Highlight = Color3.fromRGB(180,50,255), Glow = Color3.fromRGB(200,100,255)},
	Sunset = {Main = Color3.fromRGB(50,30,20), Accent = Color3.fromRGB(80,40,25), Button = Color3.fromRGB(120,50,30), Text = Color3.fromRGB(255,220,200), Highlight = Color3.fromRGB(255,140,80), Glow = Color3.fromRGB(255,160,100)},
	Midnight = {Main = Color3.fromRGB(15,15,35), Accent = Color3.fromRGB(10,20,50), Button = Color3.fromRGB(20,30,70), Text = Color3.fromRGB(180,200,255), Highlight = Color3.fromRGB(50,80,200), Glow = Color3.fromRGB(80,120,255)},
	DeepRed = {Main = Color3.fromRGB(40,10,10), Accent = Color3.fromRGB(60,10,10), Button = Color3.fromRGB(80,15,15), Text = Color3.fromRGB(255,180,180), Highlight = Color3.fromRGB(255,40,40), Glow = Color3.fromRGB(255,80,80)},
	Atlantic = {Main = Color3.fromRGB(10,30,60), Accent = Color3.fromRGB(15,45,80), Button = Color3.fromRGB(20,60,110), Text = Color3.fromRGB(200,230,255), Highlight = Color3.fromRGB(30,100,180), Glow = Color3.fromRGB(50,150,240)},
	Pacific = {Main = Color3.fromRGB(10,50,70), Accent = Color3.fromRGB(15,70,90), Button = Color3.fromRGB(20,90,120), Text = Color3.fromRGB(200,255,255), Highlight = Color3.fromRGB(30,130,170), Glow = Color3.fromRGB(40,170,210)},
	Sunrise = {Main = Color3.fromRGB(60,40,15), Accent = Color3.fromRGB(90,55,20), Button = Color3.fromRGB(130,70,25), Text = Color3.fromRGB(255,240,210), Highlight = Color3.fromRGB(255,200,100), Glow = Color3.fromRGB(255,220,130)},
	Blue = {Main = Color3.fromRGB(20,20,180), Accent = Color3.fromRGB(30,30,200), Button = Color3.fromRGB(40,40,230), Text = Color3.fromRGB(220,220,255), Highlight = Color3.fromRGB(60,60,255), Glow = Color3.fromRGB(100,100,255)},
	Cyan = {Main = Color3.fromRGB(15,160,160), Accent = Color3.fromRGB(20,180,180), Button = Color3.fromRGB(30,200,200), Text = Color3.fromRGB(220,255,255), Highlight = Color3.fromRGB(50,230,230), Glow = Color3.fromRGB(80,255,255)},
	Red = {Main = Color3.fromRGB(180,20,20), Accent = Color3.fromRGB(200,30,30), Button = Color3.fromRGB(230,40,40), Text = Color3.fromRGB(255,220,220), Highlight = Color3.fromRGB(255,60,60), Glow = Color3.fromRGB(255,100,100)},
	DeepBlue = {Main = Color3.fromRGB(8,15,80), Accent = Color3.fromRGB(12,25,110), Button = Color3.fromRGB(18,35,140), Text = Color3.fromRGB(200,210,255), Highlight = Color3.fromRGB(30,55,200), Glow = Color3.fromRGB(50,80,255)},
}

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVCircle"
FOVGui.Parent = CoreGui
FOVGui.IgnoreGuiInset = true

local FOVFrame = Instance.new("Frame")
FOVFrame.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.BackgroundTransparency = 1
FOVFrame.BorderSizePixel = 0
FOVFrame.Visible = false
FOVFrame.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Settings.FOVColor
FOVStroke.Thickness = 1.5
FOVStroke.Parent = FOVFrame
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)

local function UpdateFOV()
	FOVFrame.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
	FOVStroke.Color = Settings.FOVColor
	FOVFrame.Visible = Settings.AimbotEnabled
end

local function GetPlayers()
	local targets = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hum = p.Character:FindFirstChildWhichIsA("Humanoid")
			local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
			local head = p.Character:FindFirstChild("Head")
			if hum and hum.Health > 0 and root and head then
				table.insert(targets, {Player = p, Character = p.Character, Humanoid = hum, RootPart = root, Head = head})
			end
		end
	end
	return targets
end

local function GetBonePos(t, bone)
	if bone == "Head" then return t.Head.Position end
	if bone == "Torso" then return t.RootPart.Position end
	return math.random() > 0.5 and t.Head.Position or t.RootPart.Position
end

local function IsVisible(t)
	local origin = Camera.CFrame.Position
	local pos = GetBonePos(t, Settings.BoneTarget)
	local ray = Ray.new(origin, (pos - origin).Unit * 500)
	local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
	return hit and hit:IsDescendantOf(t.Character)
end

local function IsInFOV(t)
	local pos = GetBonePos(t, Settings.BoneTarget)
	local sp, onScreen = Camera:WorldToViewportPoint(pos)
	if not onScreen then return false end
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	return (Vector2.new(sp.X, sp.Y) - center).Magnitude < Settings.FOVRadius
end

local LockedTarget = nil

local function AcquireTarget()
	local targets = GetPlayers()
	if #targets == 0 then return nil end
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local best, bestDist = nil, math.huge
	for _, t in pairs(targets) do
		local sp, onScreen = Camera:WorldToViewportPoint(GetBonePos(t, Settings.BoneTarget))
		if onScreen then
			local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
			if screenDist < Settings.FOVRadius then
				if not Settings.VisibilityCheck or IsVisible(t) then
					local cmpDist = Settings.TargetMode == "Crosshair" and screenDist or (GetBonePos(t, Settings.BoneTarget) - Camera.CFrame.Position).Magnitude
					if cmpDist < bestDist then
						bestDist = cmpDist
						best = t
					end
				end
			end
		end
	end
	return best
end

local function ShouldReleaseLock()
	if not LockedTarget then return true end
	if not LockedTarget.Player.Parent then return true end
	if not LockedTarget.Character then return true end
	local hum = LockedTarget.Character:FindFirstChildWhichIsA("Humanoid")
	if not hum or hum.Health <= 0 then return true end
	if not IsInFOV(LockedTarget) then return true end
	if Settings.VisibilityCheck and not IsVisible(LockedTarget) then return true end
	return false
end

local function AimAtTarget(t)
	local pos = GetBonePos(t, Settings.BoneTarget)
	local sp, onScreen = Camera:WorldToViewportPoint(pos)
	if not onScreen then return end
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local delta = Vector2.new(sp.X, sp.Y) - center
	local factor = math.clamp(1 - (Settings.Stickiness - 1) * 0.09, 0.1, 1)
	mousemoverel(math.floor(delta.X * factor + 0.5), math.floor(delta.Y * factor + 0.5))
end

RunService.RenderStepped:Connect(function()
	if not Settings.AimbotEnabled then
		LockedTarget = nil
		return
	end
	if Settings.RMBActivation and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		LockedTarget = nil
		return
	end
	if ShouldReleaseLock() then LockedTarget = nil end
	if not LockedTarget then LockedTarget = AcquireTarget() end
	if LockedTarget then AimAtTarget(LockedTarget) end
end)

local ESPObjects = {}

local function UpdateESP()
	for _, obj in pairs(ESPObjects) do pcall(function() obj:Destroy() end) end
	ESPObjects = {}
	if not Settings.ESPEnabled then return end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local char = p.Character
			local visible = true
			if Settings.ESPVisCheck then
				local head = char:FindFirstChild("Head")
				local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
				if head and root then
					local target = {Character = char, Head = head, RootPart = root}
					visible = IsVisible(target)
				end
			end
			local color = visible and Settings.ESPVisColor or Settings.ESPHiddenColor
			for _, part in pairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Transparency < 1 then
					local hl = Instance.new("Highlight")
					hl.Name = "ESP"
					hl.FillColor = color
					hl.FillTransparency = Settings.ESPTransparency
					hl.OutlineColor = color
					hl.OutlineTransparency = 0.2
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = part
					table.insert(ESPObjects, hl)
				end
			end
		end
	end
end

spawn(function() while task.wait(1) do pcall(UpdateESP) end end)

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "PhantomAim"
MainGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 380)
Main.Position = UDim2.new(0.5, -140, 0.5, -190)
Main.BackgroundColor3 = Themes[Settings.CurrentTheme].Main
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = MainGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("Frame")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Themes[Settings.CurrentTheme].Accent
Title.BorderSizePixel = 0
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 8)
TitleFix.Position = UDim2.new(0, 0, 1, -8)
TitleFix.BackgroundColor3 = Themes[Settings.CurrentTheme].Accent
TitleFix.BorderSizePixel = 0
TitleFix.Parent = Title

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -20, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "KING VRX AIMBOT V1"
TitleText.TextColor3 = Themes[Settings.CurrentTheme].Text
TitleText.Font = Enum.Font.GothamBlack
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Title

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 28)
TabBar.Position = UDim2.new(0, 0, 0, 34)
TabBar.BackgroundColor3 = Themes[Settings.CurrentTheme].Accent
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local tabs, pages, activeTab = {}, {}, nil
local function CreateTab(name, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 65, 1, -4)
	btn.Position = UDim2.new(0, 4 + (order - 1) * 69, 0, 2)
	btn.BackgroundColor3 = Themes[Settings.CurrentTheme].Button
	btn.TextColor3 = Themes[Settings.CurrentTheme].Text
	btn.Text = name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.BorderSizePixel = 0
	btn.Parent = TabBar
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
	
	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, -10, 1, -68)
	page.Position = UDim2.new(0, 5, 0, 64)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 3
	page.BorderSizePixel = 0
	page.Visible = false
	page.Parent = Main
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = page
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
	end)
	
	btn.MouseButton1Click:Connect(function()
		if activeTab then activeTab.BackgroundColor3 = Themes[Settings.CurrentTheme].Button end
		for _, p in pairs(pages) do p.Visible = false end
		btn.BackgroundColor3 = Themes[Settings.CurrentTheme].Highlight
		page.Visible = true
		activeTab = btn
	end)
	
	table.insert(tabs, btn)
	table.insert(pages, page)
	return page
end

local AimPage = CreateTab("🎯 Aim", 1)
local ESPPage = CreateTab("👁 ESP", 2)
local ThemePage = CreateTab("🎨 Theme", 3)

if tabs[1] then tabs[1].BackgroundColor3 = Themes[Settings.CurrentTheme].Highlight; pages[1].Visible = true; activeTab = tabs[1] end

local function MakeToggle(page, text, setting)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Themes[Settings.CurrentTheme].Button
	btn.TextColor3 = Themes[Settings.CurrentTheme].Text
	btn.Text = text .. ": OFF"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.BorderSizePixel = 0
	btn.Parent = page
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	
	btn.MouseButton1Click:Connect(function()
		Settings[setting] = not Settings[setting]
		btn.Text = text .. ": " .. (Settings[setting] and "ON" or "OFF")
		btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(60, 200, 60) or Themes[Settings.CurrentTheme].Button
		if setting == "AimbotEnabled" then UpdateFOV() end
		if setting == "ESPEnabled" or setting == "ESPVisCheck" then UpdateESP() end
	end)
	return btn
end

local function MakeSlider(page, text, setting, min, max)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 50)
	f.BackgroundColor3 = Themes[Settings.CurrentTheme].Button
	f.BorderSizePixel = 0
	f.Parent = page
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 0, 18)
	lbl.Position = UDim2.new(0, 5, 0, 3)
	lbl.BackgroundTransparency = 1
	lbl.Text = text .. ": " .. tostring(Settings[setting])
	lbl.TextColor3 = Themes[Settings.CurrentTheme].Text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f
	
	local inp = Instance.new("TextBox")
	inp.Size = UDim2.new(1, -10, 0, 22)
	inp.Position = UDim2.new(0, 5, 0, 24)
	inp.BackgroundColor3 = Themes[Settings.CurrentTheme].Accent
	inp.TextColor3 = Themes[Settings.CurrentTheme].Text
	inp.Text = tostring(Settings[setting])
	inp.Font = Enum.Font.Gotham
	inp.TextSize = 10
	inp.BorderSizePixel = 0
	inp.Parent = f
	Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 3)
	
	inp.FocusLost:Connect(function()
		local n = tonumber(inp.Text)
		if n and n >= min and n <= max then
			Settings[setting] = n
			lbl.Text = text .. ": " .. tostring(n)
			if setting == "FOVRadius" then UpdateFOV() end
			if setting == "ESPTransparency" then UpdateESP() end
		else
			inp.Text = tostring(Settings[setting])
		end
	end)
	return f
end

local function MakeDropdown(page, text, setting, options)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 28)
	f.BackgroundColor3 = Themes[Settings.CurrentTheme].Button
	f.BorderSizePixel = 0
	f.Parent = page
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.5, -5, 1, 0)
	lbl.Position = UDim2.new(0, 5, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Themes[Settings.CurrentTheme].Text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.5, -5, 1, -4)
	btn.Position = UDim2.new(0.5, 0, 0, 2)
	btn.BackgroundColor3 = Themes[Settings.CurrentTheme].Accent
	btn.TextColor3 = Themes[Settings.CurrentTheme].Text
	btn.Text = Settings[setting]
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.BorderSizePixel = 0
	btn.Parent = f
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
	
	local idx = 1
	for i, opt in pairs(options) do if opt == Settings[setting] then idx = i end end
	
	btn.MouseButton1Click:Connect(function()
		idx = idx % #options + 1
		Settings[setting] = options[idx]
		btn.Text = options[idx]
	end)
	return f
end

MakeToggle(AimPage, "Aimbot Master", "AimbotEnabled")
MakeToggle(AimPage, "RMB Activation", "RMBActivation")
MakeToggle(AimPage, "Visibility Check", "VisibilityCheck")
MakeSlider(AimPage, "FOV Radius", "FOVRadius", 30, 500)
MakeSlider(AimPage, "Stickiness", "Stickiness", 1, 10)
MakeDropdown(AimPage, "Bone Target", "BoneTarget", {"Head", "Torso", "Random"})
MakeDropdown(AimPage, "Target Mode", "TargetMode", {"Crosshair", "Distance"})

MakeToggle(ESPPage, "ESP Master", "ESPEnabled")
MakeToggle(ESPPage, "Vis Colors", "ESPVisCheck")
MakeSlider(ESPPage, "ESP Transparency", "ESPTransparency", 0, 1)

for _, name in pairs({"Default","Sunset","Midnight","DeepRed","Atlantic","Pacific","Sunrise","Blue","Cyan","Red","DeepBlue"}) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = Themes[name].Highlight
	btn.TextColor3 = Themes[name].Text
	btn.Text = name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.BorderSizePixel = 0
	btn.Parent = ThemePage
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	btn.MouseButton1Click:Connect(function()
		Settings.CurrentTheme = name
		local t = Themes[name]
		Main.BackgroundColor3 = t.Main
		Title.BackgroundColor3 = t.Accent
		TitleFix.BackgroundColor3 = t.Accent
		TitleText.TextColor3 = t.Text
		TabBar.BackgroundColor3 = t.Accent
		for _, b in pairs(tabs) do
			if b ~= activeTab then b.BackgroundColor3 = t.Button end
			b.TextColor3 = t.Text
		end
		if activeTab then activeTab.BackgroundColor3 = t.Highlight end
	end)
end

local dragging, dragStart, startPos = false, nil, nil
Title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = i.Position; startPos = Main.Position
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = i.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.T then
		Settings.GUIEnabled = not Settings.GUIEnabled
		MainGui.Enabled = Settings.GUIEnabled
		FOVGui.Enabled = Settings.GUIEnabled
	end
end)

UpdateFOV()
UpdateESP()
