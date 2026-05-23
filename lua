--// Inicialização Prévia
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/other.lua"))() end)

--// Serviços
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// Prevenção de Duplicação da UI
if CoreGui:FindFirstChild("Z3US Loader") then
	CoreGui["Z3US Loader"]:Destroy()
end

--// Configurações de Tema (Cores)
local Theme = {
	Background = Color3.fromRGB(17, 18, 20),
	FrameHover = Color3.fromRGB(25, 27, 30),
	StrokeNormal = Color3.fromRGB(26, 29, 37),
	StrokeSelected = Color3.fromRGB(140, 155, 208),
	StrokeHover = Color3.fromRGB(50, 55, 70),
	TextNormal = Color3.fromRGB(255, 255, 255),
	ToggleOn = Color3.fromRGB(140, 155, 208),
	ToggleOff = Color3.fromRGB(60, 60, 60)
}

-- Animação Padrão
local FastTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--// Variáveis de Estado
local State = {
	SelectedScript = nil,
	Autoload = true,
	Silentload = false,
	Version = "New"
}

--// Criação da UI Principal
local z3USLoader = Instance.new("ScreenGui")
z3USLoader.Name = "Z3US Loader"
z3USLoader.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
z3USLoader.ResetOnSpawn = false
z3USLoader.IgnoreGuiInset = true

-- Tenta colocar no CoreGui (Exploits), senão usa PlayerGui (Roblox Studio)
pcall(function() z3USLoader.Parent = CoreGui end)
if not z3USLoader.Parent then z3USLoader.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.BackgroundColor3 = Theme.Background
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromOffset(878, 550)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Parent = z3USLoader

local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0, 25)
uICorner.Parent = frame

--// Arrastar Janela Suave (Smooth Drag)
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		}):Play()
	end
end)

--// Logo
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://92661965333918"
logo.Position = UDim2.fromScale(0.755, 0.2)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.Size = UDim2.fromOffset(175, 175)
logo.Parent = frame

--// Construtor Automático de Textos
local function CreateText(name, text, pos, size, color, fontSize)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.BackgroundTransparency = 1
	lbl.Position = pos
	lbl.Size = size
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.TextSize = fontSize
	lbl.FontFace = Font.new("rbxasset://fonts/families/Nunito.json")
	lbl.Parent = frame
	return lbl
end

local textLabel5 = CreateText("ThanksText", "Thank you for using Z3US <3", UDim2.fromScale(0.628, 0.821), UDim2.fromOffset(200, 50), Color3.fromRGB(40, 58, 85), 34)
local textLabel6 = CreateText("StatusText", "No Script Selected", UDim2.fromScale(0.645, 0.447), UDim2.fromOffset(200, 50), Theme.TextNormal, 34)

--// Botão Fechar "X"
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.BackgroundTransparency = 1
closeButton.Position = UDim2.fromScale(0.949, 0.0172)
closeButton.Size = UDim2.fromOffset(44, 41)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(58, 67, 98)
closeButton.TextSize = 24
closeButton.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
closeButton.Parent = frame

