local RS = game:GetService("ReplicatedStorage")
local ByteNet = require(RS.Packages.ByteNet)

local packets = ByteNet.defineNamespace("PlayerStorageNetworks", function()
	return {
		-- Cash
		UpdateCash = ByteNet.definePacket({
			value = ByteNet.struct({
				Cash = ByteNet.int32,
			}),
			reliability = "reliable",
		}),
		RequestCash = ByteNet.definePacket({
			value = ByteNet.struct({
				Req = ByteNet.uint8,
			}),
			reliability = "reliable",
		}),
		-- Wave
		UpdateWave = ByteNet.definePacket({
			value = ByteNet.struct({
				Wave = ByteNet.int16,
				IsRunning = ByteNet.bool,
				Countdown = ByteNet.int8,
			}),
			reliability = "reliable",
		}),
		RequestWave = ByteNet.definePacket({
			value = ByteNet.struct({
				Req = ByteNet.uint8,
			}),
			reliability = "reliable",
		}),
		RequestNextWave = ByteNet.definePacket({
			value = ByteNet.struct({
				Req = ByteNet.uint8,
			}),
			reliability = "reliable",
		}),
		-- Game State
		UpdateBaseHealth = ByteNet.definePacket({
			value = ByteNet.struct({
				Health = ByteNet.int16,
				MaxHealth = ByteNet.int16,
			}),
			reliability = "reliable",
		}),
		GameOver = ByteNet.definePacket({
			value = ByteNet.struct({
				Won = ByteNet.bool,
				Reset = ByteNet.bool,
			}),
			reliability = "reliable",
		}),
		RestartGame = ByteNet.definePacket({
			value = ByteNet.struct({
				Req = ByteNet.uint8,
			}),
			reliability = "reliable",
		}),
		UpdateCoins = ByteNet.definePacket({
			value = ByteNet.struct({
				Coins = ByteNet.int32,
			}),
			reliability = "reliable",
		}),
	}
end)

return packets
