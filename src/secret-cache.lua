local class = require "middleclass"

local SecretCachePerPdu = class("SecretCachePerPdu")

function SecretCachePerPdu:initialize(secret_factory)
  self.secret_factory = secret_factory
  self.secrets = {}
end

function SecretCachePerPdu:find_or_create(pinfo, buffer)
  local length_mac = buffer:raw(2, 16)
  local secret_for_pdu = self.secrets[length_mac]

  if secret_for_pdu == "NOT FOUND" then
    return
  end

  if secret_for_pdu ~= nil then
    return secret_for_pdu:clone()
  end

  local secret_for_node = self.secret_factory:find_or_create(pinfo, buffer)
  if secret_for_node ~= nil then
    self.secrets[length_mac] = secret_for_node:clone()
    return secret_for_node
  end

  self.secrets[length_mac] = "NOT FOUND"
end

function SecretCachePerPdu:delete(cache_key)
  self.secrets[cache_key] = nil
end

return {
  SecretCachePerPdu = SecretCachePerPdu
}