local math_utils = require("math_utils")
local impact_effects = require("impact_effects")
local bullet_module = require("bullet")
local enemy_module = require("enemy")
local cannon_module = require("cannon")
local background = require("background")
local wave_module = require("wave")
local animation_module = require("animation")
local game_state = require("game_state")
local sound_module = require("sound")
local score_module = require("score")
local menu = require("menu")
local fonts_manager = require("fonts")
local enhancements = require("enhancements")
local game_save_load = require("game_save_load")

local gameOverScreenInitialized = false
local cachedGameOverText = {}

function cleanupGameObjects()
    cannon_module.clearBullets()
    enemy_module.clearEnemies()
    wave_module.clearWaves()
    impact_effects.clearEffects()
end

function love.load()
    math.randomseed(os.time())
    math.random()

    love.window.setFullscreen(true)

    local icon = love.image.newImageData("image/icon.png")
    love.window.setIcon(icon)
    love.window.setTitle("Pulsating Core")
    
    background.load()

    animation_module.initializeSquares()
    sound_module.loadSounds()
    sound_module.setMusicVolume(game_state.volume)

    sound_module.playNextTrack()

    score_module.updateTextVisibility(0)

    enhancements.createButtons()

    local savedScore, savedTime = game_save_load.loadGameProgress()
    if savedScore then
        print("Best Score: " .. savedScore .. " at " .. savedTime .. " seconds")
    end
end

