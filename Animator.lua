local Tween = require(script.Parent:WaitForChild("Tween"))
local Animator = {}

local USE_TRANSFORM = false

local Priorities = {
	[5] = 0, -- Action4
	[4] = 1,
	[3] = 2,
	[Enum.AnimationPriority.Action.Value] = 3,
	[Enum.AnimationPriority.Movement.Value] = 4,
	[Enum.AnimationPriority.Idle.Value] = 5,
	[Enum.AnimationPriority.Core.Value] = 6,
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function getDescendants(var2)
	local descendants = { var2 }
	local cursor = 1
	
	while descendants[cursor] do
		local current = descendants[cursor]
		for i, child in ipairs(current:GetChildren())do
			table.insert(descendants, child)
		end
		
		cursor = cursor + 1
	end
	
	return descendants
end

function Animator.new(rig)
	local motors = {}
	local motorAdded = function(motor)
		if not motor:IsA("Motor6D") or not motor.Part1 then return end
		
		motors[motor.Part1.Name] = {
			C0 = motor.C0,
			C1 = motor.C1,
			motor = motor,
			transform = CFrame.new(),
			weight = 1.0,
		}
	end
	
	for i, motor in ipairs(getDescendants(rig)) do
		motorAdded(motor)
	end
	
	local connection = rig.DescendantAdded:Connect(function(motor)
		motorAdded(motor)
	end)
	
	return {
		connection = connection,
		motors = motors,
		cache = {},
		animations = {},
	}
end

function Animator.cloneTrack(anim)
	return {
		looped = anim.looped,
		priority = anim.priority,
		maxWeight = 1.0,
		length = anim.length,
		fadein = anim.fadein,
		fadeout = anim.fadeout,
		poses = anim.poses
	}	
end

function Animator.loadAnimation(track)
	-- copies the animation so we dont accidentally
	-- override the actual track info
	
	local cursor = 0
	local pop = function()
		cursor = cursor + 1
		return track[cursor]
	end
	
	local looped, priority = pop() == 1, pop()
	local length = pop()
	local fadein, fadeout = pop(), pop()
	local numPoses = pop()
	
	local poses = {}
	for i = 1, numPoses do
		local name = pop()
		local numSubposes = pop()
		
		local pose = {}
		poses[name] = pose
		
		for j = 1, numSubposes do
			local timer = pop()
			local cframe = CFrame.new(pop(), pop(), pop(), pop(), pop(), pop(), pop())
			local weight = pop()
			local easing = pop()
			local direction = pop()
			
			table.insert(pose, {
				cframe = cframe,
				weight = weight,
				easing = Tween[easing][direction],
				timer = timer,
			})
		end
	end
	
	return {
		looped = looped,
		priority = Priorities[priority],
		maxWeight = 1.0,
		length = length,
		fadein = fadein,
		fadeout = fadeout,
		poses = poses
	}
end

function Animator.commitPose(a, name, cframe, weight)
	-- sum w_i c W mix(I, cframe, w_i)
	local motor = a.motors[name]
	if not motor then return end
	local var1 = motor.weight - math.max(motor.weight - weight, 0.0)
	motor.transform = CFrame.new():Lerp(cframe, var1) * motor.transform
	motor.weight = motor.weight - var1
end

function Animator.stopTrack(a, track, fadeout)
	track.fading = os.clock()
	track.fadeout = fadeout or track.fadeout
end

function Animator.playTrack(a, track, fadein, maxWeight)
	local idx = table.find(a.animations, track)
	track.fading = math.huge
	track.fadein = fadein or track.fadein
	track.maxWeight = maxWeight or 1.0
	
	if idx then return end
	track.begin = os.clock()
	
	table.insert(a.animations, track)
	table.sort(a.animations, function(b, c) return b.priority < c.priority end)
end

function Animator.stepTrack(a, track)
	assert(track.begin, "track(): must have begin")
	assert(track.fadein, "track(): must have fadein")
	assert(track.fadeout, "track(): must have fadeout")
	assert(track.length, "track(): must have length")
	
	local t = os.clock() - track.begin
	local weight = 1.0
	
	if t < track.fadein then
		weight = t / track.fadein
	elseif t > track.length - track.fadeout and not track.looped then
		weight = (track.length - t) / track.fadeout
	end
	
	if track.fading ~= math.huge then
		weight = math.min((track.fading + track.fadeout - os.clock()) / track.fadeout, weight)
		if weight < 0.0 then return true end
	end
	
	local currentT = t % track.length
	weight = weight * track.maxWeight
	for name, keyframes in pairs(track.poses) do
		local i, span = 1, #keyframes
		while span > 1 do
			span = math.floor((span + 1) * 0.5)
			
			local desired = i + span
			if desired <= #keyframes and keyframes[desired].timer < currentT then
				 i = desired
			end
		end
		
		local prev = keyframes[i]
		local curr = keyframes[i + 1]
		
		if curr then
			local dt = math.abs(curr.timer - prev.timer)
			local alpha = prev.easing(math.min((currentT - prev.timer) / dt, 1.0))
			Animator.commitPose(
				a, name,
				prev.cframe:Lerp(curr.cframe, alpha),
				weight * lerp(prev.weight, curr.weight, alpha)
			)
		else
			Animator.commitPose(
				a, name,
				prev.cframe,
				weight * prev.weight
			)
		end
	end
	
	return t >= track.length and not track.looped
end

function Animator.update(a)
	local removeList = {}
	for i = 1, #a.animations do
		if Animator.stepTrack(a, a.animations[i]) then
			table.insert(removeList, i)
		end
	end
	
	for i = #removeList, 1, -1 do
		table.remove(a.animations, removeList[i])
	end
	
	-- Update motors
	for name, motor in pairs(a.motors) do
		-- part0 * C0 * Transform = part1 * C1
		if USE_TRANSFORM then
			motor.motor.Transform = motor.transform
		else
			motor.motor.C0 = motor.C0 * motor.transform
		end
		
		motor.weight = 1.0
		motor.transform = CFrame.new()
	end
end

return Animator
