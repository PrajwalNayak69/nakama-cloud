local nk = require("nakama")

-- === OpCodes ===
local OP_CODE_MOVE = 1
local OP_CODE_STATE = 2

-- === Helper: Broadcast Game State ===
local function broadcast_state(dispatcher, state)
    local success, json_data = pcall(nk.json_encode, {
        board = state.board,
        players = state.players,
        turn = state.turn,
        winner = state.winner,
        started = state.started
    })

    if success then
        dispatcher.broadcast_message(OP_CODE_STATE, json_data, nil, nil)
    else
        nk.logger_error("❌ Failed to encode game state for broadcast")
    end
end

-- === Helper: Check for Winner ===
local function check_winner(board)
    local lines = {
        {1, 2, 3}, {4, 5, 6}, {7, 8, 9},  -- Rows
        {1, 4, 7}, {2, 5, 8}, {3, 6, 9},  -- Columns
        {1, 5, 9}, {3, 5, 7}              -- Diagonals
    }

    for _, line in ipairs(lines) do
        local a, b, c = line[1], line[2], line[3]
        if board[a] ~= "" and board[a] == board[b] and board[b] == board[c] then
            return board[a]
        end
    end

    return nil
end

-- === Helper: Check for Empty Cells ===
local function contains_empty(board)
    for _, cell in ipairs(board) do
        if cell == "" then return true end
    end
    return false
end

-- === Match Handlers ===
local function match_init(context, params)
    nk.logger_info("🎮 Initializing new Tic-Tac-Toe match")

    local state = {
        board = {"", "", "", "", "", "", "", "", ""},
        players = {},
        turn = 0,
        winner = nil,
        started = false
    }

    local tick_rate = 1
    local label = "tic_tac_toe_match"
    return state, tick_rate, label
end

local function match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    nk.logger_info(("👋 Join attempt from user %s"):format(presence.user_id))

    if #state.players >= 2 then
        nk.logger_info("❌ Match full, rejecting join.")
        return state, false, "Match full"
    end

    return state, true, ""
end

local function match_join(context, dispatcher, tick, state, presences)
    for _, presence in ipairs(presences) do
        table.insert(state.players, presence.user_id)
        nk.logger_info(("✅ Player joined: %s"):format(presence.user_id))
    end

    nk.logger_info(("👥 Current players: %s"):format(nk.json_encode(state.players)))

    if #state.players == 2 then
        state.started = true
        broadcast_state(dispatcher, state)
    else
        -- Send partial state to new player
        broadcast_state(dispatcher, state)
    end

    return state
end

local function match_leave(context, dispatcher, tick, state, presences)
    for _, presence in ipairs(presences) do
        for i = #state.players, 1, -1 do
            if state.players[i] == presence.user_id then
                table.remove(state.players, i)
                nk.logger_info(("👋 Player left: %s"):format(presence.user_id))
                break
            end
        end
    end

    if #state.players < 2 and state.started then
        state.winner = "abandoned"
        broadcast_state(dispatcher, state)
        nk.logger_info("⚠️ Match abandoned due to player leave")
    end

    return state
end

local function match_loop(context, dispatcher, tick, state, messages)
    for _, message in ipairs(messages) do
        if message.op_code ~= OP_CODE_MOVE then
            goto continue
        end

        local success, data = pcall(nk.json_decode, message.data)
        if not success or type(data.cell) ~= "number" then
            nk.logger_error("❌ Invalid move payload received")
            goto continue
        end

        local sender = message.sender.user_id
        local cell = data.cell
        local player_index = -1

        for i, player_id in ipairs(state.players) do
            if player_id == sender then
                player_index = i
                break
            end
        end

        if player_index == -1 then
            nk.logger_error("❌ Move from unknown player")
            goto continue
        end

        if player_index ~= state.turn + 1 then
            nk.logger_info("⏳ Not this player's turn")
            goto continue
        end

        if cell < 0 or cell > 8 then
            nk.logger_error("❌ Invalid cell index")
            goto continue
        end

        local cell_index = cell + 1
        if state.board[cell_index] ~= "" then
            nk.logger_info("❌ Cell already taken")
            goto continue
        end

        if state.winner ~= nil then
            nk.logger_info("⚠️ Game already ended")
            goto continue
        end

        -- Make move
        local markers = {"X", "O"}
        state.board[cell_index] = markers[player_index]
        nk.logger_info(("🎯 Player %d placed %s in cell %d"):format(player_index, markers[player_index], cell_index))

        -- Check winner or next turn
        local win = check_winner(state.board)
        if win ~= nil then
            state.winner = win
            nk.logger_info(("🏆 Winner found: %s"):format(win))
        elseif not contains_empty(state.board) then
            state.winner = "draw"
            nk.logger_info("🤝 Game ended in a draw")
        else
            state.turn = 1 - state.turn
        end

        broadcast_state(dispatcher, state)
        ::continue::
    end

    return state
end

local function match_terminate(context, dispatcher, tick, state, grace_seconds)
    nk.logger_info("🛑 Match terminated.")
    return state
end

local function match_signal(context, dispatcher, tick, state, data)
    return state, data
end

-- === Register directly in this module ===
local M = {}

function M.match_init(context, params)
    return match_init(context, params)
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    return match_join_attempt(context, dispatcher, tick, state, presence, metadata)
end

function M.match_join(context, dispatcher, tick, state, presences)
    return match_join(context, dispatcher, tick, state, presences)
end

function M.match_leave(context, dispatcher, tick, state, presences)
    return match_leave(context, dispatcher, tick, state, presences)
end

function M.match_loop(context, dispatcher, tick, state, messages)
    return match_loop(context, dispatcher, tick, state, messages)
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
    return match_terminate(context, dispatcher, tick, state, grace_seconds)
end

function M.match_signal(context, dispatcher, tick, state, data)
    return match_signal(context, dispatcher, tick, state, data)
end

return M