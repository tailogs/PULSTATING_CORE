local M = {}

M.impactEffects = {}

function M.createImpactEffect(x, y)
    table.insert(M.impactEffects, {
        x = x,
        y = y,
        duration = 0.7,
        sparks = {},
    })

    local numSparks = 30
    for i = 1, numSparks do
        local angle = math.random() * math.pi * 2
        local speed = math.random(100, 300)
        table.insert(M.impactEffects[#M.impactEffects].sparks, {
            x = x,
            y = y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            life = math.random() * 0.5 + 0.3,
            alpha = 1,
        })
    end
end

function M.updateImpactEffects(dt)
    for i = #M.impactEffects, 1, -1 do
        local effect = M.impactEffects[i]

        for j = #effect.sparks, 1, -1 do
            local spark = effect.sparks[j]
            spark.x = spark.x + spark.dx * dt
            spark.y = spark.y + spark.dy * dt
            spark.alpha = spark.alpha - dt / spark.life
            if spark.alpha <= 0 then
                table.remove(effect.sparks, j)
            end
        end

        if #effect.sparks == 0 then
            table.remove(M.impactEffects, i)
        end
    end
end

function M.drawImpactEffects()
    for _, effect in ipairs(M.impactEffects) do
        for _, spark in ipairs(effect.sparks) do
            love.graphics.setColor(1, 0, 0, spark.alpha)
            love.graphics.circle("fill", spark.x, spark.y, 3)
        end
    end
end

function M.clearEffects()
    M.impactEffects = {}
end

return M