function love.update(dt)
    if game_state.isGameOver then
        sound_module.toggleDistortionDeath()
        return
    end

    if menu.isOpen then
        return
    end

    game_state.t_dt = dt
    game_state.elapsedTime = game_state.elapsedTime + dt
    if game_state.elapsedTime < game_state.startDelay then
        return
    end

    if game_state.startGame then
        game_state.startGame = false
        sound_module.playStartSound()
    end

    game_state.updateGameTime(dt)
    background.update(dt)
    animation_module.updateAnimation(dt)

    if game_state.elapsedTime >= animation_module.smallSquareGrowthTime then
        if not game_state.mainAnimationStarted then
            game_state.mainAnimationStarted = true
        end

        if animation_module.smallSquareCount > 10 and not game_state.waveCreated then
            wave_module.createWave(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
            game_state.waveCreated = true
            sound_module.playCreateCubeSound()
        end

        animation_module.updateSquares(dt)
    end

    if game_state.mainAnimationStarted then
        cannon_module.updateCannon(game_state.elapsedTime, enemy_module, math_utils, bullet_module, impact_effects, dt)
        bullet_module.updateBullets(cannon_module.cannon, dt)
    end

    wave_module.updateWaves(dt)
    enemy_module.updateEnemy(dt)

    enemy_module.attackCannon(cannon_module.cannon) 

    local spawnData = enemy_module.getSpawnData()

    if enemy_module.enemySpawnTime < spawnData.spawnInterval then
        enemy_module.enemySpawnTime = enemy_module.enemySpawnTime + dt
    else
        local spawnX, spawnY
        local safeRadius = 500

        repeat
            spawnX = math.random(100, love.graphics.getWidth() - 100)
            spawnY = math.random(100, love.graphics.getHeight() - 100)
        until enemy_module.isOutsideSafeRadius(spawnX, spawnY, safeRadius)

        enemy_module.createEnemy(spawnX, spawnY)
        enemy_module.enemySpawnTime = 0

        print(spawnData.additionalInfo)
    end

    impact_effects.updateImpactEffects(dt)
    score_module.updateTextVisibility(dt)
    score_module.animateScore(dt)
    score_module.updateParticles(dt)

    if enemy_module.enemyDestroyed then
        score_module.addScore(100, love.mouse.getX(), love.mouse.getY())
    end

    if cannon_module.cannon.health <= 0 then
        game_state.isGameOver = true
        cleanupGameObjects()
    end
    
    if not sound_module.isMusicMuted then
        sound_module.update()
    end

    enhancements.update(dt)
end


function love.draw()
    if game_state.isGameOver then
        drawGameOverScreen()
        return
    end

    background.draw()
    animation_module.drawSquares()

    if game_state.mainAnimationStarted then
        wave_module.drawWaves()
        enemy_module.drawEnemy()
        cannon_module.drawCannon()
        bullet_module.drawBullets(cannon_module.cannon)
    end

    impact_effects.drawImpactEffects()
    score_module.drawScore()

    if menu.isOpen then
        menu.draw(game_state.t_dt)
    end

    sound_module.drawMusicControls()

    enhancements.draw()
end

function love.keypressed(key)
    if key == "escape" then
        if menu.currentScreen == "authors" then
            menu.currentScreen = "menu"
        elseif menu.currentScreen == "playerStats" then
            menu.currentScreen = "menu"
        else
        end
        menu.isOpen = not menu.isOpen
        game_state.isPaused = not game_state.isPaused
        sound_module.toggleDistortion()
    end

    if key == "r" and game_state.isGameOver then
        game_save_load.handleGameOver()
        restartGame()
    end

    if key == "m" then
        sound_module.toggleMusicMute()
    elseif key == "p" then
        local currentTrack = sound_module.getCurrentTrack()
        if currentTrack:isPlaying() then
            currentTrack:pause()
        else
            currentTrack:play()
        end
    elseif key == "right" then
        if not menu.isMuted then
            sound_module.playNextTrack()
        end
    elseif key == "left" then
        if not menu.isMuted then
            sound_module.playPreviousTrack()
        end
    end

    if key == "+" then
        sound_module.setMusicVolume(sound_module.musicVolume + 0.1)
    elseif key == "-" then
        sound_module.setMusicVolume(sound_module.musicVolume - 0.1)
    end
end

function love.quit()
    if game_state.isGameOver then
        game_save_load.handleGameOver()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    sound_module.handleMousePress(x, y)
    enhancements.mousepressed(x, y, button, istouch, presses)

    if love.mouse.isDown(1) and not cannon_module.cannon.isReloading then
        cannon_module.attackPlayerCannon(game_state.t_dt)
    end
end

function formatGameTime(seconds)
    local weeks = math.floor(seconds / (60 * 60 * 24 * 7))
    local days = math.floor((seconds % (60 * 60 * 24 * 7)) / (60 * 60 * 24))
    local hours = math.floor((seconds % (60 * 60 * 24)) / (60 * 60))
    local minutes = math.floor((seconds % (60 * 60)) / 60)
    local secs = math.floor(seconds % 60)

    local timeParts = {}

    if weeks > 0 then
        table.insert(timeParts, weeks .. "w")
    end
    if days > 0 then
        table.insert(timeParts, days .. "d")
    end
    if hours > 0 then
        table.insert(timeParts, string.format("%02dh", hours))
    end
    if minutes > 0 then
        table.insert(timeParts, string.format("%02dm", minutes))
    end
    if secs > 0 then
        table.insert(timeParts, string.format("%02ds", secs))
    end

    return table.concat(timeParts, " ")
end

function drawGameOverScreen()
    if not gameOverScreenInitialized then
        local canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setCanvas(canvas)
        love.graphics.clear()

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        local shadowOffset = 5
        fonts_manager.drawFontScumbriaBold(
            64,
            {r = 0, g = 0, b = 0, a = 0.7},
            "GAME OVER",
            love.graphics.getWidth() / 2 - 150 + shadowOffset,
            love.graphics.getHeight() / 3 + shadowOffset
        )
        fonts_manager.drawFontScumbriaBold(
            64,
            {r = 0.8, g = 0.2, b = 0.2},
            "GAME OVER",
            love.graphics.getWidth() / 2 - 150,
            love.graphics.getHeight() / 3
        )

        fonts_manager.drawFontScumbriaRegular(
            28,
            {r = 0, g = 0, b = 0, a = 0.7},
            "Press R to Restart",
            love.graphics.getWidth() / 2 - 100 + shadowOffset,
            love.graphics.getHeight() / 2 + 50 + shadowOffset
        )
        fonts_manager.drawFontScumbriaRegular(
            28,
            {r = 1, g = 1, b = 1},
            "Press R to Restart",
            love.graphics.getWidth() / 2 - 100,
            love.graphics.getHeight() / 2 + 50
        )

        local formattedTime = formatGameTime(game_state.elapsedTime)
        fonts_manager.drawFontScumbriaRegular(
            28,
            {r = 1, g = 1, b = 1},
            "Time: " .. formattedTime,
            love.graphics.getWidth() / 2 - 100,
            love.graphics.getHeight() / 2 + 100
        )

        fonts_manager.drawFontScumbriaRegular(
            28,
            {r = 1, g = 1, b = 1},
            "Score: " .. score_module.getScore(),
            love.graphics.getWidth() / 2 - 100,
            love.graphics.getHeight() / 2 + 140
        )

        love.graphics.setCanvas()
        cachedGameOverText.canvas = canvas
        gameOverScreenInitialized = true
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(cachedGameOverText.canvas)

    if not cachedGameOverText.colorUpdated then
        local time = love.timer.getTime()
        local r = 0.8 + math.sin(time) * 0.1
        fonts_manager.drawFontScumbriaBold(
            64,
            {r = r, g = 0.2, b = 0.2},
            "GAME OVER",
            love.graphics.getWidth() / 2 - 150,
            love.graphics.getHeight() / 3
        )
        cachedGameOverText.colorUpdated = true
    end
end

function restartGame()
    love.event.quit("restart")
end
