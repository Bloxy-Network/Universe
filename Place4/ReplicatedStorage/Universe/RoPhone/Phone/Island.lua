-- @ScriptType: ModuleScript

local RunService = game:GetService("RunService")

local dependencies = script.Parent:WaitForChild("Dependencies")
local Spr = require(dependencies:WaitForChild("Spr"))
local Signal = require(dependencies:WaitForChild("GoodSignal"))

local CONFIG = require(script.Parent.Parent:WaitForChild("CONFIG"))

local Island = {}
Island.__index = Island

function Island.new()
	local self = setmetatable({}, Island)
	
	-- Set up Island Bar frame
	self.Frame = Instance.new("CanvasGroup")
	self.Frame.Name = "Island"
	self.Frame.AnchorPoint = Vector2.new(.5,0)
	self.Frame.Position = UDim2.new(.5,0,CONFIG.ISLAND_MARGIN,0)
	self.Frame.Size = UDim2.new(CONFIG.ISLAND_SIZE.X,0,CONFIG.ISLAND_SIZE.Y,0)
	self.Frame.ZIndex = 200
	self.Frame.BackgroundColor3 = Color3.new(0,0,0)
	
	self.IslandCorner = Instance.new("UICorner", self.Frame)
	self.IslandCorner.CornerRadius = UDim.new(1,0)
	
	-- Notifications
	self.Container = Instance.new("CanvasGroup", self.Frame)
	self.Container.Name = "Notification"
	self.Container.AnchorPoint = Vector2.new(.5,.5)
	self.Container.Position = UDim2.new(.5,0,.5,0)
	self.Container.Size = UDim2.new(1,0,1,0)
	self.Container.GroupTransparency = 1
	self.Container.BackgroundTransparency = 1
	self.Container.Visible = false
	
	self.Title = Instance.new("TextLabel", self.Container)
	self.Title.Name = "Title"
	self.Title.AnchorPoint = Vector2.new(0,.5)
	self.Title.BackgroundTransparency = 1
	self.Title.TextColor3 = Color3.new(1,1,1)
	self.Title.TextScaled = false
	self.Title.TextXAlignment = Enum.TextXAlignment.Left
	self.Title.TextSize = 14
	self.Title.Font = Enum.Font.BuilderSansBold
	
	self.Description = Instance.new("TextLabel", self.Container)
	self.Description.Name = "Description"
	self.Description.AnchorPoint = Vector2.new(0,.5)
	self.Description.BackgroundTransparency = 1
	self.Description.TextColor3 = Color3.new(.9,.9,.9)
	self.Description.TextScaled = false
	self.Description.TextXAlignment = Enum.TextXAlignment.Left
	self.Description.TextSize = 10
	self.Description.Font = Enum.Font.BuilderSans
	
	self.Icon = Instance.new("ImageLabel", self.Container)
	self.Icon.Name = "Icon"
	self.Icon.AnchorPoint = Vector2.new(.5,.5)
	self.Icon.BackgroundColor3 = Color3.new(1,1,1)
	self.Icon.ScaleType = Enum.ScaleType.Fit
	
	self.IconRatio = Instance.new("UIAspectRatioConstraint", self.Icon)
	self.IconRatio.AspectRatio = 1
	
	self.IconCorner = Instance.new("UICorner", self.Icon)
	self.IconCorner.CornerRadius = UDim.new(.2,0)
	
	-- Media
	self.MediaContainer = Instance.new("CanvasGroup", self.Frame)
	self.MediaContainer.Name = "Media"
	self.MediaContainer.AnchorPoint = Vector2.new(.5,.5)
	self.MediaContainer.Position = UDim2.new(.5,0,.5,0)
	self.MediaContainer.Size = UDim2.new(1,0,1,0)
	self.MediaContainer.GroupTransparency = 1
	self.MediaContainer.BackgroundTransparency = 1
	self.MediaContainer.Visible = false
	self.MediaContainer.ZIndex = 2
	
	self.MediaBackground = Instance.new("Frame", self.MediaContainer)
	self.MediaBackground.Name = "Background"
	self.MediaBackground.AnchorPoint = Vector2.new(.5,.5)
	self.MediaBackground.Position = UDim2.new(.5,0,.5,0)
	self.MediaBackground.Size = UDim2.new(1,0,1,0)
	self.MediaBackground.BackgroundTransparency = 1
	self.MediaBackground.ZIndex = 1
	
	self.MediaTitle = Instance.new("TextLabel", self.MediaContainer)
	self.MediaTitle.Name = "Title"
	self.MediaTitle.AnchorPoint = Vector2.new(0,.5)
	self.MediaTitle.BackgroundTransparency = 1
	self.MediaTitle.TextColor3 = Color3.new(1,1,1)
	self.MediaTitle.TextScaled = false
	self.MediaTitle.TextXAlignment = Enum.TextXAlignment.Left
	self.MediaTitle.TextSize = 14
	self.MediaTitle.Font = Enum.Font.BuilderSansBold
	self.MediaTitle.ZIndex = 2
	
	self.MediaAuthor = Instance.new("TextLabel", self.MediaContainer)
	self.MediaAuthor.Name = "Description"
	self.MediaAuthor.AnchorPoint = Vector2.new(0,.5)
	self.MediaAuthor.BackgroundTransparency = 1
	self.MediaAuthor.TextColor3 = Color3.new(.9,.9,.9)
	self.MediaAuthor.TextScaled = false
	self.MediaAuthor.TextXAlignment = Enum.TextXAlignment.Left
	self.MediaAuthor.TextSize = 10
	self.MediaAuthor.Font = Enum.Font.BuilderSans
	self.MediaAuthor.ZIndex = 2
	
	self.MediaIcon = Instance.new("ImageLabel", self.MediaContainer)
	self.MediaIcon.Name = "Icon"
	self.MediaIcon.AnchorPoint = Vector2.new(.5,.5)
	self.MediaIcon.BackgroundColor3 = Color3.new(1,1,1)
	self.MediaIcon.ScaleType = Enum.ScaleType.Fit
	self.MediaIcon.ZIndex = 2

	self.MediaIconRatio = Instance.new("UIAspectRatioConstraint", self.MediaIcon)
	self.MediaIconRatio.AspectRatio = 1

	self.MediaIconCorner = Instance.new("UICorner", self.MediaIcon)
	self.MediaIconCorner.CornerRadius = UDim.new(.2,0)
	
	self.PlayIcon = Instance.new("ImageButton", self.MediaContainer)
	self.PlayIcon.Name = "PlayIcon"
	self.PlayIcon.ScaleType = Enum.ScaleType.Fit
	self.PlayIcon.BackgroundTransparency = 1
	self.PlayIcon.ZIndex = 2
	
	self.ProgressContainer = Instance.new("CanvasGroup", self.MediaContainer)
	self.ProgressContainer.Name = "ProgressContainer"
	self.ProgressContainer.AnchorPoint = Vector2.new(.5,.5)
	self.ProgressContainer.Position = UDim2.new(.5,0,.65,0)
	self.ProgressContainer.Size = UDim2.new(.8,0,.05,0)
	self.ProgressContainer.BackgroundTransparency = 1
	self.ProgressContainer.ZIndex = 2
	
	self.ProgressContainerCorner = Instance.new("UICorner", self.ProgressContainer)
	self.ProgressContainerCorner.CornerRadius = UDim.new(1,0)
	
	self.ProgressFrame = Instance.new("Frame", self.ProgressContainer)
	self.ProgressFrame.Name = "ProgressBar"
	self.ProgressFrame.AnchorPoint = Vector2.new(0,.5)
	self.ProgressFrame.Position = UDim2.new(0,0,.5,0)
	self.ProgressFrame.Size = UDim2.new(0,0,1,0)
	self.ProgressFrame.BackgroundColor3 = Color3.new(1,1,1)
	
	self.ProgressFrameCorner = Instance.new("UICorner", self.ProgressFrame)
	self.ProgressFrameCorner.CornerRadius = UDim.new(1,0)
	
	-- Click button
	self.Click = Instance.new("TextButton", self.Frame)
	self.Click.Name = "Click"
	self.Click.Transparency = 1
	self.Click.AnchorPoint = Vector2.new(.5,.5)
	self.Click.Position = UDim2.new(.5,0,.5,0)
	self.Click.Size = UDim2.new(1,0,1,0)
	self.Click.Visible = false
	
	-- Defaults
	self.Complete = true
	self.MediaPlaying = false
	self.IslandBig = false
	
	self.Sound = nil :: Sound
	self.SoundChanged = Signal.new()
	
	return self