closeButton.MouseEnter:Connect(function() TweenService:Create(closeButton, FastTween, {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play() end)
closeButton.MouseLeave:Connect(function() TweenService:Create(closeButton, FastTween, {TextColor3 = Color3.fromRGB(58, 67, 98)}):Play() end)
closeButton.MouseButton1Click:Connect(function() z3USLoader:Destroy() end)

--// Painel de Aviso (Rivals Ban Warning)
local blackout = Instance.new("Frame")
blackout.Name = "Blackout"
blackout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackout.BackgroundTransparency = 1
blackout.Size = UDim2.fromScale(1, 1)
blackout.ZIndex = 8
blackout.Visible = false
Instance.new("UICorner", blackout).CornerRadius = UDim.new(0, 25)
blackout.Parent = frame

local confipanel = Instance.new("Frame")
confipanel.Name = "ConfirmPanel"
confipanel.BackgroundColor3 = Theme.Background
confipanel.Position = UDim2.fromScale(0.5, 0.5)
confipanel.AnchorPoint = Vector2.new(0.5, 0.5)
confipanel.Size = UDim2.fromOffset(400, 150)
confipanel.ZIndex = 10
confipanel.GroupTransparency = 1
confipanel.Visible = false
confipanel.Parent = frame
Instance.new("UICorner", confipanel).CornerRadius = UDim.new(0, 12)

local confirmStroke = Instance.new("UIStroke", confipanel)
confirmStroke.Color = Theme.StrokeNormal
confirmStroke.Thickness = 2

local confirmText = CreateText("ConfirmText", "WARNING: This script may not be undetected!\nRunning it may result in a ban.\nDo you still want to select it?", UDim2.fromOffset(10, 10), UDim2.new(1, -20, 0, 70), Theme.TextNormal, 20)
confirmText.Parent = confipanel
confirmText.TextWrapped = true

local function createConfirmBtn(text, color, pos)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = color
	btn.Size = UDim2.fromOffset(100, 35)
	btn.Position = pos
	btn.Text = text
	btn.TextColor3 = Theme.TextNormal
	btn.TextSize = 18
	btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json")
	btn.ZIndex = 10
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.Parent = confipanel
	return btn
end

local confirmYes = createConfirmBtn("Yes", Theme.ToggleOn, UDim2.new(0.5, -110, 1, -45))
local confirmNo = createConfirmBtn("No", Theme.ToggleOff, UDim2.new(0.5, 10, 1, -45))

local function toggleConfirm(state)
	if state then
		blackout.Visible = true
		confipanel.Visible = true
		TweenService:Create(blackout, FastTween, {BackgroundTransparency = 0.4}):Play()
		TweenService:Create(confipanel, FastTween, {GroupTransparency = 0}):Play()
	else
		TweenService:Create(blackout, FastTween, {BackgroundTransparency = 1}):Play()
		local t = TweenService:Create(confipanel, FastTween, {GroupTransparency = 1})
		t:Play()
		t.Completed:Wait()
		blackout.Visible = false
		confipanel.Visible = false
	end
end

--// Construtor Automático dos Painéis Laterais (Toggles)
local function createTogglePanel(name, pos, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.BackgroundColor3 = Theme.Background
	panel.BackgroundTransparency = 0.9
	panel.Position = pos
	panel.Size = size
	panel.Visible = false
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 25)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Theme.StrokeNormal
	stroke.Thickness = 2
	panel.Parent = frame
	return panel
end

local rivalsToggleContainer = createTogglePanel("RivalsContainer", UDim2.fromScale(0.60, 0.53), UDim2.fromOffset(280, 65))
local versionToggleContainer = createTogglePanel("VersionContainer", UDim2.fromScale(0.60, 0.53), UDim2.fromOffset(280, 50))

local function createToggle(parent, labelText, btnText, pos, size, defaultState)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.BackgroundColor3 = Theme.Background
	toggleFrame.BackgroundTransparency = 0.9
	toggleFrame.Position = pos
	toggleFrame.Size = size
	Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 15)
	Instance.new("UIStroke", toggleFrame).Color = Theme.StrokeNormal
	
	local label = CreateText("Label", labelText, UDim2.fromScale(0.05, 0), UDim2.fromOffset(70, size.Y.Offset), Theme.TextNormal, 16)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame
	
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = defaultState and Theme.ToggleOn or Theme.ToggleOff
	btn.Position = UDim2.fromScale(0.6, 0.15)
	btn.Size = UDim2.fromOffset(60, size.Y.Offset * 0.7)
	
	if labelText == "Version:" then 
		btn.Size = UDim2.fromOffset(80, 35) 
		btn.Position = UDim2.fromScale(0.65, 0.15) 
	end
	
	btn.Text = btnText
	btn.TextColor3 = Theme.TextNormal
	btn.TextSize = 14
	btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json")
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
	btn.Parent = toggleFrame
	toggleFrame.Parent = parent
	return btn
end

local autoloadBtn = createToggle(rivalsToggleContainer, "Autoload:", "ON", UDim2.fromScale(0.05, 0.15), UDim2.fromOffset(120, 45), true)
local silentloadBtn = createToggle(rivalsToggleContainer, "Silentload:", "OFF", UDim2.fromScale(0.55, 0.15), UDim2.fromOffset(120, 45), false)
local versionBtn = createToggle(versionToggleContainer, "Version:", "New", UDim2.fromScale(0.05, 0), UDim2.fromOffset(260, 50), true)

--// Geração Dinâmica dos Botões de Seleção de Jogo
-- Muito mais limpo: Adicione jogos aqui sem criar 20 linhas extras de UI para cada um.
local scriptsData = {
	{name = "Arsenal", yPos = 0.0415},
	{name = "Planks", yPos = 0.1778},
	{name = "Counterblox", yPos = 0.3142},
	{name = "Gunfight Arena", yPos = 0.4505},
	{name = "OneTap", yPos = 0.5869},
	{name = "Universal", yPos = 0.7233},
	{name = "Rivals", yPos = 0.8596},
}

local scriptButtons = {}

local function SelectScript(scriptName)
	-- Reseta as bordas
	for _, data in pairs(scriptButtons) do
		TweenService:Create(data.stroke, FastTween, {Color = Theme.StrokeNormal}):Play()
	end
	
	rivalsToggleContainer.Visible = false
	versionToggleContainer.Visible = false

	if scriptName then
		State.SelectedScript = scriptName
		textLabel6.Text = scriptName
		TweenService:Create(scriptButtons[scriptName].stroke, FastTween, {Color = Theme.StrokeSelected}):Play()

		if scriptName == "Rivals" then
			rivalsToggleContainer.Visible = true
		elseif scriptName == "Counterblox" then
			versionToggleContainer.Visible = true
		end
	else
		State.SelectedScript = nil
		textLabel6.Text = "No Script Selected"
	end
end

for _, data in ipairs(scriptsData) do
	local btnFrame = Instance.new("Frame")
	btnFrame.BackgroundColor3 = Theme.Background
	btnFrame.BackgroundTransparency = 0.9
	btnFrame.Position = UDim2.fromScale(0.03, data.yPos)
	btnFrame.Size = UDim2.fromOffset(330, 65)
	
	local stroke = Instance.new("UIStroke", btnFrame)
	stroke.Color = Theme.StrokeNormal
	stroke.Thickness = 1.9
	
	Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 25)
	
	local lbl = CreateText("Label", data.name, UDim2.fromScale(0.05, 0.15), UDim2.fromScale(0.9, 0.7), Theme.TextNormal, 42)
	lbl.TextScaled = true -- Se ajusta independente do tamanho do nome
	lbl.Parent = btnFrame
	
	-- Botão Invisível para Click (Hitbox)
	local clickBtn = Instance.new("TextButton", btnFrame)
	clickBtn.Size = UDim2.fromScale(1, 1)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	
	-- Animação Hover
	clickBtn.MouseEnter:Connect(function()
		if State.SelectedScript ~= data.name then
			TweenService:Create(stroke, FastTween, {Color = Theme.StrokeHover}):Play()
		end
	end)
	clickBtn.MouseLeave:Connect(function()
		if State.SelectedScript ~= data.name then
			TweenService:Create(stroke, FastTween, {Color = Theme.StrokeNormal}):Play()
		end
	end)
	
	clickBtn.MouseButton1Click:Connect(function()
		if data.name == "Rivals" then
			toggleConfirm(true)
		else
			SelectScript(data.name)
		end
	end)
	
	btnFrame.Parent = frame
	scriptButtons[data.name] = {frame = btnFrame, stroke = stroke}
