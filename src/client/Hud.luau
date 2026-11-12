--!strict
-- Hud: mobil oncelikli arayuz, tamamen kodla kurulur.
--
-- Kurallar (spec §3.9):
--  - Tum olculer Scale tabanli (piksel = yalnizca kucuk padding).
--  - Dokunma hedefi >= ekran yuksekliginin %8'i.
--  - Tek ana HUD; detaylar sonuc panelinde.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = {}

local playerGui: PlayerGui? = nil
local birdLabel: TextLabel? = nil
local scoreLabel: TextLabel? = nil
local resultFrame: Frame? = nil
local starsLabel: TextLabel? = nil
local scoreResultLabel: TextLabel? = nil
local primaryButton: TextButton? = nil
local secondaryButton: TextButton? = nil

local COLORS = {
	panel = Color3.fromRGB(24, 26, 32),
	accent = Color3.fromRGB(240, 176, 66),
	text = Color3.fromRGB(240, 240, 240),
	muted = Color3.fromRGB(150, 156, 168),
}

local function makeLabel(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	position: UDim2
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = COLORS.text
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = UDim2.fromScale(0.42, 0.14)
	button.Position = position
	button.BackgroundColor3 = COLORS.accent
	button.TextColor3 = Color3.fromRGB(24, 26, 32)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = button

	return button
end

function Hud.attach(callbacks: {
	onPrimary: () -> (),
	onSecondary: () -> (),
}): ()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FlockfallHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = gui

	birdLabel =
		makeLabel(root, "Birds", "KUS 3", UDim2.fromScale(0.3, 0.07), UDim2.fromScale(0.03, 0.03))
	birdLabel.TextXAlignment = Enum.TextXAlignment.Left

	scoreLabel =
		makeLabel(root, "Score", "0", UDim2.fromScale(0.3, 0.07), UDim2.fromScale(0.67, 0.03))
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
	scoreLabel.TextColor3 = COLORS.accent

	-- Sonuc paneli
	local result = Instance.new("Frame")
	result.Name = "Result"
	result.AnchorPoint = Vector2.new(0.5, 0.5)
	result.Position = UDim2.fromScale(0.5, 0.5)
	result.Size = UDim2.fromScale(0.72, 0.5)
	result.BackgroundColor3 = COLORS.panel
	result.BackgroundTransparency = 0.08
	result.BorderSizePixel = 0
	result.Visible = false
	result.Parent = root
	resultFrame = result

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = result

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1.6
	ratio.AspectType = Enum.AspectType.FitWithinMaxSize
	ratio.DominantAxis = Enum.DominantAxis.Width
	ratio.Parent = result

	starsLabel =
		makeLabel(result, "Stars", "", UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.12))
	starsLabel.TextXAlignment = Enum.TextXAlignment.Center
	starsLabel.TextColor3 = COLORS.accent

	scoreResultLabel = makeLabel(
		result,
		"ScoreResult",
		"",
		UDim2.fromScale(0.9, 0.12),
		UDim2.fromScale(0.05, 0.34)
	)
	scoreResultLabel.TextXAlignment = Enum.TextXAlignment.Center
	scoreResultLabel.TextColor3 = COLORS.text

	primaryButton = makeButton(result, "Primary", "SONRAKI", UDim2.fromScale(0.06, 0.62))
	secondaryButton = makeButton(result, "Secondary", "YENIDEN", UDim2.fromScale(0.52, 0.62))
	secondaryButton.BackgroundColor3 = COLORS.muted

	primaryButton.Activated:Connect(callbacks.onPrimary)
	secondaryButton.Activated:Connect(callbacks.onSecondary)

	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	gui.Parent = playerGui
end

function Hud.setBirds(count: number): ()
	if birdLabel ~= nil then
		birdLabel.Text = "KUS " .. tostring(count)
	end
end

function Hud.setScore(score: number): ()
	if scoreLabel ~= nil then
		scoreLabel.Text = tostring(score)
	end
end

function Hud.showResult(payload: any): ()
	if resultFrame == nil then
		return
	end
	resultFrame.Visible = true
	resultFrame.BackgroundTransparency = 1

	local stars = payload.stars or 1
	local starText = ""
	for _ = 1, stars do
		starText ..= "★ "
	end
	if starsLabel ~= nil then
		starsLabel.Text = starText
	end
	if scoreResultLabel ~= nil then
		scoreResultLabel.Text = "SKOR " .. tostring(payload.score or 0)
	end
	if primaryButton ~= nil then
		primaryButton.Text = payload.phase == "won" and "SONRAKI" or "TEKRAR"
	end

	TweenService:Create(resultFrame, TweenInfo.new(0.35), { BackgroundTransparency = 0.08 }):Play()
end

function Hud.hideResult(): ()
	if resultFrame ~= nil then
		resultFrame.Visible = false
	end
end

function Hud.reset(): ()
	Hud.hideResult()
	Hud.setScore(0)
end

return Hud
