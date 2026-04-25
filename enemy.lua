local M = {}

local sound_module = require("sound")
local game_state = require("game_state")

M.enemies = {}
M.enemySpawnTime = 0
M.kills = 0
M.elapsedTime = 0

M.settings = {
    circle = {speed = 30, baseHP = 1, spawnWeight = 100, attackDamage = 1, attackInterval = 2, level = 1},
    rectangle = {speed = 25, baseHP = 2, spawnWeight = 0, attackDamage = 2, attackInterval = 1.8, level = 2},
    triangle = {speed = 20, baseHP = 3, spawnWeight = 0, attackDamage = 3, attackInterval = 1.5, level = 3},
    square = {speed = 15, baseHP = 4, spawnWeight = 0, attackDamage = 4, attackInterval = 1.2, level = 4},
    legendary = {speed = 10, baseHP = 5, spawnWeight = 0, attackDamage = 5, attackInterval = 1, level = 5},
}

M.shapes = {"circle", "rectangle", "triangle", "square", "legendary"}

M.initialSpawnInterval = 15
M.spawnIntervalDecreaseRate = 0.0005
M.currentSpawnInterval = M.initialSpawnInterval
M.timeSinceLastDecay = 0

function M.isOutsideSafeRadius(x, y, safeRadius)
    local centerX, centerY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
    return distance > safeRadius
end

function M.getSpawnData()
    local spawnInterval = M.currentSpawnInterval
    local spawnChance = math.random()
    local data = {
        spawnInterval = spawnInterval,
        spawnChance = spawnChance,
        additionalInfo = "Пример дополнительной информации",
    }
    return data
end

function M.updateSpawnChance()
    local timeFactor = M.elapsedTime / 60

    if timeFactor < 1 then
        M.settings.rectangle.spawnWeight = 1
    elseif timeFactor < 2 then
        M.settings.rectangle.spawnWeight = 5
        M.settings.triangle.spawnWeight = 3
    elseif timeFactor < 3 then
        M.settings.rectangle.spawnWeight = 10
        M.settings.triangle.spawnWeight = 5
        M.settings.square.spawnWeight = 3
    else
        M.settings.rectangle.spawnWeight = 15
        M.settings.triangle.spawnWeight = 10
        M.settings.square.spawnWeight = 5
        M.settings.legendary.spawnWeight = 1
    end
end

function M.createEnemy(x, y, shape)
    local safeRadius = 500
    while not M.isOutsideSafeRadius(x, y, safeRadius) do
        x = math.random(100, love.graphics.getWidth() - 100)
        y = math.random(100, love.graphics.getHeight() - 100)
    end
    shape = shape or M:randomShape()

    if not shape or not M.settings[shape] then
        print("Ошибка: форма '" .. (shape or "nil") .. "' не найдена в настройках врагов.")
        shape = "circle"
    end

    local settings = M.settings[shape]
    local attackDamage = settings.attackDamage or 1
    local attackInterval = settings.attackInterval or 1
    local color = {math.random(), math.random(), math.random()}

    local baseSize = 50
    local hpIncreaseFactor = math.min(0.5, M.elapsedTime / 600)
    local hp = settings.baseHP + hpIncreaseFactor * settings.baseHP
    local size = baseSize + math.max(0, (hp - 1))

    table.insert(M.enemies, {
        x = x,
        y = y,
        size = size,
        hp = hp,
        maxHP = hp,
        speed = settings.speed,
        attackDamage = attackDamage,
        attackInterval = attackInterval,
        attackCooldown = 0,
        shape = shape,
        color = color,
        alpha = 0,
        targetX = love.graphics.getWidth() / 2,
        targetY = love.graphics.getHeight() / 2,
    })
end

function M:randomShape()
    local totalWeight = 0
    for _, settings in pairs(M.settings) do
        totalWeight = totalWeight + settings.spawnWeight
    end

    if totalWeight == 0 then
        print("Ошибка: общий вес врагов равен 0, не удается выбрать форму.")
        return "circle"
    end

    local rand = math.random(totalWeight)
    local cumulativeWeight = 0

    for shape, settings in pairs(M.settings) do
        cumulativeWeight = cumulativeWeight + settings.spawnWeight
        if rand <= cumulativeWeight then
            return shape
        end
    end
