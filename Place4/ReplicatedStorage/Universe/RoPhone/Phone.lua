-- @ScriptType: ModuleScript

-- TYPES
type PhoneSettings = {
	PhoneColor: Color3,
	CaseThickness: number,
	VolumeColor: Color3,
}

-- VARIABLES
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local CONFIG = require(script.Parent:WaitForChild("CONFIG"))

local App = require(script:WaitForChild("App"))
local Island = require(script:WaitForChild("Island"))
local Gesture = require(script:WaitForChild("Gesture"))
local Volume = require(script:WaitForChild("Volume"))
local Spring = require(script:WaitForChild("Spring"))
local Homescreen = require(script:WaitForChild("Homescreen"))

local defaultApps = script:WaitForChild("DefaultApps")

local OS = {}

local dependencies = script:WaitForChild("Dependencies")
local Spr = require(dependencies:WaitForChild("Spr"))
local Grid = require(dependencies:WaitForChild("Grid"))
local Signal = require(dependencies:WaitForChild("GoodSignal"))

local viewport = Workspace.CurrentCamera.ViewportSize

-- FUNCTIONS
function OS.Initialize(player: Player, phoneSettings: PhoneSettings?, dataRemote: RemoteEvent?)	

	defaultApps.Parent = player.PlayerScripts

	-- Create a settings table
	if phoneSettings == nil then
		phoneSettings = {
			PhoneColor = CONFIG.PHONE_COLOR,
			PowerColor = CONFIG.POWER_COLOR,
			VolumeColor = CONFIG.VOLUME_COLOR
		}
	end

	OS.Player = player
	OS.DataRemote = dataRemote or nil

	-- Create phone GUI
	OS.Gui = Instance.new("ScreenGui", player.PlayerGui)
	OS.Gui.Name = "PhoneGui"
	OS.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Manage added sound instances
	OS.Gui.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Sound") then
			descendant.Volume = OS.Volume.Level
			table.insert(OS.Volume.Instances, descendant)
		end
	end)

	-- Set up phone frame (case)
	OS.Frame = Instance.new("Frame", OS.Gui)
	OS.Frame.Name = "PhoneFrame"

	OS.Frame.Size = CONFIG.SIZE
	OS.Frame.Position = CONFIG.POSITION
	OS.Frame.AnchorPoint = CONFIG.ANCHOR_POINT
	OS.Frame.BackgroundColor3 = phoneSettings.PhoneColor

	local frameCorner = Instance.new("UICorner", OS.Frame)
	frameCorner.CornerRadius = CONFIG.CORNER_RADIUS

	local frameAspectRatio = Instance.new("UIAspectRatioConstraint", OS.Frame)
	frameAspectRatio.AspectRatio = CONFIG.ASPECT_RATIO

	OS.Case = Instance.new("UIStroke", OS.Frame)
	OS.Case.Thickness = CONFIG.THICKNESS
	OS.Case.Color = phoneSettings.PhoneColor
	
	-- Set up volume and power buttons
	OS.Volume = Volume.new(CONFIG.DEFAULT_VOLUME)
	OS.Volume.ButtonUp.Parent = OS.Frame
	OS.Volume.ButtonDown.Parent = OS.Frame
		
	local posX = (CONFIG.THICKNESS/OS.Gui.AbsoluteSize.X) / OS.Frame.Size.X.Scale
	
	OS.Volume.ButtonUp.AnchorPoint = Vector2.new(.5,.5)
	OS.Volume.ButtonUp.Position = UDim2.new(1+posX,0,.25,0)
	OS.Volume.ButtonUp.Size = UDim2.new(posX,0,0.1,0)
	OS.Volume.ButtonUp.BackgroundColor3 = phoneSettings.VolumeColor
	OS.Volume.ButtonUp.Text = ""
	
	local cornerUp = Instance.new("UICorner", OS.Volume.ButtonUp)
	cornerUp.CornerRadius = UDim.new(1,0)

	OS.Volume.ButtonDown.AnchorPoint = Vector2.new(.5,.5)
	OS.Volume.ButtonDown.Position = UDim2.new(1+posX,0,.365,0)
	OS.Volume.ButtonDown.Size = UDim2.new(posX,0,.1,0)
	OS.Volume.ButtonDown.BackgroundColor3 = phoneSettings.VolumeColor
	OS.Volume.ButtonDown.Text = ""
	
	local cornerDown = Instance.new("UICorner", OS.Volume.ButtonDown)
	cornerDown.CornerRadius = UDim.new(1,0)

	OS.PowerButton = Instance.new("TextButton", OS.Frame)
	OS.PowerButton.Name = "PowerButton"
	OS.PowerButton.AnchorPoint = Vector2.new(.5,.5)
	OS.PowerButton.Position = UDim2.new(0-posX,0,.25,0)
	OS.PowerButton.Size = UDim2.new(posX,0,.1,0)
	OS.PowerButton.BackgroundColor3 = phoneSettings.PowerColor
	OS.PowerButton.Text = ""
	
	local cornerPower = Instance.new("UICorner", OS.PowerButton)
	cornerPower.CornerRadius = UDim.new(1,0)

	-- Set up phone screen
	OS.Screen = Instance.new("CanvasGroup", OS.Frame)
	OS.Screen.Name = "Screen"
	OS.Screen.AnchorPoint = Vector2.new(.5,.5)
	OS.Screen.Position = UDim2.new(.5,0,.5,0)
	OS.Screen.Size = UDim2.new(1,0,1,0)
	OS.Screen.BackgroundColor3 = Color3.new(1,1,1)

	local screenCorner = Instance.new("UICorner", OS.Screen)
	screenCorner.CornerRadius = CONFIG.CORNER_RADIUS

	-- Create the lockscreen
	OS.Lockscreen = Lockscreen.new()
	OS.Lockscreen.Frame.Parent = OS.Screen
	
	-- Create a homescreen page
	OS.Homescreen = Homescreen.new()
	OS.Homescreen.Frame.Parent = OS.Screen
	
	OS.Homescreen:AddPage()

	OS.CurrentPage = 1

	-- Set up island (pill at top of screen)
	OS.Island = Island.new()
	OS.Island.Frame.Parent = OS.Screen
	
	OS.Island.SoundChanged:Connect(function(sound: Sound)
		sound.Parent = OS.Gui
	end)

	OS.IslandInset = CONFIG.ISLAND_MARGIN + CONFIG.ISLAND_SIZE.Y

	-- Set up gesture bar (home button at bottom of screen)
	OS.Gesture = Gesture.new()
	OS.Gesture.Button.Parent = OS.Screen

	OS.GestureInset = CONFIG.GESTURE_MARGIN + CONFIG.GESTURE_SIZE.Y

	OS.Gesture.ButtonClicked:Connect(function()
		for i, v in OS.Apps do
			task.spawn(function()
				v:CloseApp()
				
				OS.Homescreen.Frame.Visible = true
				
				local newSpring = Spring.new(OS.Gesture.Button, 1, 5*OS.AnimationSpeed, {BackgroundTransparency = 1})
				newSpring:Play()
				
				newSpring.Completed:Wait()
				
				OS.Gesture.Button.Visible = false
			end)
		end
	end)

	-- Create table for all registered apps
	OS.Apps = {}
	
	-- Device variables
	OS.NotificationSound = CONFIG.NOTIFICATION_ID
	OS.AnimationSpeed = CONFIG.ANIMATION_SPEED
	
	OS.DeviceAspectRatio = phoneSettings.AspectRatio
	OS.MainGestureColor = Color3.new(1,1,1)

	OS.DeviceOn = false
	OS.Locked = true
	OS.Password = ""
	
	OS.Spring = Spring
	OS.GoodSignal = Signal

	-- Power functions
	OS.PowerButton.MouseButton1Click:Connect(function()
		
	end)
