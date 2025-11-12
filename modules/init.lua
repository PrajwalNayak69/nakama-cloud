local nk = require("nakama")

nk.logger_info("🚀 Initializing Tic-Tac-Toe runtime module")

-- Load the match module to verify it works
local success, match_module = pcall(require, "tic_tac_toe")
if success then
    nk.logger_info("✅ tic_tac_toe module loaded successfully")
else
    nk.logger_error("❌ Failed to load tic_tac_toe module: " .. tostring(match_module))
end

-- RPC: Create a Tic-Tac-Toe match (for direct creation)
local function rpc_create_match(context, payload)
    nk.logger_info("🎮 RPC called to create Tic-Tac-Toe match")
    
    -- Create an authoritative match using the tic_tac_toe module
    local match_id = nk.match_create("tic_tac_toe", {})
    
    nk.logger_info(("✅ Match created with ID: %s"):format(match_id))
    
    return nk.json_encode({ match_id = match_id })
end

-- Matchmaker matched callback - called when players are matched
local function matchmaker_matched(context, matched_users)
    nk.logger_info(("🎯 Matchmaker matched %d players"):format(#matched_users))
    
    -- Create a new authoritative match
    local match_id = nk.match_create("tic_tac_toe", {})
    
    nk.logger_info(("✅ Created match %s for matched players"):format(match_id))
    
    return match_id
end

-- Register the RPC and matchmaker callback
nk.register_rpc(rpc_create_match, "create_tictactoe_match")
nk.register_matchmaker_matched(matchmaker_matched)

nk.logger_info("✅ RPC 'create_tictactoe_match' registered")
nk.logger_info("✅ Matchmaker callback registered")
nk.logger_info("✅ Runtime initialization complete")