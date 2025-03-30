-- #ScriptType: ModuleScript

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Signal = require(dependencies:WaitForChild("GoodSignal"))
local Spring = require(script.Parent.Parent:WaitForChild("Spring"))

local Swipe = {}
Swipe.__index = Swipe

function Swipe.new(frame: Frame | CanvasGroup)
	local self = setmetatable({}, Swipe)
	
	self.Frame = frame
	
	self.SwipeStarted = Signal.new()
	self.SwipeEnded = Signal.new()
	self.SwipeChanged = Signal.new()
	
	self.Swiped = Signal.new()
	
	local mouseDown = false
	
	UserInputService.InputBegan:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
			local mouse = UserInputService:GetMouseLocation()
			if self:InFrame(mouse) then
				mouseDown = true
				self.SwipeStarted:Fire(mouse)
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and mouseDown then
			self.SwipeEnded:Fire()
			mouseDown = false
		end
	end)
	
	local startPos = 0
	local startTime = 0
	local lastPos = 0
	local delta = 0
	
	self.SwipeStarted:Connect(function(startMouse: Vector2)
		startPos = math.clamp((startMouse.X - frame.AbsolutePosition.X)/frame.AbsoluteSize.X, 0, 1)
		startTime = tick()
		
		RunService:BindToRenderStep("Swipe", Enum.RenderPriority.Last.Value, function()
			local mouse = UserInputService:GetMouseLocation()
			lastPos = math.clamp((mouse.X - frame.AbsolutePosition.X)/frame.AbsoluteSize.X, 0, 1)
			delta = lastPos - startPos
			
			self.SwipeChanged:Fire(startPos, delta)
		end)
	end)
	
	self.SwipeEnded:Connect(function()
		RunService:UnbindFromRenderStep("Swipe")
		
		local timeDelta = tick() - startTime
		
		local velocity = math.abs(delta)/timeDelta
		local acceleration = velocity/timeDelta
		
		self.Swiped:Fire(acceleration)
	end)
	
	return self
end

function Swipe:InFrame(mouse: Vector2)
	local pointA = self.Frame.AbsolutePosition
	local pointB = self.Frame.AbsolutePosition + self.Frame.AbsoluteSize
	
	return ((mouse.X > pointA.X and mouse.Y > pointA.Y) and (mouse.X < pointB.X and mouse.Y < pointB.Y))
end

return Swipe
