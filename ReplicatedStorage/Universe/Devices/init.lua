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

local function SpringDuration(start, target, velocity, response, damping)
	local epsilon = 0.001

	local displacement = start - target

	local omega = 2 * math.pi / response

	if damping >= 1 then
		return math.log(math.abs(displacement) / epsilon) / omega
	end

	local dampedOmega = omega * math.sqrt(1 - damping^2)
	local peakAmp = math.sqrt(displacement^2 + ((velocity + damping * omega * displacement) / dampedOmega)^2)

	return math.log(peakAmp / epsilon) / (damping * omega)
end

local function SpringAnimation(start, target, velocity, response, damping, dt)
	local displacement = start - target

	local omega = 2 * math.pi / response

	local expTerm = math.exp(-damping * omega * dt)

	local cosTerm, sinTerm
	if damping < 1 then
		local dampedOmega = omega * math.sqrt(1 - damping^2)
		cosTerm = math.cos(dampedOmega * dt)
		sinTerm = math.sin(dampedOmega * dt)

		local coeff = (velocity + damping * omega * displacement) / dampedOmega

		displacement = expTerm * (displacement * cosTerm + coeff * sinTerm)
		velocity = expTerm * (velocity * (cosTerm - damping * omega * sinTerm/dampedOmega) - displacement * omega * sinTerm * dampedOmega)
	else
		displacement = expTerm * (displacement + (velocity + omega * displacement) * dt)
		velocity = expTerm * (velocity - omega * (velocity + omega * displacement) * dt)
	end

	return target + displacement, velocity
end

function Spring.new(object: GuiObject, response: number, damping: number, properties: {[string]: any})
	local self = setmetatable({}, Spring)

	self.Response = response
	self.Damping = damping

	self.Velocity = 0
	self.Target = properties
	self.Object = object

	self.Time = 0
	self.TimeLength = SpringDuration(0, 1, self.Velocity, self.Response, self.Damping)

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
end

function Spring:Play(graph: Frame?)
	local velocities = {}
	local graphY = 0
	local graphV = 0

	self.Connection = RunService.RenderStepped:Connect(function(deltaTime)
		self.Time += deltaTime

		if self.Time >= self.TimeLength then
			self.Connection:Disconnect()
			self.Connection = nil
			print(self.Time)
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

				local s1, s2, s3, s4 = 0, 0, 0, 0
				local v1, v2, v3, v4 = 0, 0, 0, 0

				for i, v in pairs(velocities) do
					if i == property then
						v1, v2, v3, v4 = unpack(v)
						break
					end
				end

				s1, v1 = SpringAnimation(x1, targetValue.X.Scale, v1, self.Response, self.Damping, deltaTime)
				s2, v2 = SpringAnimation(x2, targetValue.X.Offset, v2, self.Response, self.Damping, deltaTime)
				s3, v3 = SpringAnimation(y1, targetValue.Y.Scale, v3, self.Response, self.Damping, deltaTime)
				s4, v4 = SpringAnimation(y2, targetValue.Y.Offset, v4, self.Response, self.Damping, deltaTime)

				velocities[property] = {v1,v2,v3,v4}

				self.Object[property] = UDim2.new(s1, s2, s3, s4)
			end

			if property == "AnchorPoint" then
				local x = self.Object.AnchorPoint.X
				local y = self.Object.AnchorPoint.Y

				local s1, s2 = 0, 0
				local v1, v2 = 0, 0

				for i, v in pairs(velocities) do
					if i == property then
						v1, v2 = unpack(v)
						break
					end
				end

				s1, v1 = SpringAnimation(x, targetValue.X, v1, self.Response, self.Damping, deltaTime)
				s2, v2 = SpringAnimation(y, targetValue.Y, v2, self.Response, self.Damping, deltaTime)
				
				velocities[property] = {v1, v2}
				self.Object.AnchorPoint = Vector2.new(s1, s2)
			end

			if property == "Rotation" then
				local rotation = self.Object.Rotation
				local s1, v1 = 0, 0

				for i, v in pairs(velocities) do
					if i == property then
						v1 = v[1]
						break
					end
				end
				
				s1, v1 = SpringAnimation(rotation, targetValue, v1, self.Response, self.Damping, deltaTime)
				velocities[property] = {v1}
				self.Object.Rotation = s1
			end
		end

		graphY, graphV = SpringAnimation(graphY, 1, graphV, self.Response, self.Damping, deltaTime)

		if graph then
			local dot = Instance.new("Frame", graph)
			dot.BackgroundColor3 = Color3.new(1, 0, 0)
			dot.BorderSizePixel = 0
			dot.Size = UDim2.new(.025, 0, 0.05, 0)
			dot.AnchorPoint = Vector2.new(0.5, 0.5)

			local corner = Instance.new("UICorner", dot)
			corner.CornerRadius = UDim.new(0.5, 0)

			local ratio = Instance.new("UIAspectRatioConstraint", dot)
			ratio.AspectRatio = 1

			dot.Position = UDim2.new(self.Time/self.TimeLength, 0, 1-graphY, 0)
		end
	end)
end

local Grid = {}
Grid.__index = Grid

local viewportSize = workspace.CurrentCamera.ViewportSize

function Grid.new(container: Frame | CanvasGroup, gridSize: Vector2)
	local self = setmetatable({}, Grid)

	self.GridSize = gridSize

	self.Container = container
	self.Objects = {}

	return self
end

function Grid:AddObject(object: GuiObject)
	local objectSizeX = object.Size.X.Scale
	local objectSizeY = object.Size.Y.Scale

	-- Convert offset size to scale size and add to scale size
	objectSizeX += object.Size.X.Offset / viewportSize.X
	objectSizeY += object.Size.Y.Offset / viewportSize.Y

	-- Ensure anchor point is centered for the object
	object.AnchorPoint = Vector2.new(.5,.5)

	-- Rounded tile size, always an integer
	local objectSize = Vector2.new(
		math.round(objectSizeX*self.GridSize.X),
		math.round(objectSizeY*self.GridSize.Y)
	)

	-- Update object size to match rounded tile size
	object.Size = UDim2.fromScale(objectSize.X/self.GridSize.X, objectSize.Y/self.GridSize.Y)

	-- Add object to objects table
	self.Objects[object] = {
		TileSize = objectSize,
		Position = UDim2.fromScale(0,0)
	}
end

function Grid:UpdateSize(gridSize: Vector2)
	self.GridSize = gridSize
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

function RoPhone:CreateSpring(object: GuiObject, response: number, damping: number, properties: {[string]: any})
	return Spring.new(object, response, damping, properties)
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