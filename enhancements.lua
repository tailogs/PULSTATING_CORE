local M = {}

local score = require("score")
local cannon_module = require("cannon")
local bullet_module = require("bullet")
local enemy_module = require("enemy")

M.buttons = {}
local buttonSize = 50
local lineWidth = 1
local buttonSpacing = 10
local effects = {"Immortality", "Shield", "Healing", "Damage", "Rotation Speed", "Reload Speed", "Bullet Speed", "Critical Hit"}
local animationTime = 0.5

M.firstRun = true
local criticalChance = 10

M.immortalityIcon = love.graphics.newImage("image/Immortal.png")
M.shieldIcon = love.graphics.newImage("image/Shield.png")
M.healingIcon = love.graphics.newImage("image/Healing.png")
M.damageIcon = love.graphics.newImage("image/Damage.png")
M.rotationSpeedIcon = love.graphics.newImage("image/RotationSpeed.png")
M.reloadSpeedIcon = love.graphics.newImage("image/ReloadSpeed.png")
M.bulletSpeedIcon = love.graphics.newImage("image/BulletSpeed.png")
M.criticalHitIcon = love.graphics.newImage("image/CriticalHit.png")

score.setScore(0)

local effectCosts = {
    ["Immortality"] = 20,
    ["Shield"] = 5,
    ["Healing"] = 10,
    ["Damage"] = 5,
    ["Rotation Speed"] = 5,
    ["Reload Speed"] = 5,
    ["Bullet Speed"] = 5,
    ["Critical Hit"] = 5,
}

M.immortalityTimer = nil
M.immortalityDuration = 10
M.originalMaxHealth = 0
M.originalHealth = 0

local errorMessage = nil

function M.activateImmortality()
    if M.immortalityTimer == nil then
        M.originalMaxHealth = cannon_module.cannon.maxHealth
        M.originalHealth = cannon_module.cannon.health
        cannon_module.cannon.maxHealth = math.huge
        cannon_module.cannon.health = math.huge
        M.immortalityTimer = M.immortalityDuration
    else
        M.immortalityTimer = M.immortalityTimer + M.immortalityDuration
    end
end

function M.updateImmortality(dt)
    if M.immortalityTimer then
        M.immortalityTimer = M.immortalityTimer - dt
        if M.immortalityTimer <= 0 then
            cannon_module.cannon.maxHealth = M.originalMaxHealth
            cannon_module.cannon.health = M.originalHealth
            M.immortalityTimer = nil
        end
    end
end

function M.drawImmortalityTimer()
    if M.immortalityTimer then
        local timeLeft = math.ceil(M.immortalityTimer)
        local x = love.graphics.getWidth() - 180
        local y = love.graphics.getHeight() / 2 - 20

        local text = "Immortality: " .. timeLeft
        local textWidth = love.graphics.getFont():getWidth(text)

        local backgroundWidth = textWidth + 20

        local alpha = math.abs(math.sin(M.immortalityTimer * 2 * math.pi / M.immortalityDuration))
        love.graphics.setColor(1, 0.3, 0.3, 0.5 + 0.5 * alpha)
        love.graphics.rectangle("fill", x - backgroundWidth / 2 - 10, y - 10, backgroundWidth + 100, 40)

        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.print(text, x - textWidth / 2, y)
    end
end

function M.setError(message)
    errorMessage = message
end

function M.canAfford(button)
    local currentScore = score.getScore()
    print("M.score value: ", currentScore)

    if not currentScore or type(currentScore) ~= "number" then
        print("Ошибка: очки не являются числом. Устанавливаю значение в 0.")
        currentScore = 0
    end

    if currentScore < button.price then
        print("Недостаточно очков для покупки " .. button.effect)
        return false
    end

    return true
end

local function increaseCriticalChance()
    criticalChance = math.min(criticalChance + 5, 100)
end

function M.getCriticalChance()
    return criticalChance
end

function M.isCritical()
    return math.random(100) <= criticalChance
end

local function applyEnhancement(effect)
    if effect == "Immortality" then
        M.activateImmortality()
    elseif effect == "Shield" then
        local tempMaxHealth = math.floor(cannon_module.cannon.maxHealth * 0.5 + 0.5)
        cannon_module.cannon.maxHealth = tempMaxHealth + cannon_module.cannon.maxHealth
        cannon_module.cannon.health = tempMaxHealth + cannon_module.cannon.health
    elseif effect == "Healing" then
        local healAmount = (cannon_module.cannon.maxHealth - cannon_module.cannon.health) * 0.5
        cannon_module.cannon.health = math.min(cannon_module.cannon.health + healAmount, cannon_module.cannon.maxHealth)
    elseif effect == "Damage" then
        bullet_module.domag = bullet_module.domag + 0.5
    elseif effect == "Rotation Speed" then
        cannon_module.cannon.rotationSpeed = cannon_module.cannon.rotationSpeed + cannon_module.cannon.rotationSpeed * 0.2
    elseif effect == "Reload Speed" then
        cannon_module.cannon.reloadTime = math.max(cannon_module.cannon.reloadTime - cannon_module.cannon.reloadTime * 0.2, 0.5)
    elseif effect == "Bullet Speed" then
        cannon_module.cannon.bulletSpeed = cannon_module.cannon.bulletSpeed + 50
    elseif effect == "Critical Hit" then
        increaseCriticalChance()
        cannon_module.isCritical = M.getCriticalChance()
    end
