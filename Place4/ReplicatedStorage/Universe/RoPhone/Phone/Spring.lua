-- @ScriptType: ModuleScript

local dependencies = script.Parent:WaitForChild("Dependencies")
local Spr = require(dependencies:WaitForChild("Spr"))
local Signal = require(dependencies:WaitForChild("GoodSignal"))

local Spring = {}
Spring.__index = Spring

function Spring.new(instance: Instance, damping: number, frequency: number, properties: {[string]: any})
	local self = setmetatable({}, Spring)
	
	self.Instance = instance
	self.Damping = damping
	self.Frequency = frequency
	self.Properties = properties
	
	self.Completed = Signal.new()
	self.Started = Signal.new()
	
	return self
end

function Spring:Play()
	self.Started:Fire()
	Spr.target(self.Instance, self.Damping, self.Frequency, self.Properties)
	
	Spr.completed(self.Instance, function()
		self.Completed:Fire()
	end)
end

function Spring:Stop(property: string?)
	Spr.stop(self.Instance, property)
end

return Spring
