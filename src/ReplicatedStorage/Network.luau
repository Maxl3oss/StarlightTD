local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NetRay = require(RS.Packages.NetRay)

local isServer = RunService:IsServer()

local function getOrRegisterEvent(eventName, config)
	if isServer then
		return NetRay:RegisterEvent(eventName, config)
	else
		return NetRay:GetEvent(eventName)
	end
end

local type = {
	Number = "number",
	String = "string",
	Boolean = "boolean",
	Vector3 = "Vector3",
	CFrame = "CFrame",
	UDim2 = "UDim2",
	Color3 = "Color3",
	BrickColor = "BrickColor",
	Enum = "Enum",
	Instance = "Instance",
	Table = "table",
	Function = "function",
	Thread = "thread",
	Any = "any",
}

return {
	-- Cash
	UpdateCash = getOrRegisterEvent("UpdateCash", {
		typeDefinition = {
			Cash = type.Number,
		},
	}),
	RequestCash = getOrRegisterEvent("RequestCash", {
		typeDefinition = {
			Req = type.Number,
		},
	}),
	-- Wave
	UpdateWave = getOrRegisterEvent("UpdateWave", {
		typeDefinition = {
			Wave = type.Number,
			IsRunning = type.Boolean,
			Countdown = type.Number,
		},
	}),
	RequestWave = getOrRegisterEvent("RequestWave", {
		typeDefinition = {
			Req = type.Number,
		},
	}),
	RequestNextWave = getOrRegisterEvent("RequestNextWave", {
		typeDefinition = {
			Req = type.Number,
		},
	}),
	-- Game State
	UpdateBaseHealth = getOrRegisterEvent("UpdateBaseHealth", {
		typeDefinition = {
			Health = type.Number,
			MaxHealth = type.Number,
		},
	}),
	GameOver = getOrRegisterEvent("GameOver", {
		typeDefinition = {
			Won = type.Boolean,
			Reset = type.Boolean,
		},
	}),
	RestartGame = getOrRegisterEvent("RestartGame", {
		typeDefinition = {
			Req = type.Number,
		},
	}),
	UpdateCoins = getOrRegisterEvent("UpdateCoins", {
		typeDefinition = {
			Coins = type.Number,
		},
	}),
	PlaceTower = getOrRegisterEvent("PlaceTower", {
		typeDefinition = {
			TowerName = type.String,
			Position = type.Vector3,
		},
	}),
	UpdateOwnedTowers = getOrRegisterEvent("UpdateOwnedTowers", {
		typeDefinition = {
			Towers = type.String,
		},
	}),
	RequestOwnedTowers = getOrRegisterEvent("RequestOwnedTowers", {
		typeDefinition = {
			Req = type.Number,
		},
	}),
	TowerShoot = getOrRegisterEvent("TowerShoot", {
		typeDefinition = {
			From = type.Vector3,
			To = type.Vector3,
		},
	}),
}
