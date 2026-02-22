local Players = game:GetService("Players")

local Blueprint = {}
Blueprint.__index = Blueprint

function Blueprint.new(houseName: string, editorGui: ScreenGui)
    local self = setmetatable({}, Blueprint)

    self.Player = Players.LocalPlayer
    self.HouseName = houseName
    self.EditorGui = editorGui

    return self
end

function Blueprint:Edit()
    -- Open editor GUI
    self.EditorGui.Visible = true

    -- Variables for ease of access
    local container = self.EditorGui.Background
    local titleFrame = container.Title
    local optionsFrame = container.Options

    local houseNameTextBox = titleFrame.HouseName
    local houseCostLabel = titleFrame.HouseCost
    local sqftLabel = titleFrame.Sqft
    local bedroomsLabel = titleFrame.Bedrooms
    local bathroomsLabel = titleFrame.Bathrooms

    local previewButton = optionsFrame.Preview
    local saveButton = optionsFrame.Save
    local exitButton = optionsFrame.Close
    local restartButton = optionsFrame.Restart

    -- Close editor GUI
    exitButton.MouseButton1Click:Connect(function()
        self.EditorGui.Visible = false
    end)
end

local Houses = {}
Houses.__index = Houses

function Houses.new(houseName: string, editorGui: ScreenGui)
    local self = setmetatable({}, Houses)

    self.Player = Players.LocalPlayer
    self.HouseName = houseName
    self.Blueprint = Blueprint.new(houseName)

    return self
    
end

return Houses