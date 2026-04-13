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

local NetType = {
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
			Cash = NetType.Number,
		},
	}),
	RequestCash = getOrRegisterEvent("RequestCash", {
		typeDefinition = {
			Req = NetType.Number,
		},
	}),
	-- Wave
	UpdateWave = getOrRegisterEvent("UpdateWave", {
		typeDefinition = {
			Wave = NetType.Number,
			IsRunning = NetType.Boolean,
			Countdown = NetType.Number,
		},
	}),
	RequestWave = getOrRegisterEvent("RequestWave", {
		typeDefinition = {
			Req = NetType.Number,
		},
	}),
	RequestNextWave = getOrRegisterEvent("RequestNextWave", {
		typeDefinition = {
			Req = NetType.Number,
		},
	}),
	-- Game State
	UpdateBaseHealth = getOrRegisterEvent("UpdateBaseHealth", {
		typeDefinition = {
			Health = NetType.Number,
			MaxHealth = NetType.Number,
		},
	}),
	GameOver = getOrRegisterEvent("GameOver", {
		typeDefinition = {
			Won = NetType.Boolean,
			Reset = NetType.Boolean,
		},
	}),
	RestartGame = getOrRegisterEvent("RestartGame", {
		typeDefinition = {
			Req = NetType.Number,
		},
	}),
	UpdateCoins = getOrRegisterEvent("UpdateCoins", {
		typeDefinition = {
			Coins = NetType.Number,
		},
	}),
	PlaceTower = getOrRegisterEvent("PlaceTower", {
		typeDefinition = {
			TowerName = NetType.String,
			Position = NetType.Vector3,
		},
	}),
	UpdateOwnedTowers = getOrRegisterEvent("UpdateOwnedTowers", {
		typeDefinition = {
			Towers = NetType.String,
		},
	}),
	RequestOwnedTowers = getOrRegisterEvent("RequestOwnedTowers", {
		typeDefinition = {
			Req = NetType.Number,
		},
	}),
	TowerShoot = getOrRegisterEvent("TowerShoot", {
		typeDefinition = {
			From = NetType.Vector3,
			To = NetType.Vector3,
			TowerName = NetType.String,
			TowerInstance = NetType.Instance,
		},
	}),
	Notify = getOrRegisterEvent("Notify", {
		typeDefinition = {
			Message = NetType.String,
			Type = NetType.String, -- "Info", "Error", "Success"
		},
	}),
	RequestUpgrade = getOrRegisterEvent("RequestUpgrade", {
		typeDefinition = {
			TowerInstance = NetType.Instance,
		},
	}),
}
