-- @ScriptType: ModuleScript

local CONFIG = require(script.Parent.Parent.Parent:WaitForChild("CONFIG"))

local dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Grid = require(dependencies:WaitForChild("Grid"))

local Page = {}
Page.__index = Page

function Page.new()
	local self = setmetatable({}, Page)
		
	self.Frame = Instance.new("Frame")
	self.Frame.Position = UDim2.new(.5,0,.5,0)
	self.Frame.Size = UDim2.new(1,0,1,0)
	self.Frame.AnchorPoint = Vector2.new(.5,.5)
	self.Frame.Transparency = 1

	self.GridFrame = Instance.new("Frame", self.Frame)
	self.GridFrame.Position = UDim2.new(.5,0, (CONFIG.ISLAND_SIZE.Y + CONFIG.ISLAND_MARGIN*2), 0)
	self.GridFrame.Size = UDim2.new(.9,0, 1 - (CONFIG.ISLAND_SIZE.Y + CONFIG.ISLAND_MARGIN*2 + CONFIG.DOCK_SIZE.Y + CONFIG.DOCK_MARGIN + CONFIG.INFO_BAR_SIZE.Y + CONFIG.INFO_BAR_MARGIN*2), 0)
	self.GridFrame.AnchorPoint = Vector2.new(0.5,0)
	self.GridFrame.Transparency = 1
	
	self.Grid = Grid.new(self.Frame, CONFIG.APP_GRID_SIZE, CONFIG.APP_GRID_SPACING, self.GridFrame)

	self.AppButtons = {}

	return self
end

function Page:AddAppButton(appButton: GuiButton)
	local originalSize = appButton.Size
	local originalPos = appButton.Position
	
	appButton.Size = UDim2.new(1/CONFIG.APP_GRID_SIZE.X, 0, 1/CONFIG.APP_GRID_SIZE.Y, 0)
	
	local added = self.Grid:AddObject(appButton)
	
	if added then
		appButton.Parent = self.Frame
		return true
	end
	
	appButton.Size = originalSize
	appButton.Position = originalPos
	
	return false
end

function Page:RemoveAppButton(appButton: GuiButton)
	self.Grid:RemoveObject(appButton)
end

return Page
