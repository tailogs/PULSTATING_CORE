local M = {}

M.startSound = nil
M.createCubeSound = nil
M.shotSound = nil
M.fillSound = nil
M.scoreSound = nil
M.attackEnemy = nil

M.effectVolume = 1.0
M.previousEffectVolume = 1.0
M.isEffectsMuted = false

M.musicTracks = {}
M.musicTrackNames = {}
M.currentTrackIndex = 1
M.musicVolume = 1.0
M.isMusicMuted = false
M.fadeStartTime = nil

M.isDistorted = false

M.musicAuthors = {}

function M.loadSounds()
    M.startSound = love.audio.newSource("audio/start.wav", "static")
    M.createCubeSound = love.audio.newSource("audio/createCube.wav", "static")
    M.shotSound = love.audio.newSource("audio/shot.wav", "static")
    M.fillSound = love.audio.newSource("audio/fillSound.wav", "static")
    M.scoreSound = love.audio.newSource("audio/score.wav", "static")
    M.attackEnemy = love.audio.newSource("audio/attackEnemy.wav", "static")

    M.loadMusic("audio/background/neri_san/")

    M.setEffectVolume(M.effectVolume)
    M.setMusicVolume(M.musicVolume)
end

function M.toggleDistortion()
    M.isDistorted = not M.isDistorted
    if M.isDistorted then
        M.setEffectPitch(0.8)
        M.setMusicPitch(0.8)
        M.setEffectVolume(0.7)
        M.setMusicVolume(0.7)
    else
        M.setEffectPitch(1.0)
        M.setMusicPitch(1.0)
        M.setEffectVolume(M.effectVolume)
        M.setMusicVolume(M.musicVolume)
    end
end

function M.setEffectPitch(pitch)
    if M.startSound then M.startSound:setPitch(pitch) end
    if M.createCubeSound then M.createCubeSound:setPitch(pitch) end
    if M.shotSound then M.shotSound:setPitch(pitch) end
    if M.fillSound then M.fillSound:setPitch(pitch) end
    if M.scoreSound then M.scoreSound:setPitch(pitch) end
    if M.attackEnemy then M.attackEnemy:setPitch(pitch) end
end

function M.setMusicPitch(pitch)
    for _, track in ipairs(M.musicTracks) do
        track:setPitch(pitch)
    end
end

function M.toggleDistortionDeath()
    M.isDistorted = not M.isDistorted
    if M.isDistorted then
        M.setEffectPitch(0.5)
        M.setMusicPitch(0.5)
        M.setEffectVolume(0.5)
        M.setMusicVolume(0.4)
    else
        M.setEffectPitch(1.0)
        M.setMusicPitch(1.0)
        M.setEffectVolume(M.effectVolume)
        M.setMusicVolume(M.musicVolume)
    end
end

function M.loadMusic(folderPath)
    local lfs = love.filesystem

    local function loadFromFolder(path)
        local files = lfs.getDirectoryItems(path)

        for _, file in ipairs(files) do
            local fullPath = path .. "/" .. file
            local info = lfs.getInfo(fullPath)

            if info.type == "file" and file:match("%.mp3$") then
                local success, track = pcall(love.audio.newSource, fullPath, "stream")
                if success then
                    table.insert(M.musicTracks, track)
                    local trackName = file:match("([^/]+)%.mp3$")
                    table.insert(M.musicTrackNames, trackName)
                end
            elseif info.type == "directory" then
                loadFromFolder(fullPath)
            end
        end
    end

    loadFromFolder(folderPath)

    M.shuffleMusic()

    if #M.musicTracks > 0 then
        M.currentTrackIndex = 1
        M.playCurrentTrack()
    end
end

