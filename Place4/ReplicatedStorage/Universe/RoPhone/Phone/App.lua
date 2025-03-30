-- @ScriptType: ModuleScript

local dependencies = script.Parent:WaitForChild("Dependencies")
local Spr = require(dependencies:WaitForChild("Spr"))
local Signal = require(dependencies:WaitForChild("GoodSignal"))

type Theme = "Light" | "Dark"

local App = {}
App.__index = App

function App.new(name: string, frame: CanvasGroup, imageId: number, theme: Theme, aspectRatio: number)
	local self = setmetatable({}, App)

	self.Name = name
	
	self.Frame = frame
	self.Frame.AnchorPoint = Vector2.new(.5,.5)
	
	self.FrameCorner = Instance.new("UICorner", self.Frame)
	self.FrameCorner.CornerRadius = UDim.new(.125,0)
	
	self.FrameRatio = Instance.new("UIAspectRatioConstraint", self.Frame)
	self.FrameRatio.AspectRatio = aspectRatio
	
	self.Button = Instance.new("ImageButton")
	self.Button.AnchorPoint = Vector2.new(.5,.5)
	self.Button.BorderSizePixel = 0
	self.Button.AutoButtonColor = false
	self.Button.BackgroundColor3 = Color3.new(1,1,1)
	self.Button.Image = "rbxassetid://"..imageId
	
	self.ButtonCorner = Instance.new("UICorner", self.Button)
	self.ButtonCorner.CornerRadius = UDim.new(.3,0)
	
	self.ButtonRatio = Instance.new("UIAspectRatioConstraint", self.Button)
	self.ButtonRatio.AspectRatio = 1
	
	self.DefaultPos = UDim2.new()
	self.DefaultSize = UDim2.new()

	self.ButtonClicked = self.Button.MouseButton1Click

	self.Open = false
	self.Opened = Signal.new()
	
	self.Theme = theme
	
	self.DeviceAspectRatio = aspectRatio

	self.ButtonClicked:Connect(function()
		self:OpenApp()
	end)

	return self
end

function App:OpenApp()
	if self.Open then
		return
	end
	
	self.Frame.Size = self.Button.Size
	self.Frame.Position = self.Button.Position
	
	self.FrameCorner.CornerRadius = self.ButtonCorner.CornerRadius
	self.FrameRatio.AspectRatio = 1

	self.Frame.GroupTransparency = 1
	self.Frame.Visible = true
		
	Spr.target(self.Button, 1, 3, {Size = UDim2.new(1,0,1,0), Position = UDim2.new(.5,0,.5,0)})
	Spr.target(self.Frame, 1, 3, {Size = UDim2.new(1,0,1,0), Position = UDim2.new(.5,0,.5,0)})
	Spr.target(self.Frame, 1, 4, {GroupTransparency = 0})
	Spr.target(self.FrameRatio, 1, 2, {AspectRatio = self.DeviceAspectRatio})
	Spr.target(self.FrameCorner, 1, 2, {CornerRadius = UDim.new(.125,0)})

	self.Open = true
	
	Spr.completed(self.FrameCorner, function()
		self.Opened:Fire()
	end)
end

function App:CloseApp()
	if not self.Open then
		return
	end
	
	Spr.target(self.Button, .8, 3, {Size = self.DefaultSize, Position = self.DefaultPos})
	Spr.target(self.Frame, .8, 3, {Size = self.DefaultSize, Position = self.DefaultPos})
	Spr.target(self.Frame, 1, 4, {GroupTransparency = 1})
	Spr.target(self.FrameRatio, 1, 4, {AspectRatio = 1})
	Spr.target(self.FrameCorner, 1, 4, {CornerRadius = self.ButtonCorner.CornerRadius})
	
	Spr.completed(self.Frame, function()
		self.Frame.Visible = false
	end)

	self.Open = false
end

return App