end

function M.buyEnhancement(effect)
    local effectCost = effectCosts[effect]

    if not effectCost or type(effectCost) ~= "number" then
        print("Ошибка: неверная цена для улучшения " .. effect)
        return
    end

    local button = nil
    for _, btn in ipairs(M.buttons) do
        if btn.effect == effect then
            button = btn
            break
        end
    end

    if button and M.canAfford(button) then
        score.addScore(-effectCost)
        print("Вы купили " .. effect)

        applyEnhancement(effect)

        if effect == "Immortality" or effect == "Healing" then
        else
            button.price = math.floor(button.price * 1.5)
        end
        effectCosts[effect] = button.price
    else
        print("Недостаточно очков для покупки " .. effect)
    end
end

function M.isMouseOverButton(button)
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= button.x and mouseX <= button.x + button.width and mouseY >= button.y and mouseY <= button.y + button.height
end

function M.createButtons()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local columns = 8
    local totalWidth = columns * buttonSize + (columns - 1) * buttonSpacing
    local startX = (screenWidth - totalWidth) / 2
    local y = screenHeight - buttonSize - 60 + 30

    for i = 0, columns - 1 do
        local effectIndex = i % #effects + 1
        local effect = effects[effectIndex]
        local price = effectCosts[effect]
        
        print("Effect: " .. effect .. ", Price: " .. price)
        
        table.insert(M.buttons, {
            x = startX + i * (buttonSize + buttonSpacing),
            y = y,
            width = buttonSize,
            height = buttonSize,
            effect = effect,
            price = price,
            clicked = false,
            scale = 0,
            angle = 0,
            opacity = 0,
            clickTime = 0,
            hoverTime = 0,
            isHovered = false,
            hovering = false,
        })
    end
end

function M.update(dt)
    M.updateImmortality(dt)

    if M.firstRun then
        for _, btn in ipairs(M.buttons) do
            btn.scale = math.min(btn.scale + dt / (animationTime), 1)
            btn.opacity = math.min(btn.opacity + dt / animationTime, 1)

            btn.angle = btn.angle + 180 * dt / animationTime

            if btn.scale == 1 and btn.opacity == 1 then
                M.firstRun = false
            end
        end
    else
        for _, btn in ipairs(M.buttons) do
            local isHovered = M.isMouseOverButton(btn)

            if isHovered then
                if not btn.hovering then
                    btn.hoverTime = 0
                    btn.returnTime = 0
                    btn.hovering = true
                end
                btn.hoverTime = math.min(btn.hoverTime + dt, animationTime)
                btn.isHovered = true
            else
                if btn.hovering then
                    btn.returnTime = math.min(btn.returnTime + dt, animationTime)
                    btn.hoverTime = math.max(btn.hoverTime - dt, 0)

                    if btn.returnTime >= animationTime then
                        btn.hovering = false
                        btn.isHovered = false
                    end
                end
            end

            local scaleFactor = 1 + 0.2 * math.sin((math.pi / 2) * (btn.hoverTime / animationTime * 0.1))
            local finalScale = scaleFactor * 1

            btn.scale = finalScale

            btn.angle = 90 * math.sin((math.pi / 2) * (btn.hoverTime / animationTime))

            if btn.clicked then
                btn.clickTime = btn.clickTime + dt
                if btn.clickTime <= animationTime then
                    btn.scale = 1
                else
                    btn.clicked = false
                end
            end
        end
    end
end

