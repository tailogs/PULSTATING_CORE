local M = {}

local game_state = require("game_state")
local score_module = require("score")
local sound_module = require("sound")
local fonts_manager = require("fonts")
local game_save_load = require("game_save_load")
local time_module = require("time_module")

M.isOpen = false
M.volume = 1.0
M.effectVolume = 1.0
M.sliderWidth = 350
M.sliderHeight = 30
M.closing = false
M.batteryLevel = 75
M.signalStrength = 4
M.buttonPressed = nil
M.gameTime = "00:12:34"
M.alpha = 0.0
M.tabletWidth, M.tabletHeight = 900, 650
M.isMuted = false
M.soundToggleTimer = 0
M.soundToggleCooldown = 0.2

M.currentScreen = "menu"
M.transitionAlpha = 0

function M.updateVolume(newVolume)
    M.volume = newVolume

    if newVolume == 0 then
        sound_module.toggleMusicMute()
    else
        sound_module.setMusicVolume(M.volume)
    end
end

function M.drawMusicVolumeSlider(x, y)
    local mx, my = love.mouse.getPosition()

    if mx > x and mx < x + M.sliderWidth and my > y and my < y + M.sliderHeight then
        if love.mouse.isDown(1) then
            M.volume = (mx - x) / M.sliderWidth
            M.volume = math.max(0, math.min(1, M.volume))
            sound_module.setMusicVolume(M.volume)
        end
    end

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, M.sliderWidth, M.sliderHeight, 5)

    love.graphics.setColor(0.8, 0.1, 0.8)
    love.graphics.rectangle("fill", x, y, M.sliderWidth * M.volume, M.sliderHeight, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Music Volume", x, y - 25)
    love.graphics.print(math.floor(M.volume * 100) .. "%", x + M.sliderWidth + 10, y + M.sliderHeight / 2 - love.graphics.getFont():getHeight() / 2)
end

function M.drawEffectsVolumeSlider(x, y)
    local mx, my = love.mouse.getPosition()

    if mx > x and mx < x + M.sliderWidth and my > y and my < y + M.sliderHeight then
        if love.mouse.isDown(1) then
            M.effectVolume = (mx - x) / M.sliderWidth
            M.effectVolume = math.max(0, math.min(1, M.effectVolume))
            sound_module.setEffectVolume(M.effectVolume)
        end
    end

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, M.sliderWidth, M.sliderHeight, 5)

    love.graphics.setColor(0.1, 0.8, 0.1)
    love.graphics.rectangle("fill", x, y, M.sliderWidth * M.effectVolume, M.sliderHeight, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Effects Volume", x, y - 25)
    love.graphics.print(math.floor(M.effectVolume * 100) .. "%", x + M.sliderWidth + 10, y + M.sliderHeight / 2 - love.graphics.getFont():getHeight() / 2)
end

function M.drawMusicToggle(x, y)
    local mx, my = love.mouse.getPosition()
    local isHovered = mx > x and mx < x + 60 and my > y and my < y + 30
    local toggleColor = M.isMuted and {0.8, 0.1, 0.1} or {0.1, 0.8, 0.1}

    love.graphics.setColor(toggleColor)
    love.graphics.rectangle("fill", x, y, 60, 30, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(M.isMuted and "OFF" or "ON", x + 15, y + 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Mute Music", x + 70, y + 5)

    if isHovered and love.mouse.isDown(1) then
        if love.timer.getTime() - M.soundToggleTimer > M.soundToggleCooldown then
            M.isMuted = not M.isMuted
            sound_module.toggleMusicMute()
            M.soundToggleTimer = love.timer.getTime()
        end
    end
end

function M.drawEffectsToggle(x, y)
    local mx, my = love.mouse.getPosition()
    local isHovered = mx > x and mx < x + 60 and my > y and my < y + 30
    local toggleColor = M.effectMuted and {0.8, 0.1, 0.1} or {0.1, 0.8, 0.1}

    love.graphics.setColor(toggleColor)
    love.graphics.rectangle("fill", x, y, 60, 30, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(M.effectMuted and "OFF" or "ON", x + 15, y + 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Mute Effects", x + 70, y + 5)

    if isHovered and love.mouse.isDown(1) then
        if love.timer.getTime() - M.soundToggleTimer > M.soundToggleCooldown then
            M.effectMuted = not M.effectMuted
            sound_module.toggleEffectsMute()
            M.soundToggleTimer = love.timer.getTime()
        end
    end
end

function M.drawTablet(x, y, width, height)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.25)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.rectangle("fill", x + 10, y + 10, width - 20, height - 20, 10)

    love.graphics.setColor(0.8, 0.2, 0.8)
    love.graphics.setLineWidth(5)
    love.graphics.rectangle("line", x, y, width, height, 10)

    love.graphics.setColor(1.0, 0.5, 1.0)
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line", x - 5, y - 5, width + 10, height + 10, 10)
end

function M.drawButton(label, x, y, onClick)
    local buttonWidth, buttonHeight = 300, 80
    local mx, my = love.mouse.getPosition()
    local isHovered = mx > x and mx < x + buttonWidth and my > y and my < y + buttonHeight

    local buttonColor = {0.9, 0.1, 0.8}

    if isHovered then
        buttonColor = {1, 0.3, 0.3}

        if love.mouse.isDown(1) then
            if M.buttonPressed == nil then
                M.buttonPressed = label
                onClick()
                if label == "Continue" then
                    M.isOpen = false
                    game_state.isPaused = false
                end
            end
        else
            M.buttonPressed = nil
        end
    else
        if not love.mouse.isDown(1) then
            M.buttonPressed = nil
        end
    end
    love.graphics.setColor(buttonColor[1], buttonColor[2], buttonColor[3], isHovered and 1 or 0.9)
    love.graphics.rectangle("fill", x + (isHovered and -2 or -1), y + (isHovered and -2 or -1),
        buttonWidth + (isHovered and 4 or 2), buttonHeight + (isHovered and 4 or 2), 8)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(label, x + buttonWidth / 2 - love.graphics.getFont():getWidth(label) / 2,
        y + buttonHeight / 2 - love.graphics.getFont():getHeight() / 2)
end

function M.drawAuthorsScreen()
    local width, height = love.graphics.getDimensions()
    local centerX, centerY = width / 2, height / 2

    local tabletX = (width - M.tabletWidth) / 2
    local tabletY = (height - M.tabletHeight) / 2

    M.drawTablet(tabletX, tabletY, M.tabletWidth, M.tabletHeight)

    love.graphics.setColor(1, 1, 1)
    fonts_manager.drawFontScumbriaRegular(40, {r = 1, g = 1, b = 1}, "Authors", centerX - 200, tabletY + 40, "center")

    love.graphics.setColor(1, 1, 1, 0.6)
    fonts_manager.drawFontScumbriaRegular(20, {r = 1, g = 1, b = 1}, "Click on the names to visit their profiles", centerX - 200, tabletY + 80, "center")
    
    local authors = {
        {name = "Tailogs", role = "Programming", telegram = ""}, 
        {name = "Tailogs", role = "Design", telegram = ""}, 
        {name = "neri san", role = "Music", telegram = "https://t.me/nerisann"}
    }

    for i, author in ipairs(authors) do
        local text = author.name .. " - " .. author.role
        local mx, my = love.mouse.getPosition()
        local isHovered = mx > tabletX + 50 and mx < tabletX + M.tabletWidth - 50 and my > tabletY + 100 + (i - 1) * 80 and my < tabletY + 100 + (i - 1) * 80 + 30

        local time = love.timer.getTime() * 2 + i
        local colorFactor = 0.5 + 0.5 * math.sin(time)

        local r = 0.5 + 0.5 * colorFactor
        local g = 0.5 * colorFactor
        local b = 1 - colorFactor

        love.graphics.setColor(r, g, b)

        fonts_manager.drawFontSturkopfGrotesk(64, {r = r, g = g, b = b}, text, tabletX + 50, tabletY + 120 + (i - 1) * 80, "left", nil, author.telegram)

    end

    M.drawButton("Back", tabletX + (M.tabletWidth - 300) / 2, tabletY + M.tabletHeight - 100, function()
        M.currentScreen = "menu"
    end)
end

function M.switchToAuthorsScreen()
    M.currentScreen = "authors"
    M.transitionAlpha = 1
end

function M.drawVolumeSlider(x, y)
    M.drawMusicVolumeSlider(x, y)
    M.drawEffectsVolumeSlider(x, y + 60)
end

function M.drawCyberpunkButton(x, y, onClick)
    local width, height = 150, 50
    local mx, my = love.mouse.getPosition()
    local isHovered = mx > x and mx < x + width and my > y and my < y + height

    local offsetX = isHovered and 4 or 2
    local offsetY = isHovered and 4 or 2

    local buttonColor = isHovered and {0.8, 0.2, 0.8} or {0.1, 0.8, 0.1}
    love.graphics.setColor(buttonColor)
    love.graphics.polygon("fill", x, y, x + width, y, x + width - 20, y + height, x + 20, y + height)
    
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    local text = "Player Stats"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, x + (width - textWidth) / 2, y + (height - textHeight) / 2)

    if isHovered and love.mouse.isDown(1) then
        onClick()
    end
end

function M.drawMenuScreen()
    local width, height = love.graphics.getDimensions()
    local centerX, centerY = width / 2, height / 2

    M.drawTablet(centerX - M.tabletWidth / 2, centerY - M.tabletHeight / 2, M.tabletWidth, M.tabletHeight)

    love.graphics.setColor(1, 1, 1)
    fonts_manager.drawFontScumbriaRegular(60, {r = 1, g = 1, b = 1}, "Menu", centerX - 85, centerY - M.tabletHeight / 2 + 40)

    M.drawVolumeSlider(centerX - 175, centerY + 180)
    M.drawMusicToggle(centerX - 175, centerY + 282)
    M.drawEffectsToggle(centerX - 5, centerY + 282)

    M.drawButton("Authors", centerX - 150, centerY - 100, function()
        M.switchToAuthorsScreen()
    end)

    M.drawButton("Continue", centerX - 150, centerY - 200, function()
    end)

    M.drawButton("Exit", centerX - 150, centerY + 0, function()
        love.event.quit()
    end)
    
     M.drawCyberpunkButton(centerX - 75, centerY + 95, function()
        M.currentScreen = "playerStats"
    end)
end

function M.drawGameScreen()
end

function M.drawPlayerStatsScreen()
    local width, height = love.graphics.getDimensions()
    local centerX, centerY = width / 2, height / 2

    M.drawTablet(centerX - M.tabletWidth / 2, centerY - M.tabletHeight / 2, M.tabletWidth, M.tabletHeight)

    local savedScore, savedTime = game_save_load.loadGameProgress()

    local function drawDynamicGradientText(size, text, x, y, align)
        local gradientShader = love.graphics.newShader([[
            extern float time;
            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
                vec4 pixel = Texel(texture, texture_coords);
                float gradient = sin(time + texture_coords.x * 2.0 + texture_coords.y * 1.5);
                return vec4(gradient * 0.8, gradient * 0.5, 1.0, 1.0) * pixel * color;
            }
        ]])

        gradientShader:send("time", love.timer.getTime())

        love.graphics.setShader(gradientShader)
        fonts_manager.drawFontScumbriaRegular(size, { r = 1, g = 1, b = 1 }, text, x, y, align)
        love.graphics.setShader()
    end

    drawDynamicGradientText(
        40,
        "Player Stats",
        centerX - 140,
        centerY - M.tabletHeight / 2 + 40,
        "center"
    )

    local startY = centerY - 50
    local lineHeight = 50

    if savedScore and savedTime then
        drawDynamicGradientText(
            30,
            "Best Score: " .. savedScore,
            centerX - 140,
            startY,
            "center"
        )
        drawDynamicGradientText(
            30,
            "Time Played: " .. time_module.formatTime(savedTime),
            centerX - 140,
            startY + lineHeight,
            "center"
        )
    else
        drawDynamicGradientText(
            30,
            "No saved progress found.",
            centerX,
            startY,
            "center"
        )
    end

    M.drawButton("Back", centerX - 140, centerY + M.tabletHeight / 2 - 100, function()
        M.currentScreen = "menu"
    end, fonts_manager.drawFontScumbriaBold)
end

function M.draw()
    if M.currentScreen == "menu" then
        M.drawMenuScreen()
    elseif M.currentScreen == "authors" then
        M.drawAuthorsScreen()
    elseif M.currentScreen == "game" then
        M.drawGameScreen()
    elseif M.currentScreen == "playerStats" then
        M.drawPlayerStatsScreen()
    end
end

return M