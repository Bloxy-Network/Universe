local CONFIG = {}

-- Device data
CONFIG.DATA_REMOTE = nil						-- RemoteEvent that data will be passed through

-- Device looks
CONFIG.SIZE = UDim2.new(.2,0,.7,0) 				-- Size of phone (Constrained by AspectRatio)
CONFIG.POSITION = UDim2.new(.5,0,.5,0) 			-- Position of phone on-screen
CONFIG.ANCHOR_POINT = Vector2.new(.5,.5) 		-- Anchor point of phone
CONFIG.CORNER_RADIUS = UDim.new(.125,0) 		-- Corner radius of the phone
CONFIG.ASPECT_RATIO = .49						-- Aspect ratio of the phone (9:16 is .52) (9:19.5 is .49)
CONFIG.PHONE_COLOR = Color3.new(0, 0, 0)		-- Color of phone case
CONFIG.THICKNESS = 3							-- Phone case thickness
CONFIG.POWER_COLOR = Color3.new(0,0,0)			-- Power button color
CONFIG.VOLUME_COLOR = Color3.new(0,0,0)			-- Volume button color

-- UI defaults
CONFIG.ISLAND_MARGIN = .015						-- Scape between top of screen and top of Island Bar in scale
CONFIG.ISLAND_SIZE = Vector2.new(.375,.06)		-- Size of the Island Bar in scale

CONFIG.GESTURE_MARGIN = .01						-- Space between bottom of screen and bottom of Gesture Bar in scale
CONFIG.GESTURE_SIZE = Vector2.new(.6,.015)		-- Size of the Gesture Bar in scale

CONFIG.APP_GRID_SIZE = Vector2.new(4,5) 		-- Default number of rows and columns
CONFIG.APP_GRID_SPACING = Vector2.new(.2,.2)	-- Padding between apps

CONFIG.DOCK_MARGIN = .01						-- Space between top of Gesture Bar and bottom of Dock
CONFIG.DOCK_SIZE = Vector2.new(.95,.125)		-- Size of the Dock on the homescreen
CONFIG.DOCK_CORNER_RADIUS = UDim.new(.4,0)		-- Corner radius of the Dock
CONFIG.DOCK_COLOR = Color3.new(0,0,0)			-- Color of the Dock
CONFIG.DOCK_APPS = 4							-- Max number of apps allowed in the Dock
CONFIG.DOCK_PADDING = Vector2.new(.075, .3)		-- Padding (x,y) of app button to edge of Dock

CONFIG.DYNAMIC_WALLPAPER = true					-- Wallpaper will move when swiping between homescreen pages

CONFIG.INFO_BAR_SIZE = Vector2.new(.1,.04)		-- Size of the InfoBar
CONFIG.INFO_BAR_MARGIN = .015					-- Margin from top of Dock to bottom of InfoBar
CONFIG.DOT_SPACING = .05						-- Spacing between each dot in the InfoBar in scale

CONFIG.MEDIA_PLAY_ID = 91627705357741			-- Play button image ID (Island media)
CONFIG.MEDIA_PAUSE_ID = 105425577870678			-- Pause button image ID (Island media)
CONFIG.MEDIA_SKIP_ID = 131609719356033			-- Skip button image ID (Island media)

-- Device defaults
CONFIG.DEFAULT_VOLUME = .5 						-- Default volume of the device

CONFIG.NOTIFICATION_ID = 0						-- Default notification sound
CONFIG.NOTIFICATION_DURATION = 2				-- Time, in seconds, that notifications are displayed
CONFIG.ANIMATION_SPEED = 1						-- Default animation speed

CONFIG.APP_TIMEOUT = 5							-- Time, in seconds, before OS.RegisterApp() quits and errors if app is not loaded.
CONFIG.MEDIA_TIMEOUT = 5						-- Time, in seconds, that media needs to be paused to close the media player

-- Customizables
CONFIG.WALLPAPER_ID = 116568521810438			-- Default wallpaper image ID

return CONFIG
