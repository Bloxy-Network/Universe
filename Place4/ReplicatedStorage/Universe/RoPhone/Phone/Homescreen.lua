-- @ScriptType: ModuleScript

local RunService = game:GetService("RunService")

local CONFIG = require(script.Parent.Parent:WaitForChild("CONFIG"))
local Spring = require(script.Parent:WaitForChild("Spring"))

local dependencies = script.Parent:WaitForChild("Dependencies")
local Grid = require(dependencies:WaitForChild("Grid"))
local Signal = require(dependencies:WaitForChild("GoodSignal"))

local Page = require(script:WaitForChild("Page"))
local Dock = require(script:WaitForChild("Dock"))
local InfoBar = require(script:WaitForChild("InfoBar"))
local Swipe = require(script:WaitForChild("Swipe"))

local Homescreen = {}
Homescreen.__index = Homescreen

function Homescreen.new()
	local self = setmetatable({}, Homescreen)

	self.Frame = Instance.new("CanvasGroup")
	self.Frame.Name = "Homescreen"
	self.Frame.AnchorPoint = Vector2.new(.5,.5)
	self.Frame.Position = UDim2.new(.5,0,.5,0)
	self.Frame.Size = UDim2.new(1,0,1,0)
	self.Frame.BackgroundTransparency = 1
	
	self.Background = Instance.new("ImageLabel", self.Frame)
	self.Background.Name = "Background"
	self.Background.AnchorPoint = Vector2.new(.5,.5)
	self.Background.Position = UDim2.new(.5,0,.5,0)
	self.Background.Size = UDim2.new(2,0,1,0)
	self.Background.ScaleType = Enum.ScaleType.Crop
	self.Background.Image = "rbxassetid://"..CONFIG.WALLPAPER_ID
	
	self.Dock = Dock.new()
	self.Dock.Frame.Parent = self.Frame
	self.Dock.ButtonsFrame.Parent = self.Frame
	
	self.InfoBar = InfoBar.new()
	self.InfoBar.Button.Parent = self.Frame
	self.InfoBar.Button.Visible = false
	self.InfoBar.PageDots.GroupTransparency = 1
	self.InfoBar.Button.BackgroundTransparency = 1

	self.CurrentPage = 1
	self.Pages = {} :: {[number]: typeof(Page.new())}
	self.PageAdded = Signal.new()
	
	self.Swipe = Swipe.new(self.Frame)
	
	self.CurrentPageUpdated = Signal.new()
	
	self.Swipe.SwipeChanged:Connect(function(startPos: number, delta: number)
		if #self.Pages > 1 then
			local newPos = .5 + delta
			
			if self.CurrentPage == 1 then
				newPos = math.clamp(newPos, -.5, .5)
			end
			
			if self.CurrentPage == #self.Pages then
				newPos = math.clamp(newPos, .5, 1.5)
			end
			
			local newSpring = Spring.new(self.Pages[self.CurrentPage].Frame, 1.5, 8, {Position = UDim2.new(newPos, 0,.5,0)})
			newSpring:Play()
			
			for i, page in self.Pages do
				if i ~= self.CurrentPage then
					local delta = i - self.CurrentPage
					page.Frame.Position = UDim2.new(self.Pages[self.CurrentPage].Frame.Position.X.Scale + delta, 0,.5,0)
				end
			end
		end
	end)
	
	self.Swipe.Swiped:Connect(function(accel: number)
		if #self.Pages <= 1 then
			return
		end
				
		local page = self.Pages[self.CurrentPage]
				
		if accel >= 10 then
			if page.Frame.Position.X.Scale > .5 then
				self.CurrentPageUpdated:Fire(self.CurrentPage - 1)
			elseif page.Frame.Position.X.Scale < .5 then
				self.CurrentPageUpdated:Fire(self.CurrentPage + 1)
			end
		elseif page.Frame.Position.X.Scale >= .9 then
			self.CurrentPageUpdated:Fire(self.CurrentPage - 1)
		elseif page.Frame.Position.X.Scale <= .1 then
			self.CurrentPageUpdated:Fire(self.CurrentPage + 1)
		else
			local newSpring = Spring.new(page.Frame, 1.5, 5, {Position = UDim2.new(.5,0,.5,0)})
			newSpring:Play()
		end
	end)
	
	self.CurrentPageUpdated:Connect(function(currentPage: number)
		self.CurrentPage = currentPage
				
		local newSpring = Spring.new(self.Pages[self.CurrentPage].Frame, 1.5, 5, {Position = UDim2.new(.5,0,.5,0)})
		newSpring:Play()
		
		self.Pages[self.CurrentPage].Frame.Changed:Connect(function(property)
			if property ~= "Position" then
				return
			end
			
			for i, page in self.Pages do
				if i ~= self.CurrentPage then
					local delta = i - self.CurrentPage
					page.Frame.Position = UDim2.new(self.Pages[self.CurrentPage].Frame.Position.X.Scale + delta,0,.5,0)
				end
			end
		end)
		
		for i, dot in self.InfoBar.Dots do
			if i == self.CurrentPage then
				Spring.new(dot, 1.2, 3, {BackgroundTransparency = 0}):Play()
			else
				Spring.new(dot, 1.2, 3, {BackgroundTransparency = .5}):Play()
			end
		end
	end)
	
	self.InfoBar.DotAdded:Connect(function(newDot: TextButton, index: number)
		newDot.MouseButton1Click:Connect(function()
			self.CurrentPageUpdated:Fire(index)
		end)
		
		if index == self.CurrentPage then
			Spring.new(newDot, 1.2, 3, {BackgroundTransparency = 0}):Play()
		end
	end)
	
	self.AppButtonAdded = Signal.new()
	self.AppButtonDocked = Signal.new()

	return self
end

function Homescreen:AddPage()
	local page = Page.new()
	page.Frame.Parent = self.Frame
	page.Frame.Position = UDim2.new(.5+#self.Pages,0,.5,0)
	
	local index = #self.Pages + 1
	
	self.Pages[index] = page
	
	if #self.Pages > 1 then
		self.InfoBar.Button.Visible = true
		
		Spring.new(self.InfoBar.Button, 1.5, 3, {BackgroundTransparency = 0}):Play()
		Spring.new(self.InfoBar.PageDots, 1.5, 3, {GroupTransparency = 0}):Play()
	end
	
	self.InfoBar:AddPageDot()
	
	self.PageAdded:Fire(self.Pages[index])
end

function Homescreen:AddAppButton(appButton: GuiButton)
	local page = self.Pages[#self.Pages]
	
	local added = page:AddAppButton(appButton)
	
	if not added then
		self:AddPage()
		self:AddAppButton(appButton)
		return
	end
	
	self.AppButtonAdded:Fire(appButton)
	
	appButton.MouseButton2Click:Once(function()
		local originalSize = appButton.Size
		local originalPos = appButton.Position
		
		local added = self.Dock:AddAppButton(appButton)
		
		if added then
			page:RemoveAppButton(appButton)

			self.AppButtonDocked:Fire(appButton)
			return true
		end
		
		appButton.Size = originalSize
		appButton.Position = originalPos
		
		return false
	end)
end

return Homescreen