end

function OS.RegisterApp(name: string, frame: CanvasGroup, imageId: number, theme: "Light" | "Dark"): typeof(App.new())
	local app = App.new(name, frame, imageId, theme, CONFIG.ASPECT_RATIO)

	for i = 1, CONFIG.APP_TIMEOUT do
		if OS.Apps ~= nil then
			break
		end
		
		if i == CONFIG.APP_TIMEOUT then
			warn("App could not be registered because the 'OS.Apps' table could not be found.")
			return
		end
		
		task.wait(1)
	end

	table.insert(OS.Apps, app)
	
	OS.Homescreen:AddAppButton(app.Button)

	app.DefaultSize = app.Button.Size
	app.DefaultPos = app.Button.Position

	frame.Parent = OS.Screen
	frame.Visible = false

	app.ButtonClicked:Connect(function()
		OS.Gesture.Button.Parent = app.Frame
		OS.Gesture.Button.BackgroundTransparency = 1
		OS.Gesture.Button.Visible = true
		
		if app.Theme == "Dark" then
			local newSpring = Spring.new(OS.Gesture.Button, 1, 3*OS.AnimationSpeed, {BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0})
			newSpring:Play()
		else
			local newSpring = Spring.new(OS.Gesture.Button, 1, 3*OS.AnimationSpeed, {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0})
			newSpring:Play()
		end
	end)
	
	OS.Homescreen.AppButtonDocked:Connect(function(appButton: GuiButton)
		if appButton == app.Button then
			app.DefaultSize = appButton.Size
			app.DefaultPos = appButton.Position
			
			appButton.Parent = OS.Homescreen.Frame
		end
	end)
	
	app.Opened:Connect(function()
		OS.Homescreen.Frame.Visible = false
	end)

	return app
end

function OS.GetApp(searchParameter: string | CanvasGroup | GuiButton): typeof(App.new())
	local searchType = typeof(searchParameter)
	
	local function GetApp()
		for i, v in OS.Apps do
			if searchType == "string" then
				if v.Name == searchParameter then
					return v
				end
			elseif searchType == "CanvasGroup" then
				if v.Frame == searchParameter then
					return v
				end
			elseif searchType == "GuiButton" then
				if v.Button == searchParameter then
					return v
				end
			end
		end
	end
	
	local app = nil
	local timer = 0
	
	repeat app = GetApp() task.wait(1) timer = 1 until app ~= nil or timer == CONFIG.APP_TIMEOUT
	
	if app == nil then
		warn("App could not be found:", searchParameter)
	end
	
	return app
end

return OS