end


-- Main Methods

function Island:Notify(app, title: string, description: string, imageId: number, islandSize: "Small" | "Large" | "Square", durationOverride: number?)
	if self.Completed == false then
		repeat task.wait() until self.Completed
	end
	
	self.Completed = false
	
	self.Icon.Image = "rbxassetid://"..imageId
	self.Title.Text = title
	self.Description.Text = description
	
	self.Click.Visible = true

	self.Click.MouseButton1Click:Connect(function()
		if not self.Completed then
			app:OpenApp()
		end
	end)
	
	self.Container.GroupTransparency = 1
	self.Container.Visible = true
	
	self.Icon.Visible = true
	self.Title.Visible = true
	self.Description.Visible = true
	
	if islandSize == "Large" then
		self.Icon.Size = UDim2.new(.2,0,.8,0)
		self.Icon.Position = UDim2.new(self.Icon.Size.X.Scale/2 + .05,0,.5,0)
		
		self.Title.Size = UDim2.new(.7,0,.4,0)
		self.Title.Position = UDim2.new(self.Icon.Position.X.Scale + (self.Icon.Size.X.Scale/2) + .05,0,.25,0)
		self.Title.TextYAlignment = Enum.TextYAlignment.Bottom
		
		self.Description.Size = UDim2.new(.7,0,.4,0)
		self.Description.Position = UDim2.new(self.Icon.Position.X.Scale + (self.Icon.Size.X.Scale/2) + .05,0,.75,0)
		self.Description.TextYAlignment = Enum.TextYAlignment.Top
		
		self:Large(.75)
		self:ShowContainer(true)
	elseif islandSize == "Small" then
		self.Icon.Size = UDim2.new(.2,0,.8,0)
		self.Icon.Position = UDim2.new(self.Icon.Size.X.Scale/2 + .05,0,.5,0)

		self.Title.Position = UDim2.new(self.Icon.Position.X.Scale + self.Icon.Size.X.Scale/2 + .05,0,.5,0)
		self.Title.Size = UDim2.new(.7,0,.8,0)
		self.Title.TextYAlignment = Enum.TextYAlignment.Center

		self.Description.Visible = false
		
		self:Small(.75)
		self:ShowContainer(true)
	elseif islandSize == "Square" then
		self.Icon.Position = UDim2.new(.5,0,.5,0)
		self.Icon.Size = UDim2.new(.8,0,.8,.0)

		self.Title.Visible = false
		self.Description.Visible = false
		
		self:Square(.75)
		self:ShowContainer(true)
	end
	
	local started = false
	
	Spr.completed(self.Frame, function()
		started = true
		self.MediaContainer.Visible = false
	end)
	
	repeat task.wait() until started
	
	task.wait(durationOverride or CONFIG.NOTIFICATION_DURATION)
		
	-- Back to normal
	self:ResetBar()

	Spr.completed(self.Frame, function()
		self.Completed = true
		self.Container.Visible = false
	end)

	repeat task.wait() until self.Completed
