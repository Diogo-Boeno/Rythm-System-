--!strict
-- Client-side rhythm scoring. Each note is one HitCircle that lasts `duration`
-- seconds (the ring closes over that time); the beat is the instant it closes.
-- Scoring is binary and client-authoritative: HIT when the player clicks on the
-- beat, MISS when they never click (off-beat clicks are ignored, not punished).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local UI = require(ReplicatedStorage.Shared.UI.Common)
local Tags = require(ReplicatedStorage.Shared.Framework.Tags)
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

-- generated notes cycle these anchor points so consecutive beats don't stack up
local CHART_POSITIONS: { UDim2 } = {
	UDim2.fromScale(0.35, 0.45),
	UDim2.fromScale(0.5, 0.55),
	UDim2.fromScale(0.65, 0.45),
	UDim2.fromScale(0.5, 0.4),
	UDim2.fromScale(0.4, 0.55),
	UDim2.fromScale(0.6, 0.5),
}
-- approach ring closes over this many beats — ~1s at 120 BPM, matching the old hand-authored feel
local CHART_APPROACH_BEATS = 2
-- default tempo/length a prompt trigger plays; the session ends when the last beat resolves
local DEFAULT_BPM = 120
local DEFAULT_DURATION = 30

-- Builds a chart of one note per beat spanning `durationSeconds`. `bpm` sets the beat
-- spacing (60/bpm), so the chart itself defines the playtime: it ends when the last
-- note resolves. e.g. buildChart(120, 30) -> 60 notes, one every 0.5s.
local function buildChart(bpm: number, durationSeconds: number): { Note }
	local beatInterval = 60 / bpm
	local approachTime = beatInterval * CHART_APPROACH_BEATS
	local chart: { Note } = {}
	local beat = 1
	while beat * beatInterval <= durationSeconds do
		table.insert(chart, {
			time = beat * beatInterval,
			duration = approachTime,
			position = CHART_POSITIONS[(beat - 1) % #CHART_POSITIONS + 1],
		})
		beat += 1
	end
	return chart
end

local RhythmController = {}

-- session state (module-level, single local player)
local gui: ScreenGui? = nil
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

	-- last note of the session resolved: free the session so a prompt can start it again
	notesRemaining -= 1
	if notesRemaining <= 0 then
		playing = false
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

-- Plays the chart once. Ignored while a session is already running, so a second
-- prompt trigger mid-song does nothing.
local function startSession()
	if playing then
		return
	end
	playing = true
	score(0)
	combo(0)
	local chart = buildChart(DEFAULT_BPM, DEFAULT_DURATION)
	notesRemaining = #chart
	playChart(chart, handleNoteResult)
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

	-- any ProximityPrompt tagged "Prompt" (placed in Studio) starts a session on
	-- trigger. Bind once — Tags wires up every current and future tagged prompt.
	Tags.bind("Prompt", function(instance)
		local proximityPrompt = instance :: ProximityPrompt
		local conn = proximityPrompt.Triggered:Connect(function(player)
			-- on the client Triggered only fires for our own interaction, but guard anyway
			if player ~= Players.LocalPlayer then
				return
			end
			startSession()
		end)
		-- disconnect if the prompt loses the tag or is destroyed
		return function()
			conn:Disconnect()
		end
	end)

	-- when a session ends, report the tally for the server to persist/validate:
	-- Net.FireServer("SubmitScore", score())
end

return RhythmController
