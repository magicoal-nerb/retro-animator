local ScriptEditorService = game:GetService("ScriptEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

local function writeCFrame(cframe: CFrame): string
	local axis, angle = cframe:ToAxisAngle()
	local im = axis:Dot(axis) < 1e-6 and Vector3.zero or axis.Unit * math.sin(angle * 0.5)
	local re = math.cos(angle * 0.5)

	return string.format("%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,",
		cframe.X, cframe.Y, cframe.Z, im.X, im.Y, im.Z, re)
end

local function writeFloat(f: number): string
	return string.format("%.4f,", f)
end

local function writeInt(f: number): string
	return string.format("%d,", f)
end

local function writeString(f: string): string
	return `"{f}",`
end

local function exportAnimation(sequence: KeyframeSequence): string
	local concat = {}
	local keyframes = sequence:GetKeyframes()
	table.sort(keyframes, function(a: Keyframe, b: Keyframe)
		return a.Time < b.Time
	end)

	local data = {}
	local length = 0.0
	local count = 0

	for i, keyframe in keyframes do
		length = math.max(length, keyframe.Time)
		for j, pose in keyframe:GetDescendants() do
			if not pose:IsA("Pose") then continue end
			local name = pose.Name
			if data[name] then
				table.insert(data[name], {
					timer = keyframe.Time,
					cframe = pose.CFrame,
					easing = pose.EasingStyle,
					direction = pose.EasingDirection,
					weight = pose.Weight,
				})
			else
				count += 1
				data[name] = {{
					timer = keyframe.Time,
					cframe = pose.CFrame,
					easing = pose.EasingStyle,
					direction = pose.EasingDirection,
					weight = pose.Weight,
				}}
			end
		end
	end
	
	local concat = { }
	table.insert(concat, writeInt(sequence.Loop and 1 or 0))
	table.insert(concat, writeInt(sequence.Priority.Value))
	table.insert(concat, writeFloat(length - 1/100))
	table.insert(concat, writeFloat(0.2))
	table.insert(concat, writeFloat(0.2))
	
	table.insert(concat, writeInt(count))
	table.insert(concat, '\n')
	
	local num = 0
	for name, poses in data do
		table.insert(concat, writeString(name))
		table.insert(concat, writeInt(#poses))
		
		for i, pose in poses do
			num += 1
			table.insert(concat, writeFloat(pose.timer))
			table.insert(concat, writeCFrame(pose.cframe))
			table.insert(concat, writeFloat(pose.weight))
			table.insert(concat, writeInt(pose.easing.Value))
			table.insert(concat, writeInt(pose.direction.Value))
			if num % 20 == 0 then
				table.insert(concat, '\n')
			end
		end
	end

	return `return \{{table.concat(concat)}\}`
end

for i, animation in Selection:Get() do
	local module = Instance.new("ModuleScript", workspace)
	module.Name = animation.Name

	ScriptEditorService:UpdateSourceAsync(module, function()
		return exportAnimation(animation)
	end)
end