end

function M.updateEnemy(dt)
    M.elapsedTime = M.elapsedTime + dt
    M.updateSpawnChance()

    M.enemySpawnTime = M.enemySpawnTime + dt

    local numToSpawn = math.min(3, math.floor(M.elapsedTime / 60) + 1)

    if M.enemySpawnTime >= M.currentSpawnInterval then
        for i = 1, numToSpawn do
            M.createEnemy(math.random(100, love.graphics.getWidth() - 100), math.random(100, love.graphics.getHeight() - 100))
        end
        M.enemySpawnTime = 0
    end
    
    M.currentSpawnInterval = math.max(1, M.initialSpawnInterval / (1 + M.spawnIntervalDecreaseRate * M.elapsedTime))

    for _, enemy in ipairs(M.enemies) do
        local angle = math.atan2(enemy.targetY - enemy.y, enemy.targetX - enemy.x)
        enemy.x = enemy.x + math.cos(angle) * enemy.speed * dt
        enemy.y = enemy.y + math.sin(angle) * enemy.speed * dt

        enemy.alpha = math.min(enemy.alpha + dt, 1)

        enemy.attackCooldown = enemy.attackCooldown + dt
        local distance = math.sqrt((enemy.x - enemy.targetX)^2 + (enemy.y - enemy.targetY)^2)

        if distance < enemy.size / 2 + 20 and enemy.attackCooldown >= enemy.attackInterval then
            M.attackCannon(cannon)
            enemy.attackCooldown = 0
        end

        if math.floor(enemy.hp + 0.5) <= 0 then
            M.kills = M.kills + 1
            table.remove(M.enemies, _)
        end
    end
end

function M.drawEnemy()
    for _, enemy in ipairs(M.enemies) do
        love.graphics.setColor(enemy.color[1], enemy.color[2], enemy.color[3], enemy.alpha)
        love.graphics.setLineWidth(2)

        if enemy.shape == "circle" then
            love.graphics.circle("line", enemy.x, enemy.y, enemy.size / 2)
        elseif enemy.shape == "rectangle" then
            love.graphics.rectangle("line", enemy.x - enemy.size / 2, enemy.y - enemy.size / 2, enemy.size, enemy.size)
        elseif enemy.shape == "triangle" then
            love.graphics.polygon("line",
            enemy.x, enemy.y - enemy.size / 2,
            enemy.x - enemy.size / 2, enemy.y + enemy.size / 2,
            enemy.x + enemy.size / 2, enemy.y + enemy.size / 2
        )
        elseif enemy.shape == "square" then
            love.graphics.rectangle("line", enemy.x - enemy.size / 2, enemy.y - enemy.size / 2, enemy.size, enemy.size)
        elseif enemy.shape == "legendary" then
            love.graphics.setColor(enemy.color[1], enemy.color[2], enemy.color[3], 0.7)
            love.graphics.circle("fill", enemy.x, enemy.y, enemy.size / 2)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.circle("line", enemy.x, enemy.y, enemy.size / 2)
        end

        local fontSize = math.max(12, math.min(30, enemy.hp / 10))
        love.graphics.setFont(love.graphics.newFont(fontSize))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            tostring(math.floor(enemy.hp + 0.5)),
            enemy.x - enemy.size / 2,
            enemy.y - fontSize / 2,
            enemy.size,
            "center"
        )
    end
end

function M.clearEnemies()
    M.enemies = {}
end

function M.attackCannon(cannon)
    if not cannon then
        print("Ошибка: пушка не найдена!")
        return
    end

    for _, enemy in ipairs(M.enemies) do
        local distance = math.sqrt((enemy.x - cannon.x)^2 + (enemy.y - cannon.y)^2)

        if distance < enemy.size / 2 + 20 then
            if enemy.attackDamage then
                local maxHealth = cannon.maxHealth
                cannon.health = math.max(0, cannon.health - (maxHealth * 0.01 * enemy.attackDamage) )
                print("Пушка получила урон: " .. enemy.attackDamage)
            else
                print("Ошибка: Отсутствует attackDamage у врага с формой: " .. enemy.shape)
            end

            sound_module.playAttackEnemy()
        end
    end
end

return M