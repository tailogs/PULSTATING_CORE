local M = {}

M.squares = {}
M.startTime = 0
M.smallSquareSize = 5
M.smallSquareAlpha = 0
M.smallSquareDisappearTime = 2
M.smallSquareGrowthTime = 2
M.mainAnimationStarted = false
M.smallSquareMaxSize = 30
M.smallSquareCount = 0

function M.initializeSquares()
    for i = 1, 8 do
        table.insert(M.squares, {
            size = 0,
            alpha = 0,
            rotationSpeed = math.random(1, 3) * 0.1,
            rotation = 0,
            color = {math.random(), math.random(), math.random()},
            time = math.random() * 2,
            lifeTime = math.random() * 10 + 5
        })
    end
end

function M.updateAnimation(dt)
    M.startTime = M.startTime + dt

    if M.startTime >= 0 and M.startTime < M.smallSquareGrowthTime then
        M.smallSquareSize = math.min(M.smallSquareMaxSize * (M.startTime / M.smallSquareGrowthTime), M.smallSquareMaxSize)
        M.smallSquareAlpha = math.min(M.startTime / M.smallSquareGrowthTime, 1)
    end

    if M.startTime >= M.smallSquareGrowthTime then
        if not M.mainAnimationStarted then
            M.mainAnimationStarted = true
        end
    end

    if M.mainAnimationStarted then
        M.smallSquareCount = M.smallSquareCount + 1
    end
end

function M.updateSquares(dt)
    for _, square in ipairs(M.squares) do
        square.alpha = math.max(0, math.min(1, (math.sin(M.startTime * 2 + square.time) + 1) / 2))
        square.size = math.min(100 + math.sin(love.timer.getTime() * 0.5 + square.time) * 50, 150)
        square.rotation = love.timer.getTime() * square.rotationSpeed
    end
end

function M.drawSquares()
    local width, height = love.graphics.getDimensions()

    if M.startTime < M.smallSquareGrowthTime then
        for _, square in ipairs(M.squares) do
            love.graphics.setColor(square.color[1], square.color[2], square.color[3], M.smallSquareAlpha)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", width / 2 - M.smallSquareSize / 2, height / 2 - M.smallSquareSize / 2, M.smallSquareSize, M.smallSquareSize)
        end
    end

    if M.mainAnimationStarted then
        for _, square in ipairs(M.squares) do
            local scaleSize = 1
            love.graphics.push()
            love.graphics.translate(width / 2, height / 2)
            love.graphics.rotate(square.rotation)
            love.graphics.translate(-width / 2, -height / 2)
            love.graphics.setColor(square.color[1], square.color[2], square.color[3], square.alpha)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", width / 2 - square.size / 2, height / 2 - square.size / 2, square.size * scaleSize, square.size * scaleSize)
            love.graphics.pop()
        end
    end
end

return M
