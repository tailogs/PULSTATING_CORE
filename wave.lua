local M = {}

M.waves = {}
M.waveSpeed = 150
M.maxWaveRadius = 2000

function M.createWave(x, y)
    table.insert(M.waves, {
        x = x,
        y = y,
        radius = 0,
        speed = M.waveSpeed,
        maxRadius = M.maxWaveRadius,
        timeElapsed = 0,
        colorFactor = 0,
    })
end

function M.updateWaves(dt)
    for _, wave in ipairs(M.waves) do
        wave.timeElapsed = wave.timeElapsed + dt
        wave.radius = wave.radius + wave.speed * dt

        wave.alpha = math.max(0, 255 * (1 - wave.timeElapsed * 0.02))

        if wave.radius > wave.maxRadius then
            wave.radius = wave.maxRadius
        end

        wave.colorFactor = (math.sin(wave.timeElapsed * 1.5) + 1) * 0.5
    end
end

function M.drawWaves(dt)
    for _, wave in ipairs(M.waves) do
        local red = wave.colorFactor
        local green = 0
        local blue = 1 - wave.colorFactor
        love.graphics.setColor(red, green, blue, wave.alpha / 255)

        love.graphics.setLineWidth(3)
        love.graphics.circle("line", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, wave.radius)

        love.graphics.setColor(red, green, blue, wave.alpha / 255 * 0.5)
        love.graphics.circle("line", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, wave.radius * 1.1)
    end
end

function M.clearWaves()
    M.waves = {}
end

return M