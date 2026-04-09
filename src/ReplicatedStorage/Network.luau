local RS = game:GetService("ReplicatedStorage")
local ByteNet = require(RS.Packages.ByteNet)

local packets = ByteNet.defineNamespace("PlayerStorageNetworks", function()
	return {
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
	}
end)

return packets
