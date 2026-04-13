local ProfileStoreSystem = {}
ProfileStoreSystem.__index = ProfileStoreSystem

-- import
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local Network = require(RS.Network)

local ProfileStore = require(SS.Packages.ProfileStore)
local Players = game:GetService("Players")
local PlayerProfileStore = ProfileStore.New("PlayerStore", require(SS.Configs.ProfileConfig))

-- config
local Profiles: { [Player]: typeof(PlayerProfileStore:StartSessionAsync()) } = {}

-- Debugging
local DEBUG = false
local function print(msg: string)
	if DEBUG then
		warn(`[ProfileStoreSystem]: {msg}`)
	end
end

-- ========== Init ==========
function ProfileStoreSystem:Init()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:PlayerAdded(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		self:PlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:PlayerRemoving(player)
	end)

	Network.RequestCash:OnEvent(function(player, data)
		local profile = Profiles[player]
		if profile then
			Network.UpdateCash:FireClient(player, {
				Cash = tonumber(profile.Data.Cash) or 0,
			})
		end
	end)

	Network.RequestOwnedTowers:OnEvent(function(player, data: { Req: number })
		self:SyncTowers(player)
	end)
end

function ProfileStoreSystem:GetProfile(player: Player)
	return Profiles[player]
end

function ProfileStoreSystem:GetData(player: Player)
	local profile = Profiles[player]
	return profile and profile.Data
end

function ProfileStoreSystem:PlayerAdded(player: Player)
	local profile = PlayerProfileStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Handling new profile session or failure to start it:
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick(`Profile session end - Please rejoin`)
		end)

		if player.Parent == Players then
			Profiles[player] = profile

			print(`Profile loaded for {player.DisplayName}!`)

			profile.Data.Cash = (profile.Data.Cash or 0)
			player:SetAttribute("DataLoaded", true)

			local cash = profile.Data.Cash
			Network.UpdateCash:FireClient(player, {
				Cash = tonumber(cash) or 0,
			})

			self:SyncTowers(player)
		else
			profile:EndSession()
		end
	else
		player:Kick(`Profile load fail - Please rejoin`)
	end
end

function ProfileStoreSystem:PlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end
-- ========== Init ==========

-- ========== Cash player ==========
function ProfileStoreSystem:AddCash(player: Player, amount: number)
	local profile = self:GetProfile(player)
	if profile ~= nil then
		profile.Data.Cash = (profile.Data.Cash or 0) + amount
		Network.UpdateCash:FireClient(player, {
			Cash = tonumber(profile.Data.Cash) or 0,
		})
	end
end

function ProfileStoreSystem:RemoveCash(player: Player, amount: number)
	local profile = self:GetProfile(player)
	if profile ~= nil then
		profile.Data.Cash = (profile.Data.Cash or 0) - amount
		Network.UpdateCash:FireClient(player, {
			Cash = tonumber(profile.Data.Cash) or 0,
		})
	end
end

function ProfileStoreSystem:GetCash(player: Player)
	local profile = self:GetProfile(player)
	return profile and profile.Data.Cash
end
-- ========== Cash player ==========

function ProfileStoreSystem:SyncTowers(player: Player)
	local profile = self:GetProfile(player)
	if profile and profile.Data.Towers then
		local towerString = table.concat(profile.Data.Towers, ",")
		Network.UpdateOwnedTowers:FireClient(player, {
			Towers = towerString,
		})
		print(`Synced towers for {player.Name}: {towerString}`)
	end
end

return ProfileStoreSystem