end

function Island:AddMedia(title: string, author: string, iconId: number, soundId: number, themeColor: Color3?)
	if self.MediaPlaying then
		self.Sound:Stop()
		self.Sound:Destroy()
		
		RunService:UnbindFromRenderStep("IslandMedia")
	end
	
	self.Sound = Instance.new("Sound")
	self.Sound.SoundId = "rbxassetid://"..soundId
	self.SoundChanged:Fire(self.Sound)
	
	self.Sound:Play()
	
	self.MediaPlaying = true
	self.Click.Visible = false
	
	local playConnection = self.PlayIcon.MouseButton1Click:Connect(function()
		if self.Sound.Playing then
			self.Sound:Pause()
		else
			self.Sound:Resume()
		end
	end)
	
	local clickConnection = self.Click.MouseButton1Click:Connect(function()
		if self.IslandBig then
			self:SmallMedia()
			self.IslandBig = false
		else
			self:LargeMedia()
			self.IslandBig = true
		end
	end)
	
	local timer = CONFIG.MEDIA_TIMEOUT
	local lastTime = 0
	local lastSaved = 0

	RunService:BindToRenderStep("IslandMedia", Enum.RenderPriority.Last.Value, function(dt)
		local currentTime = self.Sound.TimePosition
		local totalTime = self.Sound.TimeLength
		
		if timer <= 0 then
			self.Sound:Stop()
			self.Sound:Destroy()
			
			self.MediaPlaying = false
			self:ResetBar()
			
			RunService:UnbindFromRenderStep("IslandMedia")
			playConnection:Disconnect()
			
			return
		end
		
		if math.abs(lastSaved - os.time()) >= 1 then
			lastSaved = os.time()
						
			if currentTime == lastTime then
				timer -= 1
			else
				timer = CONFIG.MEDIA_TIMEOUT
				lastTime = currentTime
			end
		end
		
		if self.Sound.Playing then
			self.PlayIcon.Image = "rbxassetid://"..CONFIG.MEDIA_PAUSE_ID
		else
			self.PlayIcon.Image = "rbxassetid://"..CONFIG.MEDIA_PLAY_ID
		end
		
		Spr.target(self.ProgressFrame, 1, 1, {Size = UDim2.new(currentTime/totalTime,0,1,0)})
	end)
	
	self.MediaIcon.Image = "rbxassetid://"..iconId
	self.MediaTitle.Text = title
	self.MediaAuthor.Text = author
	
	self.MediaContainer.GroupTransparency = 1
	self.MediaContainer.Visible = true
		
	self.MediaIcon.AnchorPoint = Vector2.new(0,.5)
	self.MediaIcon.Position = UDim2.new(.05,0,.335,0)
	self.MediaIcon.Size = UDim2.new(.25,0,.4,0)

	self.PlayIcon.AnchorPoint = Vector2.new(.5,.5)
	self.PlayIcon.Position = UDim2.new(.5,0,.8,0)
	self.PlayIcon.Size = UDim2.new(.25,0,.3,0)

	self.MediaTitle.Position = UDim2.new(.3,0,.175,0)
	self.MediaTitle.Size = UDim2.new(.65,0,.25,0)
	
	self.MediaAuthor.Position = UDim2.new(.3,0,.425,0)
	self.MediaAuthor.Size = UDim2.new(.65,0,.25,0)
	self.MediaAuthor.TextYAlignment = Enum.TextYAlignment.Top
	
	self.MediaIcon.Visible = true
	self.PlayIcon.Visible = true
	self.MediaTitle.Visible = true
	self.ProgressContainer.Visible = true
		
	-- Display full
	repeat task.wait() until self.Complete
	
	self.PlayIcon.Image = "rbxassetid://"..CONFIG.MEDIA_PAUSE_ID
	
	self:LargeMedia()
	
	task.wait(CONFIG.NOTIFICATION_DURATION)
		
	self.Click.Visible = true
	
	-- Desplay small
	self:SmallMedia()
	
	self.Sound.Ended:Connect(function()
		self.Sound:Stop()
		self.Sound:Destroy()

		self.MediaPlaying = false
		self:ResetBar()

		RunService:UnbindFromRenderStep("IslandMedia")
		playConnection:Disconnect()
		clickConnection:Disconnect()
		
		return
	end)
	
	self.SoundChanged:Connect(function()
		playConnection:Disconnect()
		clickConnection:Disconnect()
	end)
