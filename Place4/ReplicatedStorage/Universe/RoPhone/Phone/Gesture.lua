-- @ScriptType: ModuleScript

local CONFIG = require(script.Parent.Parent:WaitForChild("CONFIG"))

local Gesture = {}
Gesture.__index = Gesture

function Gesture.new()
	local self = setmetatable({}, Gesture)
	
	self.Button = Instance.new("TextButton")
	self.Button.Name = "GestureBar"
	self.Button.AnchorPoint = Vector2.new(.5,1)
	self.Button.Position = UDim2.new(.5,0,1 - CONFIG.GESTURE_MARGIN,0)
	self.Button.Size = UDim2.new(CONFIG.GESTURE_SIZE.X,0,CONFIG.GESTURE_SIZE.Y,0)
	self.Button.ZIndex = 200
	self.Button.BackgroundColor3 = Color3.new(1,1,1)
	self.Button.Text = ""
	self.Button.AutoButtonColor = false
	self.Button.Visible = false
	
	self.Corner = Instance.new("UICorner", self.Button)
	self.Corner.CornerRadius = UDim.new(1,0)
	
	self.ButtonClicked = self.Button.MouseButton1Click
	
	return self
end

return Gesture
