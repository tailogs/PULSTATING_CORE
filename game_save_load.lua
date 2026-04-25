local M = {}

local game_state = require("game_state")
local score_module = require("score")

function M.shiftEncryptDecrypt(data, key)
    local output = {}
    for i = 1, #data do
        local char = string.byte(data, i)
        local shiftedChar = char + key
        table.insert(output, string.char(shiftedChar))
    end
    return table.concat(output)
end

function M.saveGameProgress(score, time)
    if score == nil or time == nil then
        print("Error: score or time is nil")
        return
    end

    local filePath = "game_progress.dat"
    local file, err = io.open(filePath, "w")

    if not file then
        print("Error opening file for writing: " .. err)
        return
    end

    local saveData = string.format("%d,%f", score, time)
    local key = 3

    local encryptedData = M.shiftEncryptDecrypt(saveData, key)

    file:write(encryptedData)
    file:close()
    print("Game progress saved securely in the project directory.")
end

function M.loadGameProgress()
    local filePath = "game_progress.dat"
    local file, err = io.open(filePath, "r")

    if not file then
        print("Error opening file for reading: " .. err)
        return nil
    end

    local encryptedData = file:read("*a")
    file:close()

    local key = 3

    local decryptedData = M.shiftEncryptDecrypt(encryptedData, -key)

    local score, time = string.match(decryptedData, "(%d+),([%d.]+)")
    return tonumber(score), tonumber(time)
end

function M.handleGameOver()
    local currentScore = score_module.getScore()
    local currentTime = game_state.elapsedTime

    if currentScore == nil or currentTime == nil then
        print("Error: Unable to retrieve score or time")
        return
    end

    local savedScore, savedTime = M.loadGameProgress()

    if not savedTime or currentTime > savedTime then
        M.saveGameProgress(currentScore, currentTime)
    else
        print("Game progress not saved: time condition not met")
    end
end

return M