end



-- Helper Functions

function Island:ResetBar()
	if not self.MediaPlaying then
		self.Click.Visible = false

		Spr.target(self.Frame, 1.2, 4, {Size = UDim2.new(CONFIG.ISLAND_SIZE.X,0,CONFIG.ISLAND_SIZE.Y,0)})
		Spr.target(self.IslandCorner, 1.2, 4, {CornerRadius = UDim.new(1,0)})
		Spr.target(self.Container, 1, 4, {GroupTransparency = 1})
		Spr.target(self.MediaContainer, 1, 4, {GroupTransparency = 1})
		
		Spr.completed(self.Container, function()
			self.Container.Visible = false
			self.MediaContainer.Visible = false
		end)
	else
		self.Click.Visible = true

		self.MediaContainer.GroupTransparency = 1
		self.MediaContainer.Visible = true

		self.MediaAuthor.TextTransparency = 1
		self.ProgressContainer.GroupTransparency = 1

		self.PlayIcon.AnchorPoint = Vector2.new(0,.5)
		self.PlayIcon.Position = UDim2.new(.05,0,.5,0)
		self.PlayIcon.Size = UDim2.new(.2,0,.8,0)

		self.MediaTitle.Position = UDim2.new(.3,0,.5,0)
		self.MediaTitle.Size = UDim2.new(.65,0,.8,0)
		self.MediaTitle.TextYAlignment = Enum.TextYAlignment.Center

		self:SmallMedia(1.2)
	end
