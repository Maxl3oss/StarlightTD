local RS = game:GetService("ReplicatedStorage")
local ByteNet = require(RS.Packages.ByteNet)

local packets = ByteNet.defineNamespace("PlayerStorageNetworks", function(types)
	return {
		-- Cash
		UpdateCash = ByteNet.definePacket({
			value = types.struct({
				Cash = types.int32,
			}),
			reliability = "reliable",
		}),
		RequestCash = ByteNet.definePacket({
			value = types.struct({
				Req = types.uint8,
			}),
			reliability = "reliable",
		}),
		-- Wave
		UpdateWave = ByteNet.definePacket({
			value = types.struct({
				Wave = types.int16,
				IsRunning = types.bool,
				Countdown = types.int8,
			}),
			reliability = "reliable",
		}),
		RequestWave = ByteNet.definePacket({
			value = types.struct({
				Req = types.uint8,
			}),
			reliability = "reliable",
		}),
		RequestNextWave = ByteNet.definePacket({
			value = types.struct({
				Req = types.uint8,
			}),
			reliability = "reliable",
		}),
		-- Game State
		UpdateBaseHealth = ByteNet.definePacket({
			value = types.struct({
				Health = types.int16,
				MaxHealth = types.int16,
			}),
			reliability = "reliable",
		}),
		GameOver = ByteNet.definePacket({
			value = types.struct({
				Won = types.bool,
				Reset = types.bool,
			}),
			reliability = "reliable",
		}),
		RestartGame = ByteNet.definePacket({
			value = types.struct({
				Req = types.uint8,
			}),
			reliability = "reliable",
		}),
		UpdateCoins = ByteNet.definePacket({
			value = types.struct({
				Coins = types.int32,
			}),
			reliability = "reliable",
		}),
		PlaceTower = ByteNet.definePacket({
			value = types.struct({
				TowerName = types.string,
				Position = types.vec3,
			}),
			reliability = "reliable",
		}),
		UpdateOwnedTowers = ByteNet.definePacket({
			value = types.struct({
				Towers = types.string, -- Comma separated tower names
			}),
			reliability = "reliable",
		}),
		RequestOwnedTowers = ByteNet.definePacket({
			value = types.struct({
				Req = types.uint8,
			}),
			reliability = "reliable",
		}),
		TowerShoot = ByteNet.definePacket({
			value = types.struct({
				From = types.vec3,
				To = types.vec3,
			}),
			reliability = "unreliable",
		}),
	}
end)

return packets