function M.playCurrentTrack()
    if #M.musicTracks == 0 then return end

    local currentTrack = M.musicTracks[M.currentTrackIndex]
    if currentTrack:isPlaying() then
        currentTrack:stop()
    end

    currentTrack = M.musicTracks[M.currentTrackIndex]
    currentTrack:setVolume(M.musicVolume)
    currentTrack:play()

    local trackName = M.getTrackName()
    print("Now playing: " .. trackName)
end

function M.shuffleMusic()
    for i = #M.musicTracks, 2, -1 do
        local j = math.random(i)
        M.musicTracks[i], M.musicTracks[j] = M.musicTracks[j], M.musicTracks[i]
        M.musicTrackNames[i], M.musicTrackNames[j] = M.musicTrackNames[j], M.musicTrackNames[i]
    end
    return M.musicTrackNames
end

function M.update()
    if #M.musicTracks > 0 then
        local currentTrack = M.musicTracks[M.currentTrackIndex]
        if not currentTrack:isPlaying() then
            M.playNextTrack()
        end
    end
end

function M.setEffectVolume(volume)
    M.effectVolume = volume
    if not M.isEffectsMuted then
        M.startSound:setVolume(volume)
        M.createCubeSound:setVolume(volume)
        M.shotSound:setVolume(volume)
        M.fillSound:setVolume(volume)
        M.scoreSound:setVolume(volume)
        M.attackEnemy:setVolume(volume)
    end
end

function M.setMusicVolume(volume)
    M.musicVolume = volume
    for _, track in ipairs(M.musicTracks) do
        track:setVolume(volume)
    end
end

function M.toggleMusicMute()
    M.isMusicMuted = not M.isMusicMuted
    if M.isMusicMuted then
        for _, track in ipairs(M.musicTracks) do
            track:pause()
        end
    else
        M.playNextTrack()
    end
end

function M.toggleEffectsMute()
    M.isEffectsMuted = not M.isEffectsMuted
    if M.isEffectsMuted then
        M.previousEffectVolume = M.effectVolume
        M.setEffectVolume(0)
    else
        M.setEffectVolume(M.previousEffectVolume)
    end
end

function M.playNextTrack()
    if M.currentTrackIndex > 0 and M.musicTracks[M.currentTrackIndex] then
        M.musicTracks[M.currentTrackIndex]:stop()
    end

    M.currentTrackIndex = M.currentTrackIndex + 1
    if M.currentTrackIndex > #M.musicTracks then
        M.currentTrackIndex = 1
    end

    local nextTrack = M.musicTracks[M.currentTrackIndex]
    nextTrack:setVolume(M.musicVolume)
    nextTrack:play()
end

function M.playStartSound()
    if not M.isEffectsMuted and M.startSound then
        M.startSound:play()
    end
end

function M.playCreateCubeSound()
    if not M.isEffectsMuted and M.createCubeSound then
        M.createCubeSound:play()
    end
end

function M.playShotSound()
    if not M.isEffectsMuted and M.shotSound then
        M.shotSound:play()
    end
end

function M.playFillSound()
    if not M.isEffectsMuted and M.fillSound then
        M.fillSound:play()
    end
end

function M.playScoreSound()
    if not M.isEffectsMuted and M.scoreSound then
        M.scoreSound:play()
    end
end

function M.playAttackEnemy()
    if not M.isEffectsMuted and M.attackEnemy then
        M.attackEnemy:play()
    end
end

function M.getCurrentTrack()
    return M.musicTracks[M.currentTrackIndex]
end

function M.getMusicSpectrum(fftSize)
    if #M.musicTracks > 0 then
        local track = M.musicTracks[M.currentTrackIndex]
        if track and track:isPlaying() then
            if love.audio.getSpectrum then
                return love.audio.getSpectrum(fftSize, "normal")
            else
                print("Error: love.audio.getSpectrum is unavailable.")
            end
        else
            print("Error: Track is not playing.")
        end
    end
    return {}
end

