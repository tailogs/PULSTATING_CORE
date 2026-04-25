local centerX, centerY
local radius = 250
local duration = 2
local fullCircleTime = 5
local starSpeed = 0.05
local fogAlphaSpeed = 0.002
local stars, fogs = {}, {}

local alpha = 0
local scale = 0
local timer = 0
local ringAlpha = 0
local ringTimer = 0
local rotationTime = 0
local starTimer = 0
local isRotating = false
local isInitialized = false

function generateStarsAndFogs()
    for i = 1, 200 do
        local star = {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            size = math.random(1, 3),
            alpha = 0
        }
        table.insert(stars, star)
    end

    for i = 1, 3 do
        local fog = {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            size = math.random(50, 200),
            alpha = 0
        }
        table.insert(fogs, fog)
    end
end

function love.load()
    love.window.setMode(800, 600, {fullscreen = true})
    centerX, centerY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    love.graphics.setLineWidth(6)
end

function love.update(dt)
    timer = timer + dt
    ringTimer = ringTimer + dt
    rotationTime = rotationTime + dt
    starTimer = starTimer + dt

    if timer <= duration then
        scale = timer / duration
        alpha = timer / duration
    else
        scale = 1
        alpha = 1
    end
    
    if ringTimer <= duration then
        ringAlpha = ringTimer / duration
    else
        ringAlpha = 1
    end

    local secElapsed = rotationTime % fullCircleTime
    angle = ((secElapsed / fullCircleTime) * 360) - 90

    if starTimer >= fullCircleTime then
        if not isInitialized then
            generateStarsAndFogs()
            isInitialized = true
        end
        starTimer = 0
    end

    for i, star in ipairs(stars) do
        if star.alpha < 1 then
            star.alpha = star.alpha + starSpeed * dt
        end
    end
    for i, fog in ipairs(fogs) do
        if fog.alpha < 1 then
            fog.alpha = fog.alpha + fogAlphaSpeed * dt
        end
    end

    if rotationTime >= fullCircleTime * 12 then
        isRotating = true
    end

    if isRotating then
        for i, star in ipairs(stars) do
            star.x = star.x - 1
            if star.x < 0 then
                star.x = love.graphics.getWidth()
            end
        end
    end
end

function love.draw()
    for i, fog in ipairs(fogs) do
        love.graphics.setColor(1, 1, 1, fog.alpha)
        love.graphics.circle("fill", fog.x, fog.y, fog.size)
    end

    for i, star in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, star.alpha)
        love.graphics.circle("fill", star.x, star.y, star.size)
    end

    love.graphics.setColor(0.8, 0.8, 0.8, ringAlpha)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", centerX, centerY, radius, 50)

    love.graphics.setColor(0.2, 0.8, 1, alpha)
    love.graphics.setLineWidth(10)
    love.graphics.line(centerX, centerY, 
                      centerX + math.cos(math.rad(angle)) * radius * scale, 
                      centerY + math.sin(math.rad(angle)) * radius * scale)
    
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.circle("fill", centerX, centerY, 10)
end