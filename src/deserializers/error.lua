local bin = require "plc52.bin"
local Reader = require("lightning-dissector.utils").Reader
local OrderedDict = require("lightning-dissector.utils").OrderedDict

function deserialize(payload)
  local reader = Reader:new(payload)

  local packed_channel_id = reader:read(32)
  local packed_len = reader:read(2)
  local len = string.unpack(">I2", packed_len)
  local data = reader:read(len)

  return OrderedDict:new(
    "channel_id", bin.stohex(packed_channel_id),
    "len", OrderedDict:new(
      "Raw", bin.stohex(packed_len),
      "Deserialized", len
    ),
    "data", OrderedDict:new(
      "Raw", bin.stohex(data),
      "Deserialized", data
    )
  )
end

return {
  number = 17,
  name = "error",
  deserialize = deserialize
}
