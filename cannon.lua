local M = {}
local sound_module = require("sound")
local score_module = require("score")
local math_utils = require("math_utils")
local bullet_module = require("bullet")

M.cannon = {
    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() / 2,
    angle = 0,
    rotationSpeed = 2,
    shootCooldown = 1,
    timeSinceLastShot = 0,
    target = nil,
    bulletSpeed = 300,
    bullets = {},
    recoilAmount = 10,
    recoilTime = 0.1,
    recoilTimer = 0,
    isReloading = false,
    reloadTime = 1,
    reloadTimer = 0,
    bulletCount = 8,
    maxBullets = 8,
    health = 100,
    maxHealth = 100
}

M.cannonVisible = false
M.cannonSize = 0
M.cannonGrowthTime = 2
M.cannonMaxSize = 40
M.cannonTurnSpeed = 3
M.isCritical = 10

M.lastShotAngle = nil

M.degree = 0

local function hasBulletForTarget(target)
    for _, bullet in ipairs(M.cannon.bullets) do
        if bullet.target == target then
            return true
        end
    end
    return false
end

function M.updateCannon(startTime, enemy_module, math_utils, bullet_module, impact_effects, dt)
    if startTime >= M.cannonGrowthTime and not M.cannonVisible then
        M.cannonSize = math.min(M.cannonSize + (M.cannonMaxSize * dt / M.cannonGrowthTime), M.cannonMaxSize)
        if M.cannonSize == M.cannonMaxSize then
            M.cannonVisible = true
        end
    end

    M.cannon.x = love.graphics.getWidth() / 2
    M.cannon.y = love.graphics.getHeight() / 2

    if M.cannonVisible then
        if love.keyboard.isDown("v") then
            M.manualControl = not M.manualControl
            love.timer.sleep(0.2)
        end

        local mouseX, mouseY = love.mouse.getPosition()
        local dx = mouseX - M.cannon.x
        local dy = mouseY - M.cannon.y

        local targetAngle = math.atan2(dy, dx)

        local angleDiff = targetAngle - M.cannon.angle

        if angleDiff > math.pi then
            angleDiff = angleDiff - 2 * math.pi
        end
        if angleDiff < -math.pi then
            angleDiff = angleDiff + 2 * math.pi
        end

        M.cannon.angle = M.cannon.angle + math_utils.sign(angleDiff) *
                             math.min(math.abs(angleDiff), M.cannon.rotationSpeed * dt)

        M.cannon.timeSinceLastShot = M.cannon.timeSinceLastShot + dt
    
        if M.cannon.isReloading then
            M.cannon.reloadTimer = M.cannon.reloadTimer + dt

            if M.cannon.reloadTimer >= M.cannon.reloadTime then
                M.cannon.bulletCount = math.min(M.cannon.bulletCount + 1, M.cannon.maxBullets)
                M.cannon.reloadTimer = 0
                sound_module.playFillSound()

                if M.cannon.bulletCount == M.cannon.maxBullets then
                    M.cannon.isReloading = false
                end
            end
        end

        if M.cannon.recoilTimer > 0 then
            M.cannon.recoilTimer = M.cannon.recoilTimer - dt
        end

        for i = #M.cannon.bullets, 1, -1 do
            local bullet = M.cannon.bullets[i]

            if bullet and bullet.angle then
                if bullet.angle then
                    bullet.x = bullet.x + math.cos(bullet.angle) * bullet.speed * dt
                    bullet.y = bullet.y + math.sin(bullet.angle) * bullet.speed * dt

                    for j, enemy in ipairs(enemy_module.enemies) do
                        if math.abs(bullet.x - enemy.x) < enemy.size / 2 and math.abs(bullet.y - enemy.y) < enemy.size /
                            2 then
                            enemy.hp = enemy.hp - bullet.domag
                            impact_effects.createImpactEffect(bullet.x, bullet.y)
                            score_module.addScore(math.floor(bullet.domag), enemy.x, enemy.y)

                            if enemy.hp <= 0 then
                                table.remove(enemy_module.enemies, j)
                            end

                            table.remove(M.cannon.bullets, i)
                            break
                        end
                    end
                end
            elseif not bullet then
                print("Ошибка: пуля равна nil")
            else
                print("Ошибка: bullet.angle равно nil для пули")
            end
        end

        for _, enemy in ipairs(enemy_module.enemies) do
            if enemy.isAttacking then
                M.cannon.health = math.max(0, M.cannon.health - dt * 10)
                sound_module:playAttackEnemy()
                if M.cannon.health <= 0 then
                    print("Башня уничтожена!")
                    break
                end
            end
        end
    end
end

