local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local viewport = Workspace.CurrentCamera.ViewportSize

-- GoodSignal implementation
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

-- Spring motion implementation
local Spring = {}
Spring.__index = Spring

local function SettleTime(stiffness, damping, mass)
	local epsilon = 0.01
	local omega_n = math.sqrt(stiffness / mass)
	local zeta = damping / (2 * math.sqrt(stiffness * mass))

	if zeta == 0 then
		return math.huge()
	end

	return -math.log(epsilon) / (zeta * omega_n)
end

function Spring.new(object: GuiObject, mass: number, stiffness: number, damping: number, properties: {[string]: any})
	local self = setmetatable({}, Spring)

	self.Mass = mass
	self.Damping = damping
	self.Stiffness = stiffness

	self.Velocity = 0
	self.Target = properties
	self.Object = object

	self.Time = 0
	self.TimeLength = SettleTime(stiffness, damping, mass)

	self.Connection = nil

	self.Finished = Signal.new()
	self.Stopped = Signal.new()
	
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

local function SpringAnimation(start, target, stiffness, damping, velocity, mass, dt)
	local displacement = start - target
		
	local springForce = -stiffness * displacement
	local dampingForce = -damping * velocity

	local acceleration = (springForce + dampingForce) / mass
	velocity = velocity + acceleration * dt
	local position = start + velocity * dt

	return position, velocity
end

function Spring:Play(graph: Frame?)
	local multiplier = 0
	local values = {}

	self.Connection = RunService.RenderStepped:Connect(function(deltaTime)		
		multiplier, self.Velocity = SpringAnimation(multiplier, 1, self.Stiffness, self.Damping, self.Velocity, self.Mass, deltaTime) / 1
		values[#values + 1] = multiplier
		self.Time += deltaTime

		if self.Time >= self.TimeLength then
			self.Connection:Disconnect()
			self.Connection = nil
			self.Time = 0
			self.Finished:Fire()
		end
		
		for property, targetValue in pairs(self.Target) do
			if self.Object[property] == nil then
				continue
			end

			if self.Object[property] == targetValue then
				continue
			end

			if property == "Position" or property == "Size" then
				local x1 = self.Object[property].X.Scale
				local x2 = self.Object[property].X.Offset
				local y1 = self.Object[property].Y.Scale
				local y2 = self.Object[property].Y.Offset

				local d1 = targetValue.X.Scale - x1
				local d2 = targetValue.X.Offset - x2
				local d3 = targetValue.Y.Scale - y1
				local d4 = targetValue.Y.Offset - y2

				local s1 = x1 + (d1 * multiplier)
				local s2 = x2 + (d2 * multiplier)
				local s3 = y1 + (d3 * multiplier)
				local s4 = y2 + (d4 * multiplier)

				self.Object[property] = UDim2.new(s1, s2, s3, s4)
			end

			if property == "AnchorPoint" then
				local x, y = self.Object.AnchorPoint.X, self.Object.AnchorPoint.Y

				local d1 = targetValue.X - x
				local d2 = targetValue.Y - y

				local s1 = x + (d1 * multiplier)
				local s2 = y + (d2 * multiplier)
				
				self.Object.AnchorPoint = Vector2.new(s1, s2)
			end

			if property == "Rotation" then
				local rotation = self.Object.Rotation
				local d1 = targetValue - rotation
				local s1 = rotation + (d1 * multiplier)
				
				self.Object.Rotation = s1
			end
		end

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

			dot.Position = UDim2.new(self.Time*.1, 0, 1-multiplier, 0)
		end
	end)
end

local App = {}
App.__index = App

function App.new(appName: string, appFrame: CanvasGroup, appImageId: number)
	local self = setmetatable({}, App)

	self.Name = appName
	self.Frame = appFrame
	self.ImageId = appImageId

	self.Open = false
	self.Minimized = false
	self.Closed = true

	return self
end

function App:Open()
	self.Frame.Visible = true

	self.Open = true
	self.Minimized = false
	self.Closed = false
end

function App:Minimize()
	self.Frame.Visible = false

	self.Open = false
	self.Minimized = true
	self.Closed = false
end

function App:Close()
	self.Frame.Visible = false

	self.Open = false
	self.Minimized = false
	self.Closed = true
end

local RoPhone = {}
RoPhone.__index = RoPhone

function RoPhone.new(phoneFrame: Frame, screen: CanvasGroup)
	local self = setmetatable({}, RoPhone)

	self.PhoneFrame = phoneFrame
	self.Screen = screen

	self.Lockscreen = nil
	self.Password = nil
	self.Island = nil

	self.Apps = {}
	self.OpenedApps = {}

	self.Notifications = {}
	self.PushedNotification = Signal.new()

	return self
end

function RoPhone:CreateApp(appName: string, appFrame: CanvasGroup, appImage: number): number
	local app = App.new(appName, appFrame, appImage)

	local appId = #self.Apps + 1

	self.Apps[appId] = app
	return appId
end

function RoPhone:CreateLockscreen(lockscreen: CanvasGroup, password: number?)
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

function RoPhone:UpdatePassword(password: number)
	self.Password = password
end

local RoWatch = {}
RoWatch.__index = RoWatch

function RoWatch.new(watchFrame: Frame)
	local self = setmetatable({}, RoWatch)

	self.WatchFrame = watchFrame

	return self
end

function RoWatch:PushNotification()
	
end

local RoHome = {}
RoHome.__index = RoHome

function RoHome.new()
	
end

local Device = {}
Device.__index = Device

function Device.CreatePhone(phoneFrame: Frame, screen: CanvasGroup)
	return RoPhone.new(phoneFrame, screen)
end



return Device