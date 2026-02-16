local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local CONFIG = require(script:WaitForChild("CONFIG"))

local viewport = Workspace.CurrentCamera.ViewportSize

local Spring = {}
Spring.__index = Spring

function Spring.new(mass: number, stiffness: number, damping: number, start: number, finish: number)
	local self = setmetatable({}, Spring)

	self.Mass = mass
	self.Displacement = math.abs(start - finish)
	self.Damping = damping
	self.Stiffness = stiffness
	
	return self
end

function Spring:Play()
	local m = self.Mass
	local x = self.Displacement
	local t = 0
	local c = self.Damping
	local k = self.Stiffness

	RunService.RenderStepped:Connect(function(deltaTime)
		t+=deltaTime
		print((m*(x/t^2)) + (c*(x/t)) + (k*x))
	end)
end

local RoPhone = {}
RoPhone.__index = RoPhone

function RoPhone.new()
	
end

return RoPhone