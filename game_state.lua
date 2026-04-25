local M = {}

M.startGame = true
M.startCreateCube = true
M.mainAnimationStarted = false
M.startDelay = 2
M.elapsedTime = 0
M.startTime = 0
M.gamePaused = false
M.menuOpen = false
M.t_dt = nil
M.debug = false

M.volume = 0.5

function M.formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", minutes, remainingSeconds, 0)
end

function M.updateGameTime(dt)
    if not M.gamePaused then
        M.elapsedTime = M.elapsedTime + dt
        M.gameTime = M.formatTime(M.elapsedTime)
    end
end

function M.pauseGame()
    M.gamePaused = true
    M.menuOpen = true
end

function M.resumeGame()
    M.gamePaused = false
    M.menuOpen = false
end

return M
