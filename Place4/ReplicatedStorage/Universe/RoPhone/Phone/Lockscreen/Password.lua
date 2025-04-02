-- @ScriptType: ModuleScript

local dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Signal = require(dependencies:WaitForChild("GoodSignal"))
local Spring = require(script.Parent.Parent:WaitForChild("Spring"))

local Password = {}
Password.__index = Password

function Password.new()
  local self = setmetatable({}, Password)

  self.Frame = Instance.new("CanvasGroup")
  self.Frame.AnchorPoint = Vector2.new(.5,.5)
  self.Frame.Position = UDim2.new(.5,0,.5,0)
  self.Frame.Size = UDim2.new(1,0,1,0)

  self.Password = ""
  self.PasswordChanged = Signal.new()
  
  return self
end

function Password:ChangePassword(password: string)
  self.Password = ""
  self.PasswordChanged:Fire(self.Password)
end

return Password
