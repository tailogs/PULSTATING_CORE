local M = {}

M.domag = 1

function M.createBullet(cannon, x, y, angle, isCritical)
    local bullet = {
        x = x,
        y = y,
        angle = angle or 0,
        speed = cannon.bulletSpeed,
        rotationSpeed = 5,
        lifeTime = 2,
        size = 4,
        maxSize = 8,
        growthRate = 4,
        color = {1, 0, 0},
        rotation = 0,
        alpha = 1,
        particles = {},
        domag = M.domag,
        isCritical = isCritical,
    }

    if math.random() < 0.1 then
        bullet.isCritical = true
        bullet.domag = bullet.domag * 2
    end

    table.insert(cannon.bullets, bullet)
end

function M.updateParticles(bullet, dt)
    if #bullet.particles < 10 then
        table.insert(bullet.particles, {
            x = bullet.x,
            y = bullet.y,
            size = math.random(2, 5),
            alpha = 1,
            lifeTime = math.random(0.5, 1.5),
            directionX = math.random(-10, 10) / 10,
            directionY = math.random(-10, 10) / 10,
        })
    end

    for i = #bullet.particles, 1, -1 do
        local particle = bullet.particles[i]
        particle.x = particle.x + particle.directionX * dt * 50
        particle.y = particle.y + particle.directionY * dt * 50
        particle.alpha = particle.alpha - (dt / particle.lifeTime)

        if particle.alpha <= 0 then
            table.remove(bullet.particles, i)
        end
    end
end

function M.updateBullets(cannon, dt)
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()

    for i = #cannon.bullets, 1, -1 do
        local bullet = cannon.bullets[i]

        if bullet.angle then
            bullet.x = bullet.x + math.cos(bullet.angle) * bullet.speed * dt  
            bullet.y = bullet.y + math.sin(bullet.angle) * bullet.speed * dt  
        else
            print("Ошибка: bullet.angle равно nil")
            return
        end

        if bullet.rotationSpeed then
            bullet.rotation = (bullet.rotation + (bullet.rotationSpeed * dt) * 0.5) % (2 * math.pi)
        else
            print("Ошибка: bullet.rotationSpeed равно nil для пули", i)
            return
        end

        if bullet.size and bullet.maxSize then 
            if bullet.size < bullet.maxSize then
                bullet.size = bullet.size + bullet.growthRate * dt
            end 
        else 
            print("Ошибка: bullet.size или bullet.maxSize равно nil для пули", i)
            return 
        end

        if bullet.color then 
            bullet.color[1] = math.abs(math.sin(love.timer.getTime() * 2))
            bullet.color[2] = math.abs(math.sin(love.timer.getTime() * 2 + math.pi / 2))
        else 
            print("Ошибка: bullet.color равно nil для пули", i) 
            return 
        end 

        bullet.alpha = math.max(0, bullet.lifeTime / 3)

        M.updateParticles(bullet, dt)

        if bullet.x < 0 or bullet.x > screenWidth or bullet.y < 0 or bullet.y > screenHeight then
            table.remove(cannon.bullets, i)
        end

        bullet.lifeTime = bullet.lifeTime - dt
        if bullet.lifeTime <= 0 then
            table.remove(cannon.bullets, i)
        end
    end 
end

function M.drawParticles(bullet)
    for _, particle in ipairs(bullet.particles) do
        love.graphics.setColor(1, 1, 0, particle.alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
        
        love.graphics.setColor(1, 1, 0, particle.alpha * 0.5)
        love.graphics.circle("fill", particle.x + math.random(-2,2), particle.y + math.random(-2,2), particle.size * 0.5)
    end
end

function M.drawBullets(cannon)
    for _, bullet in ipairs(cannon.bullets) do
        love.graphics.push()
        
        if bullet.color then
            love.graphics.setColor(bullet.color[1], bullet.color[2], 0, bullet.alpha)
        else
            print("Ошибка: bullet.color равно nil")
            love.graphics.setColor(1, 1, 1)
            love.graphics.pop()
            return
        end

        love.graphics.translate(bullet.x, bullet.y)
        love.graphics.rotate(bullet.rotation)
        
        love.graphics.circle("fill", 0, 0, bullet.size)
        
        love.graphics.setColor(1, 1, 0, 0.5)
        for angle = 0, 360, 30 do
            local rad = math.rad(angle)
            local x1 = math.cos(rad) * (bullet.size * 1.5)
            local y1 = math.sin(rad) * (bullet.size * 1.5)
            love.graphics.line(0, 0, x1, y1) 
        end
        
        love.graphics.pop()

        love.graphics.setColor(1, 1, 1, bullet.alpha * 0.3)
        love.graphics.circle("fill", 
                             bullet.x - math.cos(bullet.angle) * (bullet.size + 5), 
                             bullet.y - math.sin(bullet.angle) * (bullet.size + 5), 
                             bullet.size * 0.7)

        M.drawParticles(bullet)
    end

    love.graphics.setColor(1, 1, 1)
end

return M