function M.getTrackName()
    if #M.musicTracks > 0 and M.currentTrackIndex > 0 and M.currentTrackIndex <= #M.musicTrackNames then
        return "Neri San – " .. M.musicTrackNames[M.currentTrackIndex]
    end
    return "Unknown Track"
end

function M.drawMusicControls()
    local buttonSize = 50
    local padding = 10
    local screenWidth, screenHeight = love.graphics.getDimensions()

    local function drawGradientButtonOutline(x, y, width, height)
        local startColor = {0, 0, 1}
        local endColor = {0.5, 0, 1}
        
        love.graphics.setLineWidth(1)
        love.graphics.setColor(startColor)
        love.graphics.rectangle("line", x, y, width, height)
        love.graphics.setColor(endColor)
        love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2)
    end

    local buttonX = screenWidth - buttonSize - padding
    local buttons = {
        {label = "Stop", x = buttonX, y = padding},
        {label = "Next", x = buttonX - buttonSize - padding, y = padding},
        {label = "Prev", x = buttonX - 2 * (buttonSize + padding), y = padding},
    }

    for _, button in ipairs(buttons) do
        drawGradientButtonOutline(button.x, button.y, buttonSize, buttonSize)
    end

    love.graphics.setColor(0.5, 0, 1)
    love.graphics.polygon("fill", 
        buttonX + buttonSize * 0.25, padding + buttonSize * 0.25, 
        buttonX + buttonSize * 0.75, padding + buttonSize * 0.5, 
        buttonX + buttonSize * 0.25, padding + buttonSize * 0.75)

    love.graphics.setColor(0, 0, 1)
    love.graphics.polygon("fill", 
        buttonX - 2 * (buttonSize + padding) + buttonSize * 0.75, padding + buttonSize * 0.25, 
        buttonX - 2 * (buttonSize + padding) + buttonSize * 0.25, padding + buttonSize * 0.5, 
        buttonX - 2 * (buttonSize + padding) + buttonSize * 0.75, padding + buttonSize * 0.75)

    love.graphics.setColor(0.5, 0, 1)
    love.graphics.polygon("fill", 
        buttonX - buttonSize - padding + buttonSize * 0.4, padding + buttonSize * 0.35,  
        buttonX - buttonSize - padding + buttonSize * 0.6, padding + buttonSize * 0.5, 
        buttonX - buttonSize - padding + buttonSize * 0.4, padding + buttonSize * 0.65)

    love.graphics.setColor(0, 0, 1)
    love.graphics.setLineWidth(3)
    love.graphics.line(buttonX - buttonSize - padding + buttonSize * 0.7, padding + buttonSize * 0.35,
                      buttonX - buttonSize - padding + buttonSize * 0.7, padding + buttonSize * 0.65)
    love.graphics.line(buttonX - buttonSize - padding + buttonSize * 0.8, padding + buttonSize * 0.35,
                      buttonX - buttonSize - padding + buttonSize * 0.8, padding + buttonSize * 0.65)

    local trackName = M.getTrackName()
    local font = love.graphics.newFont(20)
    love.graphics.setFont(font)
    
    local textWidth = font:getWidth(trackName)
    
    local textX = screenWidth - textWidth - 10
    if textWidth > screenWidth then
        textX = screenWidth - textWidth
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(trackName, textX, padding + buttonSize + 10)
end

function M.playPreviousTrack()
    if #M.musicTracks == 0 then return end

    if M.currentTrackIndex > 0 and M.musicTracks[M.currentTrackIndex] then
        M.musicTracks[M.currentTrackIndex]:stop()
    end

    M.currentTrackIndex = M.currentTrackIndex - 1
    if M.currentTrackIndex < 1 then
        M.currentTrackIndex = #M.musicTracks
    end

    local prevTrack = M.musicTracks[M.currentTrackIndex]
    prevTrack:setVolume(M.musicVolume)
    prevTrack:play()
end

function M.handleMousePress(x, y)
    if someCondition then
        M.toggleMusicMute()
    end
end

return M