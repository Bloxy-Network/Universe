-- @ScriptType: ModuleScript

local Lockscreen = {}
Lockscreen.__index = Lockscreen

function Lockscreen.new()
  local self = setmetatable({}, Lockscreen)

  self.Frame = Instance.new("CanvasGroup")
  self.Frame.AnchorPoint = Vector2.new(.5,.5)
  self.Frame.Position = UDim2.new(.5,0,.5,0)
  self.Frame.Size = UDim2.new(1,0,1,0)

  self.Background = Instance.new("ImageLabel", self.Frame)
  self.Background.AnchorPoint = Vector2.new(.5,.5)
  self.Background.Position = UDim2.new(.5,0,.5,0)
  self.Background.Size = UDim2.new(1,0,1,0)

  self.Locked = true
  self.Password = Password.new()

  self.Password.Frame.Parent = self.Frame
  
  return self
end

return Lockscreen
