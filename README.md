# retro-animator
old animation system i guess

## initialization
```lua
-- Some server script to initialize the replication system
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Replicator"))
```

## animate example
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animator = require(ReplicatedStorage:WaitForChild("Replicator"))

local Figure = script.Parent
local Humanoid = Figure:WaitForChild("Humanoid")

local function running(speed)
	if speed > 0.5 then
		Animator.localPlayTrack("Walk")
		Animator.localStopTrack("Idle", 0.5)
	else
		Animator.localPlayTrack("Idle", 0.4)
		Animator.localStopTrack("Walk", 0.4)
	end
end

local function freefalling(active)
	if not active then return Animator.localStopTrack("Fall", 0.1) end
	Animator.localStopTrack("Idle", 0.1)
	Animator.localStopTrack("Walk", 0.1)
	Animator.localPlayTrack("Fall", 0.4)
end

local function jumping(active)
	if not active then return end
	Animator.localPlayTrack("Jump", 0.1)
end

Humanoid.Running:Connect(running)
Humanoid.FreeFalling:Connect(freefalling)
Humanoid.Jumping:Connect(jumping)
```
