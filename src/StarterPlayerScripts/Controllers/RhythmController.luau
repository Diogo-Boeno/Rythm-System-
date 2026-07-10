--!strict
-- Client-side rhythm scoring. Each note is one HitCircle that lasts `duration`
-- seconds (the ring closes over that time); the beat is the instant it closes.
-- Scoring is binary and client-authoritative: HIT when the player clicks on the
-- beat, MISS when they never click (off-beat clicks are ignored, not punished).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local UI = require(ReplicatedStorage.Shared.UI.Common)
-- local Net = require(ReplicatedStorage.Shared.Framework.Net)

local create = Vide.create
local source = Vide.source
local root = Vide.root

local HitCircle = UI.HitCircle
local Theme = UI.Theme

-- points per hit; combo is just the running count of consecutive hits
local HIT_POINTS = 100
-- forgiveness window around the beat, in seconds: a click inside this = HIT
local HIT_WINDOW = 0.15
-- how long after the flash fades before the note instance is torn down
local NOTE_CLEANUP_DELAY = 0.25

type Note = { time: number, duration: number, position: UDim2 }

-- demo chart: `time` is when the beat lands (seconds from session start),
-- `duration` is how long that note's ring takes to close in.
local DEMO_CHART: { Note } = {
	{ time = 2.0, duration = 1.2, position = UDim2.fromScale(0.35, 0.45) },
	{ time = 3.0, duration = 1.2, position = UDim2.fromScale(0.5, 0.55) },
	{ time = 4.0, duration = 1.0, position = UDim2.fromScale(0.65, 0.45) },
	{ time = 4.6, duration = 1.0, position = UDim2.fromScale(0.5, 0.4) },
	{ time = 5.2, duration = 0.8, position = UDim2.fromScale(0.4, 0.55) },
}

local RhythmController = {}

-- session state (module-level, single local player)
local gui: ScreenGui? = nil
local prompt: ProximityPrompt? = nil
local score = source(0)
local combo = source(0)
local playing = false
local notesRemaining = 0

local function handleNoteResult(hit: boolean)
	if hit then
		score(score() + HIT_POINTS)
		combo(combo() + 1)
	else
		combo(0)
	end

	-- last note of the session resolved: re-arm the prompt so it can be played again
	notesRemaining -= 1
	if notesRemaining <= 0 then
		playing = false
		if prompt then
			prompt.Enabled = true
		end
	end
end

-- Starts one note at `position` that lasts `duration` seconds. Calls `onResult`
-- exactly once with true (hit on the beat) or false (never hit) when it resolves.
local function startNote(duration: number, position: UDim2, onResult: (hit: boolean) -> ())
	local screen = gui
	if not screen then
		return
	end

	-- each note gets its own reactive scope so the HitCircle can register its
	-- RenderStepped cleanup. create() does NOT destroy the instance on scope
	-- teardown, so we Destroy it ourselves once the resolve flash has faded.
	local destroyScope: (() -> ())?
	local instance: Instance?
	destroyScope, instance = root(function()
		return HitCircle {
			parent = screen,
			position = position,
			anchorPoint = Vector2.new(0.5, 0.5),
			approachTime = duration,
			-- one flat window collapses the graded judgement into hit-or-miss
			perfectMs = HIT_WINDOW * 1000,
			greatMs = HIT_WINDOW * 1000,
			goodMs = HIT_WINDOW * 1000,
			onlyOnBeat = true,
			onJudge = function(result)
				onResult(result.judgement ~= "miss")
				task.delay(NOTE_CLEANUP_DELAY, function()
					if destroyScope then
						destroyScope()
					end
					if instance then
						instance:Destroy()
					end
				end)
			end,
		}
	end)
end

local function playChart(chart: { Note }, onResult: (hit: boolean) -> ())
	for _, note in chart do
		-- fire early by the note's duration so the ring closes right on the beat
		local spawnIn = math.max(note.time - note.duration, 0)
		task.delay(spawnIn, function()
			startNote(note.duration, note.position, onResult)
		end)
	end
end

-- Plays the chart once. Ignored if a session is already running (the prompt is
-- disabled while playing, but this guards a double-trigger race too).
local function startSession()
	if playing then
		return
	end
	playing = true
	if prompt then
		prompt.Enabled = false
	end
	score(0)
	combo(0)
	notesRemaining = #DEMO_CHART
	playChart(DEMO_CHART, handleNoteResult)
end

function RhythmController:Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screen = create "ScreenGui" {
		Name = "RhythmGame",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = playerGui,
	}
	gui = screen

	-- HUD mounted once; the labels read score/combo reactively
	root(function()
		create "TextLabel" {
			Name = "Score",
			Size = UDim2.fromOffset(240, 40),
			Position = UDim2.new(1, -24, 0, 24),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Text = function()
				return string.format("%07d", score())
			end,
			TextColor3 = Theme.color.textPrimary,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextSize = Theme.textSize.lg,
			FontFace = Theme.font.heading,
			Parent = screen,
		}
		create "TextLabel" {
			Name = "Combo",
			Size = UDim2.fromOffset(240, 36),
			Position = UDim2.new(0, 24, 1, -24),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Text = function()
				local c = combo()
				return if c > 0 then string.format("%dx", c) else ""
			end,
			TextColor3 = Theme.color.accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = Theme.textSize.lg,
			FontFace = Theme.font.strong,
			Parent = screen,
		}
	end)

	-- the station part + prompt are built on the server (RhythmStationService)
	-- and replicated in; wait for them, then start a session on trigger
	local station = Workspace:WaitForChild("RhythmStation")
	local playPrompt = station:WaitForChild("PlayPrompt") :: ProximityPrompt
	prompt = playPrompt

	playPrompt.Triggered:Connect(function(player)
		-- on the client Triggered only fires for our own interaction, but guard anyway
		if player ~= Players.LocalPlayer then
			return
		end
		startSession()
	end)

	-- when a session ends, report the tally for the server to persist/validate:
	-- Net.FireServer("SubmitScore", score())
end

return RhythmController
