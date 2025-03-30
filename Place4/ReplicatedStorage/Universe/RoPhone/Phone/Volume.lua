local dependencies = script.Parent:WaitForChild("Dependencies")
local Signal = require(dependencies:WaitForChild("GoodSignal"))

local Volume = {}
Volume.__index = Volume

function Volume.new(defaultVolume: number)
	local self = setmetatable({}, Volume)

	self.ButtonUp = Instance.new("TextButton")
	self.ButtonDown = Instance.new("TextButton")

	self.Level = defaultVolume or .5
	self.Instances = {} :: {Sound}

	self.Changed = Signal.new()

	return self
end

function Volume:Up(amount: number)
	self.Changed:Fire()
end

function Volume:Down(amount: number)
	self.Changed:Fire()
end

return Volume