function M.attackPlayerCannon(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local dx = mouseX - M.cannon.x
    local dy = mouseY - M.cannon.y
    local targetAngle = math.atan2(dy, dx)

    local angleDiff = targetAngle - M.cannon.angle
    if angleDiff > math.pi then
        angleDiff = angleDiff - 2 * math.pi
    end
    if angleDiff < -math.pi then
        angleDiff = angleDiff + 2 * math.pi
    end

    M.cannon.angle = M.cannon.angle + math_utils.sign(angleDiff) *
                         math.min(math.abs(angleDiff), M.cannon.rotationSpeed * dt)

    if M.cannon.timeSinceLastShot >= M.cannon.shootCooldown and M.cannon.bulletCount > 0 then
        local bullet = bullet_module.createBullet(M.cannon, M.cannon.x, M.cannon.y, M.cannon.angle, M.isCritical)
        table.insert(M.cannon.bullets, bullet)
        sound_module.playShotSound()

        M.cannon.bulletCount = M.cannon.bulletCount - 1
        M.cannon.timeSinceLastShot = 0

        if M.cannon.bulletCount == 0 then
            M.cannon.isReloading = true
        end
    end
end

function M.drawCannon()
    if M.cannonVisible then
        love.graphics.push()
        love.graphics.translate(M.cannon.x, M.cannon.y)
        love.graphics.rotate(M.cannon.angle)

        local recoilOffset = 0
        if M.cannon.recoilTimer > 0 then
            recoilOffset = -M.cannon.recoilAmount * (M.cannon.recoilTimer / M.cannon.recoilTime)
        end

        love.graphics.setColor(0.7, 0.2, 0.7)
        love.graphics.setLineWidth(5)
        love.graphics.rectangle("line", recoilOffset - M.cannonSize / 3, -M.cannonSize / 6, M.cannonSize * 2 / 3,
            M.cannonSize / 3)

        love.graphics.setColor(1, 0.5, 0.5, 0.7)
        love.graphics.circle("line", recoilOffset - M.cannonSize / 3, -M.cannonSize / 6, M.cannonSize / 4)

        local time = love.timer.getTime() * 3
        for i = 0, M.cannon.bulletCount - 1 do
            local angle = (i / M.cannon.maxBullets) * math.pi * 2
            local xOffset = recoilOffset - M.cannonSize / 3 + math.cos(angle + time) * (M.cannonSize / 4 * 0.75)
            local yOffset = -M.cannonSize / 6 + math.sin(angle + time) * (M.cannonSize / 4 * 0.75)

            love.graphics.setColor(0.9, 0.6, 0.8)
            love.graphics.circle("fill", xOffset, yOffset, M.cannonSize / 20)
        end

        if M.cannon.isReloading then
            local reloadText = "RELOADING"
            love.graphics.push()
            love.graphics.rotate(-M.cannon.angle)
            love.graphics.setFont(love.graphics.newFont(28))
            local alpha = math.sin(love.timer.getTime() * 8) * 0.5 + 0.5
            love.graphics.setColor(0.9, 0.1, 0.7, alpha)
            love.graphics.print(reloadText, -M.cannonSize / 2 - 65, M.cannonSize / 1.5 + 50)
            love.graphics.pop()
        end

        love.graphics.pop()

        local healthBarWidth = 200
        local healthBarHeight = 20
        local healthRatio = math.max(0, M.cannon.health / M.cannon.maxHealth)

        local currentHealthBarWidth = math.min(healthBarWidth, healthBarWidth * healthRatio)

        love.graphics.push()
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", M.cannon.x - healthBarWidth / 2, M.cannon.y + 50, healthBarWidth,
            healthBarHeight)

        local healthColor = {
            r = (1 - healthRatio),
            g = healthRatio,
            b = 0
        }
        love.graphics.setColor(healthColor.r, healthColor.g, healthColor.b)
        love.graphics.rectangle("fill", M.cannon.x - healthBarWidth / 2, M.cannon.y + 50, currentHealthBarWidth,
            healthBarHeight)

        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", M.cannon.x - healthBarWidth / 2, M.cannon.y + 50, healthBarWidth,
            healthBarHeight)

        local healthText = tostring(math.floor(M.cannon.health)) .. " / " .. tostring(M.cannon.maxHealth)
        love.graphics.setFont(love.graphics.newFont(15))
        love.graphics.setColor(0, 0, 0)

        local textYPosition = M.cannon.y + (45 + healthBarHeight / 4) + 2
        love.graphics.printf(healthText, M.cannon.x - healthBarWidth / 2, textYPosition, healthBarWidth, "center")

        love.graphics.pop()
    end
end

function M.increaseBulletSpeed(amount)
    M.cannon.bulletSpeed = M.cannon.bulletSpeed + amount
end

function M.increaseHealth(amount)
    M.cannon.health = math.min(M.cannon.health + amount, 100)
end

function M.decreaseShootCooldown(amount)
    M.cannon.shootCooldown = math.max(M.cannon.shootCooldown - amount, 0.5)
end

function M.clearBullets()
    M.cannon.bullets = {}
end

return M