local OrderedDict = require("lightning-dissector.utils").OrderedDict
local bin = require "plc52.bin"
local constants = require "lightning-dissector.constants"

local deserializers = {
  require("lightning-dissector.deserializers.init"),
  require("lightning-dissector.deserializers.ping"),
  require("lightning-dissector.deserializers.pong"),
  require("lightning-dissector.deserializers.error"),
  require("lightning-dissector.deserializers.channel-announcement"),
  require("lightning-dissector.deserializers.channel-update"),
  require("lightning-dissector.deserializers.node-announcement"),
  require("lightning-dissector.deserializers.open-channel"),
  require("lightning-dissector.deserializers.accept-channel"),
  require("lightning-dissector.deserializers.funding-created"),
  require("lightning-dissector.deserializers.channel-reestablish"),
  require("lightning-dissector.deserializers.funding-signed"),
  require("lightning-dissector.deserializers.funding-locked"),
  require("lightning-dissector.deserializers.shutdown"),
  require("lightning-dissector.deserializers.closing-signed"),
  require("lightning-dissector.deserializers.update-add-htlc"),
  require("lightning-dissector.deserializers.update-fulfill-htlc"),
  require("lightning-dissector.deserializers.update-fail-htlc"),
  require("lightning-dissector.deserializers.update-fail-malformed-htlc"),
  require("lightning-dissector.deserializers.commitment-signed"),
  require("lightning-dissector.deserializers.revoke-and-ack"),
  require("lightning-dissector.deserializers.update-fee"),
  require("lightning-dissector.deserializers.announcement-signatures"),
  require("lightning-dissector.deserializers.query-short-channel-ids"),
  require("lightning-dissector.deserializers.reply-short-channel-ids-end"),
  require("lightning-dissector.deserializers.query-channel-range"),
  require("lightning-dissector.deserializers.reply-channel-range"),
  require("lightning-dissector.deserializers.gossip-timestamp-filter")
}

local function find_deserializer_for(type)
  for _, deserializer in ipairs(deserializers) do
    if deserializer.number == type then
      return deserializer
    end
  end
end

local function deserialize(packed_payload)
  local packed_type = packed_payload:sub(1, 2)
  local type = string.unpack(">I2", packed_type)
  local payload = packed_payload:sub(3)

  local deserializer = find_deserializer_for(type)
  if deserializer == nil then
    return OrderedDict:new(
      "Type", OrderedDict:new(
        constants.fields.payload.deserialized.type.raw, bin.stohex(packed_type),
        constants.fields.payload.deserialized.type.number, type
      )
    )
  end

  local result = OrderedDict:new(
    "Type", OrderedDict:new(
      constants.fields.payload.deserialized.type.raw, bin.stohex(packed_type),
      constants.fields.payload.deserialized.type.name, deserializer.name,
      constants.fields.payload.deserialized.type.number, type
    )
  )

  local deserialized = deserializer.deserialize(payload)
  for key, value in pairs(deserialized) do
    result:append(key, value)
  end

  return result, deserializer.name
end

local function analyze_length(buffer, secret)
  local packed_encrypted = buffer():raw(0, constants.lengths.length)
  local packed_mac = buffer():raw(constants.lengths.length, constants.lengths.length_mac)
  local packed_decrypted = secret:decrypt(packed_encrypted, packed_mac)
  local deserialized = string.unpack(">I2", packed_decrypted)

  return {
    packed_encrypted = packed_encrypted,
    packed_mac = packed_mac,
    packed_decrypted = packed_decrypted,
    deserialized = deserialized,
    display = function()
      return OrderedDict:new(
        constants.fields.length.encrypted, bin.stohex(packed_encrypted),
        constants.fields.length.decrypted, bin.stohex(packed_decrypted),
        constants.fields.length.deserialized, deserialized,
        constants.fields.length.mac, bin.stohex(packed_mac)
      )
    end
  }
end

local function analyze_payload(buffer, secret)
  local payload_length = buffer:len() - constants.lengths.footer
  local packed_encrypted = buffer:raw(0, payload_length)
  local packed_mac = buffer:raw(payload_length, constants.lengths.payload_mac)
  local packed_decrypted = secret:decrypt(packed_encrypted, packed_mac)
  local deserialized, type = deserialize(packed_decrypted)

  return {
    packed_encrypted = packed_encrypted,
    packed_mac = packed_mac,
    packed_decrypted = packed_decrypted,
    type = type,
    display = function()
      return OrderedDict:new(
        constants.fields.payload.encrypted, bin.stohex(packed_encrypted),
        constants.fields.payload.mac, bin.stohex(packed_mac),
        constants.fields.payload.decrypted, bin.stohex(packed_decrypted),
        "Deserialized", deserialized
      )
    end
  }
end

return {
  analyze_length = analyze_length,
  analyze_payload = analyze_payload
}
