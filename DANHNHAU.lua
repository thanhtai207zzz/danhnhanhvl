-- Combat Menu Full Script (Fram Boss + PvP UI + Đã tách riêng hoạt động PvP)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "CombatUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Position = UDim2.new(0, 30, 0, 50)
mainFrame.Size = UDim2.new(0, 350, 0, 420)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "thanh tài💤"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Text = "✖"
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

local tabHolder = Instance.new("Frame", mainFrame)
tabHolder.Position = UDim2.new(0, 0, 0, 35)
tabHolder.Size = UDim2.new(1, 0, 0, 35)
tabHolder.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local function createTab(name, pos, callback)
	local btn = Instance.new("TextButton", tabHolder)
	btn.Size = UDim2.new(0, 120, 0, 30)
	btn.Position = UDim2.new(0, pos, 0, 2)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = name
	btn.MouseButton1Click:Connect(callback)
end

local bossTab = Instance.new("Frame", mainFrame)
bossTab.Position = UDim2.new(0, 0, 0, 70)
bossTab.Size = UDim2.new(1, 0, 1, -70)
bossTab.BackgroundTransparency = 1

local pvpTab = bossTab:Clone()
pvpTab.Parent = mainFrame
pvpTab.Visible = false

createTab("🔥 Fram Boss", 10, function()
	bossTab.Visible = true
	pvpTab.Visible = false
end)

createTab("⚔️ PvP", 140, function()
	bossTab.Visible = false
	pvpTab.Visible = true
end)

-- Variables
local radius = 20
local trianglePoints = {
	Vector3.new(1, 0, 0),
	Vector3.new(-0.5, 0, math.sqrt(3)/2),
	Vector3.new(-0.5, 0, -math.sqrt(3)/2)
}
local currentPoint = 1
local selectedBoss = nil
local isFramEnabled = false
local framCooldown = 0
local bossLabel = Instance.new("TextLabel", screenGui)
bossLabel.Size = UDim2.new(0, 250, 0, 25)
bossLabel.Position = UDim2.new(1, -260, 0, 20)
bossLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bossLabel.BackgroundTransparency = 0.4
bossLabel.TextColor3 = Color3.new(1, 0.5, 0.5)
bossLabel.Font = Enum.Font.GothamBold
bossLabel.TextSize = 16
bossLabel.Text = "💔 Boss: Đang tìm..."
bossLabel.Visible = false

local framToggle = Instance.new("TextButton", bossTab)
framToggle.Size = UDim2.new(0, 300, 0, 40)
framToggle.Position = UDim2.new(0.5, -150, 0, 10)
framToggle.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
framToggle.Text = "✅ Bật Fram Boss"
framToggle.TextColor3 = Color3.new(1, 1, 1)
framToggle.Font = Enum.Font.GothamBold
framToggle.TextSize = 16
framToggle.MouseButton1Click:Connect(function()
	isFramEnabled = not isFramEnabled
	framToggle.Text = isFramEnabled and "⛔ Tắt Fram Boss" or "✅ Bật Fram Boss"
	framToggle.BackgroundColor3 = isFramEnabled and Color3.fromRGB(120, 50, 50) or Color3.fromRGB(50, 120, 50)
	bossLabel.Visible = isFramEnabled
end)

