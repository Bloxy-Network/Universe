-- @ScriptType: ModuleScript

local CONFIG = require(script.Parent.Parent.Parent:WaitForChild("CONFIG"))

local dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Signal = require(dependencies:WaitForChild("GoodSignal"))

local Spring = require(script.Parent.Parent:WaitForChild("Spring"))

local InfoBar = {}
InfoBar.__index = InfoBar

function InfoBar.new()
	local self = setmetatable({}, InfoBar)
	
	self.Button = Instance.new("TextButton")
	self.Button.Size = UDim2.new(CONFIG.INFO_BAR_SIZE.X, 0, CONFIG.INFO_BAR_SIZE.Y, 0)
	self.Button.Position = UDim2.new(.5,0, 1 - (CONFIG.DOCK_MARGIN + CONFIG.DOCK_SIZE.Y + CONFIG.INFO_BAR_MARGIN + CONFIG.INFO_BAR_SIZE.Y/2),0)
	self.Button.AnchorPoint = Vector2.new(.5,.5)
	self.Button.BackgroundTransparency = .3
	self.Button.BackgroundColor3 = CONFIG.DOCK_COLOR
	self.Button.AutoButtonColor = false
	self.Button.Text = ""
	
	self.Corner = Instance.new("UICorner", self.Button)
	self.Corner.CornerRadius = UDim.new(1,0)
	
	self.PageDots = Instance.new("CanvasGroup", self.Button)
	self.PageDots.Size = UDim2.new(1,0,1,0)
	self.PageDots.Position = UDim2.new(.5,0,.5,0)
	self.PageDots.AnchorPoint = Vector2.new(.5,.5)
	self.PageDots.BackgroundTransparency = 1
	
	self.Dots = {}
	
	self.DotAdded = Signal.new()
		
	return self
end

function InfoBar:AddPageDot()
	local newDot = Instance.new("TextButton", self.PageDots)
	newDot.Size = UDim2.new(.2,0,.5,0)
	newDot.AnchorPoint = Vector2.new(.5,.5)
	newDot.Position = UDim2.new(1.5,0,.5,0)
	newDot.BackgroundColor3 = Color3.new(1,1,1)
	newDot.Text = ""
	newDot.AutoButtonColor = false
	newDot.BackgroundTransparency = .5

	local corner = Instance.new("UICorner", newDot)
	corner.CornerRadius = UDim.new(1,0)

	local ratio = Instance.new("UIAspectRatioConstraint", newDot)
	ratio.AspectRatio = 1

	table.insert(self.Dots, newDot)

	for i, v in ipairs(self.Dots) do
		local posSpring = Spring.new(v, 1.2, 3, {Position = UDim2.new(i/(#self.Dots+1), 0,.5,0)})
		posSpring:Play()

		local barSpring = Spring.new(self.Button, 1.2, 3, {Size = UDim2.new(CONFIG.INFO_BAR_SIZE.X + (CONFIG.DOT_SPACING * (i - 1)), 0, CONFIG.INFO_BAR_SIZE.Y, 0)})
		barSpring:Play()
	end
	
	self.DotAdded:Fire(newDot, #self.Dots)
end

return InfoBar
