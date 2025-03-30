-- @ScriptType: ModuleScript

local CONFIG = require(script.Parent.Parent.Parent:WaitForChild("CONFIG"))

local dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Grid = require(dependencies:WaitForChild("Grid"))

local Dock = {}
Dock.__index = Dock

function Dock.new()
	local self = setmetatable({}, Dock)

	local verticalPadding = .1
		
	self.Frame = Instance.new("Frame")
	self.Frame.Position = UDim2.new(.5,0,1 - (CONFIG.DOCK_MARGIN + CONFIG.DOCK_SIZE.Y/2),0)
	self.Frame.Size = UDim2.new(CONFIG.DOCK_SIZE.X,0,CONFIG.DOCK_SIZE.Y,0)
	self.Frame.AnchorPoint = Vector2.new(.5,.5)
	self.Frame.Transparency = .3
	self.Frame.BackgroundColor3 = CONFIG.DOCK_COLOR
	
	self.ButtonsFrame = Instance.new("Frame")
	self.ButtonsFrame.Position = UDim2.new(.5,0,.5,0)
	self.ButtonsFrame.Size = UDim2.new(1,0,1,0)
	self.ButtonsFrame.AnchorPoint = Vector2.new(.5,.5)
	self.ButtonsFrame.BackgroundTransparency = 1
	
	self.Corner = Instance.new("UICorner", self.Frame)
	self.Corner.CornerRadius = CONFIG.DOCK_CORNER_RADIUS
	
	self.Grid = Grid.new(self.ButtonsFrame, Vector2.new(CONFIG.DOCK_APPS, 1), Vector2.new(CONFIG.APP_GRID_SPACING.X, 0), self.Frame, CONFIG.DOCK_PADDING.X, CONFIG.DOCK_PADDING.Y)

	self.Apps = {}

	return self
end

function Dock:AddAppButton(appButton: GuiButton)
	appButton.Size = UDim2.new(1/CONFIG.DOCK_APPS, 0, 1, 0)

	local added = self.Grid:AddObject(appButton)

	if added then
		return true
	end

	return false
end

function Dock:RemoveAppButton(appButton: GuiButton)
	self.Grid:RemoveObject(appButton)
end

return Dock
