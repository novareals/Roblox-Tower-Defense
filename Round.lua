local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local events = ReplicatedStorage:WaitForChild("Events")

local mob = require(script.Parent.Mob)
local info = workspace.Info

local round = {}
local votes = {}

-- Shortcut to wait with speed multiplier
local function SpeedWait(duration)
	local speed = info:FindFirstChild("SpeedMultiplier")
	local mult = (speed and speed.Value > 0) and speed.Value or 1
	task.wait(duration / mult)
end

function round.StartGame()
	if info.GameRunning.Value == true then return end

	local map = round.LoadMap()
	info.GameRunning.Value = true

	for i = 3, 0, -1 do
		info.Message.Value = "Game starting in... " .. i
		SpeedWait(1)
	end

	for wave = 1, 30 do
		if not info.GameRunning.Value then break end

		info.Wave.Value = wave
		info.Message.Value = ""

		round.GetWave(wave, map)

		repeat
			SpeedWait(1)
		until #workspace.Mobs:GetChildren() == 0 or not info.GameRunning.Value

		if not info.GameRunning.Value then
			break
		end

		if wave == 30 then
			info.Message.Value = "YOU WIN! Final wave complete!"
			SpeedWait(5)
			break
		end

		-- Give reward
		local reward = 25 * math.round(wave / 2) -- Nerfed
		for _, player in ipairs(Players:GetPlayers()) do
			if player:FindFirstChild("Gold") then
				player.Gold.Value += reward
			end
		end

		info.Message.Value = "Wave Reward: $" .. reward
		SpeedWait(2)

		for i = 5, 0, -1 do
			info.Message.Value = "Next wave starting in... " .. i
			SpeedWait(1)
		end
	end

	info.GameRunning.Value = false
	info.Message.Value = "Game ended. Returning to lobby..."
	SpeedWait(3)
	round.CleanupMap()
end

function round.LoadMap()
	local votedMap = round.ToggleVoting()
	local mapFolder = ServerStorage.Maps:FindFirstChild(votedMap) or ServerStorage.Maps.Grassland
	local newMap = mapFolder:Clone()
	newMap.Parent = workspace.Map

	if workspace.SpawnBox:FindFirstChild("Floor") then
		workspace.SpawnBox.Floor:Destroy()
	end

	newMap.Base.Humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			info.GameRunning.Value = false
			info.Message.Value = "GAME OVER"
		end
	end)

	return newMap
end

function round.CleanupMap()
	for _, child in pairs(workspace.Map:GetChildren()) do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
end

function round.ToggleVoting()
	local maps = ServerStorage.Maps:GetChildren()
	votes = {}
	for _, map in ipairs(maps) do
		votes[map.Name] = {}
	end

	info.Voting.Value = true

	for i = 10, 1, -1 do
		info.Message.Value = "Map voting (" .. i .. ")"
		SpeedWait(1)
	end

	local winVote, winScore = nil, 0
	for name, mapVotes in pairs(votes) do
		if #mapVotes > winScore then
			winScore = #mapVotes
			winVote = name
		end
	end

	if not winVote then
		winVote = maps[math.random(#maps)].Name
	end

	info.Voting.Value = false
	return winVote
end

function round.ProcessVote(player, vote)
	for name, mapVotes in pairs(votes) do
		local oldVote = table.find(mapVotes, player.UserId)
		if oldVote then
			table.remove(mapVotes, oldVote)
			break
		end
	end

	table.insert(votes[vote], player.UserId)
	events:WaitForChild("UpdateVoteCount"):FireAllClients(votes)
end

events:WaitForChild("VoteForMap").OnServerEvent:Connect(round.ProcessVote)

-- Nerfed wave counts
function round.GetWave(wave, map)
	local z = function(n) return math.max(1, math.floor(n)) end

	if wave <= 2 then
		mob.Spawn("Zombie", z(wave), map)

	elseif wave <= 4 then
		for i = 1, 2 do
			mob.Spawn("Zombie", z(wave), map)
			mob.Spawn("Noob", z(wave * 0.3), map)
		end

	elseif wave <= 7 then
		for i = 1, 2 do
			mob.Spawn("Zombie", z(wave * 0.5), map)
			mob.Spawn("Mech", z(wave * 0.4), map)
		end

	elseif wave <= 10 then
		mob.Spawn("Teddy", 1, map)
		for i = 1, 3 do
			mob.Spawn("Zombie", z(wave * 0.4), map)
			mob.Spawn("Noob", z(wave * 0.4), map)
		end

	elseif wave <= 15 then
		for i = 1, 3 do
			mob.Spawn("Zombie", z(wave * 0.7), map)
			mob.Spawn("Mech", z(wave * 0.4), map)
			if i == 3 then mob.Spawn("Teddy", 1, map) end
		end

	elseif wave <= 20 then
		for i = 1, 4 do
			mob.Spawn("Zombie", z(wave * 0.6), map)
			mob.Spawn("Mech", z(wave * 0.6), map)
			mob.Spawn("Noob", z(wave * 0.5), map)
		end

	elseif wave <= 25 then
		for i = 1, 4 do
			mob.Spawn("Zombie", z(wave * 0.8), map)
			mob.Spawn("Teddy", z(wave / 10), map)
		end

	elseif wave < 30 then
		for i = 1, 5 do
			mob.Spawn("Mech", z(wave * 0.7), map)
			mob.Spawn("Teddy", z(wave / 8), map)
		end

	elseif wave == 30 then
		mob.Spawn("Zombie", 40, map)
		for i = 1, 5 do
			mob.Spawn("Mech", 5, map)
			mob.Spawn("Teddy", 2, map)
		end
	end
end

return round