local function getClosestBoss()
	local closest, shortest = nil, math.huge
	for _, model in pairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			if model ~= Character then
				local dist = (HRP.Position - model.HumanoidRootPart.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = model
				end
			end
		end
	end
	return closest
end

-- PvP
local pvpVars = {}
local enemyTags = {}
local pvpFunctions = {
	{ name = "Hitbox ", var = "hitboxEnabled" },
	{ name = "Speed CFrame", var = "speedEnabled" },
	{ name = "Tự Đánh ", var = "autoAttack" },
	{ name = "Xoá Tường", var = "wallRemoved" },
	{ name = "Hiện Địch | esp Tên", var = "enemyMarkers" },
	{ name = "Spin Nhân Vật", var = "spinEnabled" },
	{ name = "Tốc độ Vung ", var = "swingSpeed" },
	{ name = "ESP Máu", var = "enemyHP" }
}

for i, func in ipairs(pvpFunctions) do
	pvpVars[func.var] = false
	local toggle = Instance.new("TextButton", pvpTab)
	toggle.Size = UDim2.new(1, -40, 0, 30)
	toggle.Position = UDim2.new(0, 20, 0, 10 + (i - 1) * 35)
	toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 14
	toggle.Text = "❌ " .. func.name
	toggle.MouseButton1Click:Connect(function()
		pvpVars[func.var] = not pvpVars[func.var]
		toggle.Text = (pvpVars[func.var] and "✅ " or "❌ ") .. func.name
		toggle.BackgroundColor3 = pvpVars[func.var] and Color3.fromRGB(70, 120, 70) or Color3.fromRGB(60, 60, 60)
	end)
end

-- MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
	if isFramEnabled then
		framCooldown -= dt
		if framCooldown <= 0 then
			selectedBoss = getClosestBoss()
			if selectedBoss and selectedBoss:FindFirstChild("Humanoid") and selectedBoss.Humanoid.Health > 0 then
				local bossPos = selectedBoss.HumanoidRootPart.Position
				local point = trianglePoints[currentPoint] * radius
				HRP.CFrame = CFrame.new(bossPos + point, bossPos)
				currentPoint = (currentPoint % #trianglePoints) + 1
				framCooldown = 0.08
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
				bossLabel.Text = "💔 " .. selectedBoss.Name .. ": " .. math.floor(selectedBoss.Humanoid.Health)
			else
				bossLabel.Text = "⚠️ Boss: Không hợp lệ"
			end
		end
	end

	if pvpVars.autoAttack then
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
	end
	if pvpVars.speedEnabled then
		local dir = Character.Humanoid.MoveDirection
		if dir.Magnitude > 0 then HRP.CFrame += dir.Unit * 2.5 end
	end
	if pvpVars.hitboxEnabled then
		for _, v in pairs(Character:GetChildren()) do
			if v:IsA("Tool") and v:FindFirstChild("Handle") and not v:FindFirstChild("HitboxPart") then
				local box = Instance.new("Part", v)
				box.Size = Vector3.new(16,16,16)
				box.Transparency = 0.7
				box.Color = Color3.fromRGB(255, 255, 255)
				box.Anchored = false
				box.CanCollide = false
				box.Name = "HitboxPart"
				local weld = Instance.new("WeldConstraint", box)
				weld.Part0 = box
				weld.Part1 = v.Handle
				box.CFrame = v.Handle.CFrame
			end
		end
	end
	if pvpVars.wallRemoved then
		for _, p in pairs(workspace:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 0.2 and p.Size.Magnitude > 15 then
				p:Destroy()
			end
		end
		pvpVars.wallRemoved = false
	end
	if pvpVars.spinEnabled then
		HRP.CFrame *= CFrame.Angles(0, math.rad(5), 0)
	end
	if pvpVars.enemyMarkers then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and not enemyTags[plr.Name] then
				local tag = Instance.new("BillboardGui", plr.Character.Head)
				tag.Name = "EnemyTag"
				tag.Size = UDim2.new(0, 100, 0, 20)
				tag.StudsOffset = Vector3.new(0, 3, 0)
				tag.AlwaysOnTop = true
				local label = Instance.new("TextLabel", tag)
				label.Size = UDim2.new(1, 0, 1, 0)
				label.Text = "💤 " .. plr.Name
				label.BackgroundTransparency = 1
				label.TextColor3 = Color3.new(1, 0, 0)
				label.TextScaled = true
				enemyTags[plr.Name] = tag
			end
		end
	end
	if pvpVars.enemyHP then
		for _, plr in pairs(Players:GetPlayers()) do
			local char = plr.Character
			if plr ~= LocalPlayer and char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
				local tag = char:FindFirstChild("EnemyTag")
				if tag and tag:FindFirstChild("TextLabel") then
					tag.TextLabel.Text = "💤 " .. plr.Name .. " | HP: " .. math.floor(char.Humanoid.Health)
				end
			end
		end
	end
end)