end

-- Funcionalidade do painel de aviso
confirmYes.MouseButton1Click:Connect(function()
	toggleConfirm(false)
	SelectScript("Rivals")
end)

confirmNo.MouseButton1Click:Connect(function()
	toggleConfirm(false)
end)

--// Botão Gigante de LOAD
local loadbtn = Instance.new("TextButton")
loadbtn.Name = "Loadbtn"
loadbtn.BackgroundColor3 = Theme.StrokeNormal
loadbtn.Position = UDim2.fromScale(0.527, 0.656)
loadbtn.Size = UDim2.fromOffset(405, 62)
loadbtn.Text = "LOAD SCRIPT"
loadbtn.TextColor3 = Theme.TextNormal
loadbtn.TextSize = 22
loadbtn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
Instance.new("UICorner", loadbtn).CornerRadius = UDim.new(0, 25)
loadbtn.Parent = frame

loadbtn.MouseEnter:Connect(function()
	TweenService:Create(loadbtn, FastTween, {BackgroundColor3 = Theme.StrokeSelected}):Play()
end)
loadbtn.MouseLeave:Connect(function()
	TweenService:Create(loadbtn, FastTween, {BackgroundColor3 = Theme.StrokeNormal}):Play()
end)

loadbtn.MouseButton1Click:Connect(function()
	local opt = State.SelectedScript
	
	if opt then
		loadbtn.Text = "LOADING..."
		TweenService:Create(loadbtn, FastTween, {BackgroundColor3 = Color3.fromRGB(100, 200, 100)}):Play()
		
		-- Utiliza task.spawn para impedir que UI congele enquanto executa ou espera pelo jogo
		task.spawn(function()
			if opt == "Arsenal" then
				loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Arsenal%20Beta.lua"))()
				
			elseif opt == "Planks" then
				loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Planks.lua"))()
				
			elseif opt == "OneTap" then
				getgenv().SCRIPT_KEY = ""
				loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/2548ffbebdf21063cd4083f93a27ac276d44d1cb6503093d9c3290c3dfd954e3/download"))()
				
			elseif opt == "Rivals" then
				getgenv().autoload = State.Autoload
				getgenv().silentload = State.Silentload
				getgenv().SCRIPT_KEY = ""
				
				-- Espera Carregamento
				repeat task.wait() until game:IsLoaded()
				local lp = Players.LocalPlayer
				repeat task.wait() until lp and lp.Character
				local pg = lp:WaitForChild("PlayerGui")
				repeat task.wait() until not pg:FindFirstChild("LoadingScreen")
				
				loadstring(game:HttpGet("https://api.junkie-development.de/api/v1/luascripts/public/8be52e21a0145a401c446ca7ab2b5df9bd327ea80b0cf1d2fe99e442edd0f9c9/download"))()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Test.lua"))()
				
			elseif opt == "Counterblox" then
				if State.Version == "New" then
					getgenv().SCRIPT_KEY = ""
					loadstring(game:HttpGet("https://api.junkie-development.de/api/v1/luascripts/public/2438cfd42af811d55492e854318eeda24a73aa5d0b11a403ec1f7542abd8f2f0/download"))()
				else
					loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Counterblox.lua"))()
				end
				
			elseif opt == "Gunfight Arena" then
				loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Gunfight%20Arena.lua"))()
				
			elseif opt == "Universal" then
				loadstring(game:HttpGet("https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Universal.lua"))()
			end
			
			task.wait(1)
			loadbtn.Text = "LOAD SCRIPT"
			TweenService:Create(loadbtn, FastTween, {BackgroundColor3 = Theme.StrokeNormal}):Play()
		end)
	else
		loadbtn.Text = "PLEASE SELECT A SCRIPT!"
		TweenService:Create(loadbtn, FastTween, {BackgroundColor3 = Color3.fromRGB(150, 50, 50)}):Play()
		
		task.wait(1.5)
		loadbtn.Text = "LOAD SCRIPT"
		TweenService:Create(loadbtn, FastTween, {BackgroundColor3 = Theme.StrokeNormal}):Play()
	end
end)

--// Lógica dos Toggles
autoloadBtn.MouseButton1Click:Connect(function()
	State.Autoload = not State.Autoload
	TweenService:Create(autoloadBtn, FastTween, {BackgroundColor3 = State.Autoload and Theme.ToggleOn or Theme.ToggleOff}):Play()
	autoloadBtn.Text = State.Autoload and "ON" or "OFF"
end)

silentloadBtn.MouseButton1Click:Connect(function()
	State.Silentload = not State.Silentload
	TweenService:Create(silentloadBtn, FastTween, {BackgroundColor3 = State.Silentload and Theme.ToggleOn or Theme.ToggleOff}):Play()
	silentloadBtn.Text = State.Silentload and "ON" or "OFF"
end)

versionBtn.MouseButton1Click:Connect(function()
	State.Version = State.Version == "New" and "Old" or "New"
	TweenService:Create(versionBtn, FastTween, {BackgroundColor3 = State.Version == "New" and Theme.ToggleOn or Theme.ToggleOff}):Play()
	versionBtn.Text = State.Version
end)
