local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Network = require(RS.Network)
local EnemyConfig = require(SS.Configs.EnemyConfig)
local Helper = require(RS.Utils.Helper)

local Logic = {}

function Logic.Fire(tower, target, waveSystem)
	local config = tower.Config
	local levelConfig = config.Levels[tower.Level]
	local damageType = config.DamageType or "Physical"
	local towerPos = tower.Instance:GetPivot().Position
	local radius = levelConfig.Range
	local hitCount = 0

	-- AoE Damage Logic (Centered on Tower for Potato)
	for _, mob in ipairs(Workspace:GetChildren()) do
		if mob:GetAttribute("IsMob") then
			local humanoid = mob:FindFirstChildOfClass("Humanoid")
			local hrp = mob:FindFirstChild("HumanoidRootPart")

			if humanoid and hrp then
				local dist = Helper.getDistance2D(hrp.Position, towerPos)
				if dist <= radius then
					local isCrit = math.random(1, 100) <= (levelConfig.CritRate or 0)
					local finalDamage = levelConfig.Damage * (if isCrit then (levelConfig.CritMulti or 2) else 1)

					humanoid:TakeDamage(finalDamage)

					-- Reward logic
					local enemyCfg = EnemyConfig[mob.Name]
					if enemyCfg then
						local rewardPerDamage = enemyCfg.Reward / enemyCfg.Health
						waveSystem:AddCoins(finalDamage * rewardPerDamage)
					end

					-- Broadcast Damage Visual
					Network.ShowDamage:FireAllClients({
						TargetPosition = hrp.Position,
						Damage = finalDamage,
						IsCrit = isCrit,
						DamageType = damageType,
					})

					hitCount += 1
				end
			end
		end
	end

	if hitCount > 0 then
		-- print(`[Potato Logic] Attack hit {hitCount} targets`)

		-- Visuals (Only show if hit something)
		Network.TowerShoot:FireAllClients({
			From = Helper.getTowerCenter(tower.Instance),
			To = Helper.getTowerBase(tower.Instance),
			TowerName = config.Name,
			TowerInstance = tower.Instance,
			Radius = radius,
		})
	end
end

return Logic
