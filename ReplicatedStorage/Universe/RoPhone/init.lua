local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local CONFIG = require(script:WaitForChild("CONFIG"))

local viewport = Workspace.CurrentCamera.ViewportSize

local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end

function Connection:Disconnect()
	self._connected = false

	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(_, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_handlerListHead = false,
	}, Signal) :: any
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = false
end

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				-- Get the freeRunnerThread to the first yield
				coroutine.resume(freeRunnerThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

setmetatable(Signal, {
	__index = function(_, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

local Spring = {}
Spring.__index = Spring

function Spring.new(object: GuiObject, mass: number, stiffness: number, damping: number, properties: {[string]: any})
	local self = setmetatable({}, Spring)

	self.Mass = mass
	self.Damping = damping
	self.Stiffness = stiffness

	self.PosVelocity = 0
	self.SizeVelocity = 0
	self.RotationVelocity = 0
	self.AnchorPointVelocity = 0

	self.Target = properties

	self.Object = object
	
	return self
end

function Spring:SetTarget(properties:{[string]: any})
	for property, targetValue in pairs(properties) do
		for property2, _ in pairs(self.Target) do
			if property == property2 then
				self.Target[property2] = targetValue
				continue
			end
		end

		self.Target[property] = targetValue
	end

	print(self.PosVelocity)
end

local function SpringAnimation(position, target, stiffness, damping, velocity, mass, dt)
	local displacement = position - target
		
	local springForce = -stiffness * displacement
	local dampingForce = -damping * velocity

	local acceleration = (springForce + dampingForce) / mass
	velocity = velocity + acceleration * dt
	position = position + velocity * dt
	return position, velocity
end

function Spring:Play(graph: Frame?)
	local spring = 0
	local springTime = 0

	RunService.RenderStepped:Connect(function(deltaTime)
		for property, targetValue in pairs(self.Target) do
			if self.Object[property] == nil then
				continue
			end

			if self.Object[property] == targetValue then
				continue
			end

			if property == "Position" then
				local x1 = self.Object.Position.X.Scale
				local x2 = self.Object.Position.X.Offset
				local y1 = self.Object.Position.Y.Scale
				local y2 = self.Object.Position.Y.Offset

				local v1 = self.PosVelocity
				local v2 = self.PosVelocity
				local v3 = self.PosVelocity
				local v4 = self.PosVelocity

				x1, v1 = SpringAnimation(x1, targetValue.X.Scale, self.Stiffness, self.Damping, v1, self.Mass, deltaTime)
				x2, v2 = SpringAnimation(x2, targetValue.X.Offset, self.Stiffness, self.Damping, v2, self.Mass, deltaTime)
				y1, v3 = SpringAnimation(y1, targetValue.Y.Scale, self.Stiffness, self.Damping, v3, self.Mass, deltaTime)
				y2, v4 = SpringAnimation(y2, targetValue.Y.Offset, self.Stiffness, self.Damping, v4, self.Mass, deltaTime)

				self.PosVelocity = (v1 + v2 + v3 + v4) / 4
				self.Object.Position = UDim2.new(x1, x2, y1, y2)
			end

			if property == "AnchorPoint" then
				local x, y = self.Object.AnchorPoint.X, self.Object.AnchorPoint.Y
				
				local v1, v2 = self.AnchorPointVelocity, self.AnchorPointVelocity

				x, v1 = SpringAnimation(x, targetValue.X, self.Stiffness, self.Damping, v1, self.Mass, deltaTime)
				y, v2 = SpringAnimation(y, targetValue.Y, self.Stiffness, self.Damping, v2, self.Mass, deltaTime)

				self.AnchorPointVelocity = (v1 + v2) / 2
				self.Object.AnchorPoint = Vector2.new(x, y)
			end

			if property == "Rotation" then
				local rotation = self.Object.Rotation
				
				local v1 = self.RotationVelocity

				rotation, v1 = SpringAnimation(rotation, targetValue, self.Stiffness, self.Damping, v1, self.Mass, deltaTime)
				
				self.RotationVelocity = v1
				self.Object.Rotation = rotation
			end

			if property == "Size" then
				local x1 = self.Object.Size.X.Scale
				local x2 = self.Object.Size.X.Offset
				local y1 = self.Object.Size.Y.Scale
				local y2 = self.Object.Size.Y.Offset

				local v1 = self.SizeVelocity
				local v2 = self.SizeVelocity
				local v3 = self.SizeVelocity
				local v4 = self.SizeVelocity

				x1, v4 = SpringAnimation(x1, targetValue.X.Scale, self.Stiffness, self.Damping, v1, self.Mass, deltaTime)
				x2, v1 = SpringAnimation(x2, targetValue.X.Offset, self.Stiffness, self.Damping, v2, self.Mass, deltaTime)
				y1, v2 = SpringAnimation(y1, targetValue.Y.Scale, self.Stiffness, self.Damping, v3, self.Mass, deltaTime)
				y2, v3 = SpringAnimation(y2, targetValue.Y.Offset, self.Stiffness, self.Damping, v4, self.Mass, deltaTime)

				self.SizeVelocity = (v1 + v2 + v3 + v4) / 4
				self.Object.Size = UDim2.new(x1, x2, y1, y2)
			end
		end

		spring = SpringAnimation(spring, 1, self.Stiffness, self.Damping, 0, self.Mass, deltaTime)
		
		springTime += deltaTime

		if graph then
			local dot = Instance.new("Frame", graph)
			dot.BackgroundColor3 = Color3.new(1, 0, 0)
			dot.BorderSizePixel = 0
			dot.Size = UDim2.new(.0025, 0, 0.025, 0)
			dot.AnchorPoint = Vector2.new(0.5, 0.5)

			local corner = Instance.new("UICorner", dot)
			corner.CornerRadius = UDim.new(0.5, 0)

			local ratio = Instance.new("UIAspectRatioConstraint", dot)
			ratio.AspectRatio = 1

			dot.Position = UDim2.new(springTime*.1, 0, 1-spring, 0)
		end
	end)
end

local RoPhone = {}
RoPhone.__index = RoPhone

function RoPhone.new(phoneFrame: Frame, screen: CanvasGroup)
	local self = setmetatable({}, RoPhone)

	self.PhoneFrame = phoneFrame
	self.Screen = screen

	self.Notifications = {}

	return self
end

function RoPhone:CreateLockscreen(lockscreen: CanvasGroup, password: string?)
	if self.Lockscreen ~= nil then
		warn("Lockscreen already exists for this RoPhone instance")
		return
	end

	self.Password = password or nil
	self.Lockscreen = lockscreen
end

function RoPhone:CreateIsland(island: CanvasGroup)
	if self.Island ~= nil then
		warn("Island already exists for this RoPhone instance")
		return
	end

	self.Island = island
end

function RoPhone:CreateSpring(object: GuiObject, mass: number, stiffness: number, damping: number, properties: {[string]: any})
	return Spring.new(object, mass, stiffness, damping, properties)
end

function RoPhone:CreateNotification(appId: number, message: string, imageId: number?)
	if self.Notifications[appId] == nil then
		self.Notifications[appId] = {}
	end
	
	table.insert(self.Notifications[appId], {
		Message = message,
		ImageId = imageId or nil
	})
end

return RoPhone