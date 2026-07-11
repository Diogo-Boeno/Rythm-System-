--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local UI = require(ReplicatedStorage.Shared.UI.Common)
local Tags = require(ReplicatedStorage.Shared.Framework.Tags)


local create = Vide.create
local source = Vide.source
local root = Vide.root

local HitCircle = UI.HitCircle
local Theme = UI.Theme

local HIT_POINTS = 100

local PERFECT_MS = 45
local GREAT_MS = 95
local GOOD_MS = 150

local NOTE_CLEANUP_DELAY = 0.45

local JUDGE_LABELS: { [UI.Judgement]: string } = {
	perfect = "Sick",
	great = "Good",
	good = "Bad",
	miss = "Miss",
}

type Note = { time: number, duration: number, position: UDim2 }

local CHART_POSITIONS: { UDim2 } = {
	UDim2.fromScale(0.35, 0.45),
	UDim2.fromScale(0.5, 0.55),
	UDim2.fromScale(0.65, 0.45),
	UDim2.fromScale(0.5, 0.4),
	UDim2.fromScale(0.4, 0.55),
	UDim2.fromScale(0.6, 0.5),
}
local CHART_APPROACH_BEATS = 2

local DEFAULT_BPM = 120
local DEFAULT_DURATION = 30

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


local gui: ScreenGui? = nil
local score = source(0)
local combo = source(0)
local playing = false
local notesRemaining = 0
local activePrompt: ProximityPrompt? = nil

local function endSession()
	playing = false
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	if activePrompt then
		activePrompt.Enabled = true
		activePrompt = nil
	end
end

local function handleNoteResult(hit: boolean)
	if hit then
		score(score() + HIT_POINTS)
		combo(combo() + 1)
	else
		combo(0)
	end

	notesRemaining -= 1
	if notesRemaining <= 0 then
		endSession()
	end
end


local function startNote(duration: number, position: UDim2, onResult: (hit: boolean) -> ())
	local screen = gui
	if not screen then
		return
	end


	local destroyScope: (() -> ())?
	local instance: Instance?
	destroyScope, instance = root(function()
		return HitCircle {
			parent = screen,
			position = position,
			anchorPoint = Vector2.new(0.5, 0.5),
			approachTime = duration,
			perfectMs = PERFECT_MS,
			greatMs = GREAT_MS,
			goodMs = GOOD_MS,
			onlyOnBeat = false,
			judgeLabels = JUDGE_LABELS,
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

local function startSession(prompt: ProximityPrompt, campart: BasePart?)
	if playing then
		return
	end
	playing = true
	score(0)
	combo(0)

	activePrompt = prompt
	prompt.Enabled = false

	if campart then
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		local info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
		TweenService:Create(camera, info, { CFrame = campart.CFrame }):Play()
	end

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

	Tags.bind("Prompt", function(instance)
		local proximityPrompt = instance :: ProximityPrompt
		local conn = proximityPrompt.Triggered:Connect(function(player)
			if player ~= Players.LocalPlayer then
				return
			end

			local campart = instance.Parent.Parent.Parent:FindFirstChild("CAMPART")
			startSession(proximityPrompt, if campart and campart:IsA("BasePart") then campart else nil)
		end)
		-- disconnect if the prompt loses the tag or is destroyed
		return function()
			conn:Disconnect()
		end
	end)


end

return RhythmController
