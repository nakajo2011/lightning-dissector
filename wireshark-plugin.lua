local SecretCache = require("lightning-dissector.secret-manager").SecretCache
local CompositeSecretManager = require("lightning-dissector.secret-manager").CompositeSecretManager
local KeyLogManager = require("lightning-dissector.secret-manager").KeyLogManager
local PduAnalyzer = require "lightning-dissector.pdu-analyzer"

local pdu_analyzer = PduAnalyzer:new(
  SecretCache:new(
    CompositeSecretManager:new(
      KeyLogManager:new()
    )
  )
)

local function display(tree, analyzed_frame)
  for key, value in pairs(analyzed_frame) do
    if type(value) == "table" then
      local subtree = tree:add(key .. ":")
      display(subtree, value)
    else
      tree:add(key .. ": " .. value)
    end
  end
end

local protocol = Proto("lightning", "Lightning Network")
function protocol.dissector(buffer, pinfo, tree)
  pinfo.cols.protocol = "Lightning Network"

  local analyzed_frame = pdu_analyzer:analyze(pinfo, buffer)
  local subtree = tree:add(protocol, "Lightning Network")
  display(subtree, analyzed_frame)
end

DissectorTable.get("tcp.port"):add(9000, protocol)
