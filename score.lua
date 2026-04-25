local M = {}

local sound_module = require("sound")
local fonts = require("fonts")

M.score = 0
M.scoreAnimations = {}
M.scoreTextAlpha = 0
M.scoreTextVisible = false
M.particles = {}
M.scoreTextSize = 32
M.flashDuration = 0
M.flashMaxTime = 1

function M.getScore()
    return M.score
end

function M.setScore(value)
    M.score = value
end

function M.addScore(points, x, y)
    M.score = M.score + points
    table.insert(M.scoreAnimations, {
        points = points,
        x = x,
        y = y,
        animProgress = 0,
        animDuration = 1,
        alpha = 1,
        scale = 1,
    })
    sound_module.playScoreSound()

    M.createParticleEffect(x, y)

    M.flashDuration = M.flashMaxTime
end

function M.createParticleEffect(x, y)
end

function M.updateTextVisibility(dt)
    if not M.scoreTextVisible then
        M.scoreTextAlpha = M.scoreTextAlpha + dt * 0.5
        if M.scoreTextAlpha >= 1 then
            M.scoreTextAlpha = 1
            M.scoreTextVisible = true
        end
    end
end

function M.animateScore(dt)
    for i, anim in ipairs(M.scoreAnimations) do
        anim.animProgress = anim.animProgress + dt
        if anim.animProgress >= anim.animDuration then
            table.remove(M.scoreAnimations, i)
        else
            anim.scale = 1 + 1 * (1 - anim.animProgress / anim.animDuration)
            anim.alpha = anim.alpha - dt * 2
        end
    end
end

function M.updateParticles(dt)
end

function M.drawScore()
    local flashFactor = 1
    if M.flashDuration > 0 then
        flashFactor = math.abs(math.sin(love.timer.getTime() * 10))
        M.flashDuration = M.flashDuration - love.timer.getDelta()
    end

    local time = love.timer.getTime()
    local r1, g1, b1 = math.abs(math.sin(time * 0.5)), math.abs(math.cos(time * 0.5)), 1 - math.abs(math.sin(time * 0.5))
    local r2, g2, b2 = math.abs(math.sin(time * 0.3)), math.abs(math.cos(time * 0.3)), 1 - math.abs(math.sin(time * 0.3))

    local r = r1 * (1 - math.abs(math.sin(time * 0.5))) + r2 * math.abs(math.sin(time * 0.5))
    local g = g1 * (1 - math.abs(math.cos(time * 0.5))) + g2 * math.abs(math.cos(time * 0.5))
    local b = b1 * (1 - math.abs(math.sin(time * 0.5))) + b2 * math.abs(math.sin(time * 0.5))

    love.graphics.setColor(r, g, b, M.scoreTextAlpha)
    local fontSize = 36
    local color = {r = r, g = g, b = b, a = M.scoreTextAlpha}
    fonts.drawFontScumbriaRegular(fontSize, color, "Score: " .. M.score, 10, 10)

    for _, anim in ipairs(M.scoreAnimations) do
        love.graphics.setColor(r, g, b, anim.alpha)
        fonts.drawFontScumbriaRegular(fontSize, color, "+" .. anim.points, anim.x, anim.y)
    end

    for _, p in ipairs(M.particles) do
        love.graphics.setColor(p.r, p.g, p.b, p.life)
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end
end

return M
