local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- enter your stuff here
local Animations = ReplicatedStorage:WaitForChild("animations")
local Animator = require(script.Parent.Animator)

local Replicate = RunService:IsClient() and script:WaitForChild("Replicate") or Instance.new("RemoteEvent", script)
Replicate.Name = "Replicate"

local Replicator = {}
local LoadedAnims = {}
local Animators = {}

local function animationAdded(what)
	LoadedAnims[what.Name] = Animator.loadAnimation(require(what))
end

local function tryGetAnimator(c)
	assert(c, "replicator(): character dont existy")
	if Animators[c] then
		return Animators[c]
	end
	
	Animators[c] = Animator.new(c)
	return Animators[c]
end

function Replicator.heartbeat(dt)
	for character, rig in pairs(Animators) do
		if not character.Parent then
			Animators[character] = nil
		else
			Animator.update(rig)
		end
	end
end

-- When we recieve stuff on the server
function Replicator.recieve(c, s, n, w)
	local char = c.Character
	for i, player in ipairs(Players:GetChildren()) do
		if player ~= c then
			Replicate:FireClient(player, char, s, n, w)
		end
	end
end

function Replicator.replicate(c, s, n, w)
	local anim = tryGetAnimator(c)
	if not anim then return end
	if s == 0 then
		-- Play animation
		if not anim.cache[n] then
			anim.cache[n] = Animator.cloneTrack(LoadedAnims[n])
		end
		Animator.playTrack(anim, anim.cache[n], w)
	elseif s == 1 and anim.cache[n] then
		-- Stop animation
		Animator.stopTrack(anim, anim.cache[n], w)
	end
end

-- Server sided stuff
function Replicator.playTrack(char, name, fadeIn)
	Replicate:FireAllClients(char, name, fadeIn)
end

function Replicator.stopTrack(char, name, fadeOut)
	Replicate:FireAllClients(char, name, fadeOut)
end

-- Local player stuff
function Replicator.localPlayTrack(name, fadeIn)
	Replicate:FireServer(0, name, fadeIn)
	Replicator.replicate(assert(Players.LocalPlayer).Character, 0, name, fadeIn)
end

function Replicator.localStopTrack(name, fadeOut)
	Replicate:FireServer(1, name, fadeOut)
	Replicator.replicate(assert(Players.LocalPlayer).Character, 1, name, fadeOut)
end

for i, animation in ipairs(Animations:GetChildren()) do
	animationAdded(animation)
end
Animations.ChildAdded:Connect(animationAdded)

if RunService:IsClient() then
	RunService.Heartbeat:Connect(Replicator.heartbeat)
	Replicate.OnClientEvent:Connect(Replicator.replicate)
else
	Replicate.OnServerEvent:Connect(Replicator.recieve)
end

return Replicator
