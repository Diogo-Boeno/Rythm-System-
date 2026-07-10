--!strict
-- osu!-style rhythm hit target: a fixed circle with an approach ring that closes
-- in over `approachTime`. The ring meets the circle exactly at the beat — the
-- player clicks then. Timing error against that beat is bucketed into a judgement.
-- Self-contained: it owns its own clock/loop so a chart controller can just spawn
-- one per note (autoReset = false) while a practice screen loops one (autoReset = true).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local Theme = require(script.Parent.Theme)

local create = Vide.create
local source = Vide.source
local cleanup = Vide.cleanup

type Reactive<T> = T | () -> T

export type Judgement = "perfect" | "great" | "good" | "miss"
export type HitResult = {
	judgement: Judgement,
	-- signed timing error in ms: negative = early (clicked before the beat),
	-- positive = late. Miss reports the error at the moment it expired.
	errorMs: number,
}

export type HitCircleProps = {
	-- fired exactly once per note when it resolves (hit or miss)
	onJudge: ((HitResult) -> ())?,
	-- seconds for the ring to travel from spawn scale down to the circle
	approachTime: number?,
	-- half-width of each judgement window, in ms around the beat
	perfectMs: number?,
	greatMs: number?,
	goodMs: number?,
	-- re-arm after the feedback flash instead of freezing (practice/demo loop)
	autoReset: boolean?,
	-- if true, a click outside the hit window is ignored (the note stays live)
	-- instead of resolving as a miss — "only a click on the beat counts"
	onlyOnBeat: boolean?,
	-- optional key hint drawn inside the circle (e.g. "S", "F")
	label: Reactive<string>?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	parent: Instance?,
}

-- Ring starts this many times the circle diameter and shrinks to 1x at the beat.
local START_SCALE = 2.8
local DEFAULT_APPROACH = 1.2
local DEFAULT_PERFECT_MS = 40
local DEFAULT_GREAT_MS = 90
local DEFAULT_GOOD_MS = 140
-- how long the resolve flash plays before freezing / re-arming
local FEEDBACK_TIME = 0.18
-- gameplay ring reads better a touch thicker than the 1px technical UI stroke
local RING_THICKNESS = 3

-- monochrome-plus-amber judgement mapping: amber is the reward, gray reads as
-- "dead" for a miss — stays inside the design system's restricted palette
local JUDGE_COLOR: { [Judgement]: Color3 } = {
	perfect = Theme.color.accent,
	great = Theme.color.accentDim,
	good = Theme.color.textMuted,
	miss = Theme.color.textFaint,
}