end

function Island:Large(damping: boolean)
	Spr.target(self.Frame, damping, 4, {Size = UDim2.new(.95,0,.2,0)})
	Spr.target(self.IslandCorner, damping, 4, {CornerRadius = UDim.new(.25,0)})
end

function Island:Small(damping: number)
	Spr.target(self.Frame, damping, 4, {Size = UDim2.new(.85,0,CONFIG.ISLAND_SIZE.Y,0)})
	Spr.target(self.IslandCorner, damping, 4, {CornerRadius = UDim.new(1,0)})
end

function Island:Square(damping: boolean)
	Spr.target(self.Frame, damping, 4, {Size = UDim2.new(CONFIG.ISLAND_SIZE.X,0,.175,0)})
	Spr.target(self.IslandCorner, damping, 4, {CornerRadius = UDim.new(.25,0)})
end

function Island:ShowContainer(notification: boolean)
	local containerTransparency = notification and 0 or 1
	local mediaTransparency = notification and 1 or 0
	
	Spr.target(self.Container, 1, 4, {GroupTransparency = containerTransparency})
	Spr.target(self.MediaContainer, 1, 4, {GroupTransparency = mediaTransparency})
end

function Island:LargeMedia()
	self:Large(1.2)
	self:ShowContainer(false)

	Spr.target(self.ProgressContainer, 1, 4, {GroupTransparency = 0})
	Spr.target(self.MediaAuthor, 1, 4, {TextTransparency = 0})
	Spr.target(self.MediaTitle, 1, 4, {Position = UDim2.new(.3,0,.175,0), Size = UDim2.new(.65,0,.25,0), AnchorPoint = Vector2.new(0,.5)})
	Spr.target(self.MediaIcon, 1, 4, {ImageTransparency = 0, BackgroundTransparency = 0})
	Spr.target(self.PlayIcon, 1, 4, {Position = UDim2.new(.5,0,.8,0), Size = UDim2.new(.25,0,.3,0), AnchorPoint = Vector2.new(.5,.5)})
end

function Island:SmallMedia()
	self:Small(1.2)
	self:ShowContainer(false)

	Spr.target(self.ProgressContainer, 1, 10, {GroupTransparency = 1})
	Spr.target(self.MediaAuthor, 1, 10, {TextTransparency = 1})
	Spr.target(self.MediaTitle, 1, 4, {Position = UDim2.new(.3,0,.5,0), Size = UDim2.new(.65,0,.8,0), AnchorPoint = Vector2.new(0,.5)})
	Spr.target(self.MediaIcon, 1, 10, {ImageTransparency = 1, BackgroundTransparency = 1})
	Spr.target(self.PlayIcon, 1, 4, {Position = UDim2.new(.05,0,.5,0), Size = UDim2.new(.25,0,.8,0), AnchorPoint = Vector2.new(0,.5)})
end

return Island
