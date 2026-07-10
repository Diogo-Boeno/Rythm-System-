--!strict
-- Server-owned rhythm station: a physical part in the world carrying a
-- ProximityPrompt. The world object lives on the server (authority) and
-- replicates to everyone; each client listens to the prompt's Triggered to
-- start its own session (see RhythmController).

local Workspace = game:GetService("Workspace")

local RhythmStationService = {}

local function buildStation()
	local part = Instance.new("Part")
	part.Name = "RhythmStation"
	part.Size = Vector3.new(4, 6, 1)
	-- just in front of a default spawn so it's reachable on a fresh baseplate
	part.Position = Vector3.new(0, 3, -8)
	part.Anchored = true
	part.CanCollide = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(21, 21, 24)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayPrompt"
	prompt.ActionText = "Jogar"
	prompt.ObjectText = "Rhythm"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = part

	part.Parent = Workspace
end

function RhythmStationService:Start()
	buildStation()
end

return RhythmStationService