function M.draw()
    for i, button in ipairs(M.buttons) do
        local x, y, width, height = button.x, button.y, button.width, button.height
        local isHovered = M.isMouseOverButton(button)

        love.graphics.setColor(1, 1, 1, button.opacity)

        if button.clicked then
            love.graphics.setColor(1, 0, 0, button.opacity)
        elseif button.isHovered or button.hovering then
            love.graphics.setColor(0.2, 0.8, 0.2, button.opacity)
        else
            love.graphics.setColor(0.2, 0.5, 1, button.opacity)
        end

        love.graphics.setLineWidth(lineWidth)

        love.graphics.push()
        love.graphics.translate(x + width / 2, y + height / 2)
        love.graphics.rotate(math.rad(button.angle))
        love.graphics.rectangle("line", -width * button.scale / 2, -height * button.scale / 2, width * button.scale, height * button.scale)
        love.graphics.pop()

        if button.effect == "Immortality" then
            M.drawImmortalityIcon(x, y, width * button.scale, button)
        elseif button.effect == "Shield" then
            M.drawShieldIcon(x, y, width * button.scale, button)
        elseif button.effect == "Healing" then
            M.drawHealingIcon(x, y, width * button.scale, button)
        elseif button.effect == "Damage" then
            M.drawDamageIcon(x, y, width * button.scale, button)
        elseif button.effect == "Rotation Speed" then
            M.drawRotationSpeedIcon(x, y, width * button.scale, button)
        elseif button.effect == "Reload Speed" then
            M.drawReloadSpeedIcon(x, y, width * button.scale, button)
        elseif button.effect == "Bullet Speed" then
            M.drawBulletSpeedIcon(x, y, width * button.scale, button)
        elseif button.effect == "Critical Hit" then
            M.drawCriticalHitIcon(x, y, width * button.scale, button)
        end

        love.graphics.setColor(1, 1, 1, button.opacity)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf(button.effect, x, y - 30, width * button.scale, "center")

        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Price: " .. button.price, x, y + height + 5, width * button.scale, "center")
    end

    M.drawImmortalityTimer()
end

function M.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        for _, btn in ipairs(M.buttons) do
            if M.isMouseOverButton(btn) then
                M.buyEnhancement(btn.effect)
            end
        end
    end
end

function M.drawImmortalityIcon(x, y, size, button)
    if M.immortalityIcon then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.push()
        love.graphics.translate(x + size / 2, y + size / 2)
        love.graphics.rotate(math.rad(button.angle))
        love.graphics.draw(M.immortalityIcon, 0, 0, 0, size / M.immortalityIcon:getWidth(), size / M.immortalityIcon:getHeight(), M.immortalityIcon:getWidth() / 2, M.immortalityIcon:getHeight() / 2)
        love.graphics.pop()
    else
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 3)
        love.graphics.setLineWidth(3)
        love.graphics.setColor(0, 1, 0, 0.4)
        love.graphics.circle("line", x + size / 2, y + size / 2, size / 3)
    end
end

local function drawIconWithEffect(icon, x, y, size, angle, fallbackShape)
    if icon then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.push()
        love.graphics.translate(x + size / 2, y + size / 2)
        love.graphics.rotate(math.rad(angle))
        love.graphics.draw(icon, 0, 0, 0, size / icon:getWidth(), size / icon:getHeight(), icon:getWidth() / 2, icon:getHeight() / 2)
        love.graphics.pop()
    else
        fallbackShape()
    end
end

function M.drawShieldIcon(x, y, size, button)
    drawIconWithEffect(
        M.shieldIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(0, 0, 1)
            love.graphics.rectangle("fill", x + size / 4, y + size / 4, size / 2, size / 2)
        end
    )
end

function M.drawHealingIcon(x, y, size, button)
    drawIconWithEffect(
        M.healingIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(1, 0, 0)
            love.graphics.polygon("fill", x + size / 4, y, x + size / 2, y + size / 2, x + size, y)
        end
    )
end

function M.drawDamageIcon(x, y, size, button)
    drawIconWithEffect(
        M.damageIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(1, 0, 0)
            love.graphics.polygon("fill", x + size / 4, y, x + size / 2, y + size / 2, x + size, y)
        end
    )
end

function M.drawRotationSpeedIcon(x, y, size, button)
    drawIconWithEffect(
        M.rotationSpeedIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(0, 0, 1)
            love.graphics.polygon("fill", x + size / 4, y, x + size / 2, y + size / 2, x + size, y)
        end
    )
end

function M.drawReloadSpeedIcon(x, y, size, button)
    drawIconWithEffect(
        M.reloadSpeedIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("fill", x + size / 4, y + size / 4, size / 2, size / 2)
        end
    )
end

function M.drawBulletSpeedIcon(x, y, size, button)
    drawIconWithEffect(
        M.bulletSpeedIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(0, 1, 0)
            love.graphics.polygon("fill", x + size / 4, y, x + size / 2, y + size / 2, x + size, y)
        end
    )
end

function M.drawCriticalHitIcon(x, y, size, button)
    drawIconWithEffect(
        M.criticalHitIcon,
        x,
        y,
        size,
        button.angle,
        function()
            love.graphics.setColor(1, 0, 0)
            love.graphics.polygon("fill", x + size / 4, y, x + size / 2, y + size / 2, x + size, y)
        end
    )
end

return M