-- pop the circle on resolve so a good hit feels punchy and a miss visibly deflates
local JUDGE_POP: { [Judgement]: number } = {
	perfect = 1.22,
	great = 1.16,
	good = 1.1,
	miss = 0.94,
}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function HitCircle(props: HitCircleProps)
	local approachTime = props.approachTime or DEFAULT_APPROACH
	local perfectMs = props.perfectMs or DEFAULT_PERFECT_MS
	local greatMs = props.greatMs or DEFAULT_GREAT_MS
	local goodMs = props.goodMs or DEFAULT_GOOD_MS
	local autoReset = props.autoReset == true

	-- reactive visual state
	local resolved = source(false)
	local ringScale = source(START_SCALE)
	local fade = source(0) -- 0 = fully visible, 1 = gone (feedback fade-out)
	local pop = source(1)
	local judgeColor = source(Theme.color.surfaceRaised)

	-- plain upvalues: the frame loop mutates these every step, they are not props
	local clockStart = os.clock()
	local resolveClock = 0
	local popStart = 1

	local function judgeFromError(errMs: number): Judgement
		local a = math.abs(errMs)
		if a <= perfectMs then
			return "perfect"
		elseif a <= greatMs then
			return "great"
		elseif a <= goodMs then
			return "good"
		end
		return "miss"
	end

	local function resolve(judgement: Judgement, errMs: number)
		if resolved() then
			return
		end
		resolved(true)
		judgeColor(JUDGE_COLOR[judgement])
		popStart = JUDGE_POP[judgement]
		pop(popStart)
		resolveClock = os.clock()

		if props.onJudge then
			props.onJudge({ judgement = judgement, errorMs = errMs })
		end
	end

	local function rearm()
		clockStart = os.clock()
		resolved(false)
		ringScale(START_SCALE)
		fade(0)
		pop(1)
		judgeColor(Theme.color.surfaceRaised)
	end

	local conn: RBXScriptConnection? = nil
	local function stop()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end

	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()

		if not resolved() then
			local elapsed = now - clockStart
			-- clamp so the ring locks onto the circle during the late window
			-- instead of collapsing past it
			ringScale(lerp(START_SCALE, 1, math.clamp(elapsed / approachTime, 0, 1)))

			-- ring sailed past the circle beyond the late-good window: auto-miss
			if elapsed > approachTime + goodMs / 1000 then
				resolve("miss", (elapsed - approachTime) * 1000)
			end
			return
		end

		local t = (now - resolveClock) / FEEDBACK_TIME
		if t >= 1 then
			if autoReset then
				rearm()
			else
				fade(1)
				stop()
			end
		else
			fade(t)
			-- ease the pop back toward rest as it fades
			pop(lerp(popStart, 1, t))
		end
	end)
	-- disconnect if the mounting scope (the controller's root) tears down mid-note,
	-- otherwise the RenderStepped connection leaks past the circle's lifetime
	cleanup(stop)

	return create "Frame" {
		Name = "HitCircle",
		Size = props.size or UDim2.fromOffset(96, 96),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		Parent = props.parent,

		-- the fixed target. Clickable throughout the approach so an early press
		-- still resolves the note (and misses) — matches osu! click semantics.
		create "TextButton" {
			Name = "Target",
			Size = UDim2.fromScale(1, 1),
			AutoButtonColor = false,
			BorderSizePixel = 0,
			BackgroundColor3 = function()
				return if resolved() then judgeColor() else Theme.color.surfaceRaised
			end,
			BackgroundTransparency = fade,
			Text = props.label or "",
			TextColor3 = Theme.color.textPrimary,
			TextTransparency = fade,
			TextSize = Theme.textSize.lg,
			FontFace = Theme.font.strong,

			Activated = function()
				if resolved() then
					return
				end
				local errMs = (os.clock() - clockStart - approachTime) * 1000
				local judgement = judgeFromError(errMs)
				-- onlyOnBeat: swallow off-beat clicks so the note survives until a
				-- real on-beat hit (or the auto-miss) — "click only on the rhythm"
				if judgement == "miss" and props.onlyOnBeat then
					return
				end
				resolve(judgement, errMs)
			end,

			create "UIScale" { Scale = pop },
			create "UICorner" { CornerRadius = UDim.new(1, 0) },
			create "UIAspectRatioConstraint" {},
			create "UIStroke" {
				Thickness = Theme.strokeThickness,
				Transparency = fade,
				Color = function()
					return if resolved() then judgeColor() else Theme.color.stroke
				end,
			},
		},

		-- the approach ring. Active=false so its (transparent) body never sinks
		-- clicks meant for the target underneath it.
		create "Frame" {
			Name = "ApproachRing",
			Active = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = function()
				local s = ringScale()
				return UDim2.fromScale(s, s)
			end,
			BackgroundTransparency = 1,

			create "UICorner" { CornerRadius = UDim.new(1, 0) },
			create "UIAspectRatioConstraint" {},
			create "UIStroke" {
				Thickness = RING_THICKNESS,
				Color = Theme.color.accent,
				-- ring only exists during the approach; hidden the instant it resolves
				Transparency = function()
					return if resolved() then 1 else 0
				end,
			},
		},
	}
end

return HitCircle
