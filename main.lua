debug = true

--timery
--zakładamy że są tu więc nie będziemy musieli zmieniać ich wartości w każdym miejscu
canShoot = true
canShootTimerMax = 0.2
canShootTimer = canShootTimerMax
createEnemyTimerMax = 0.4
createEnemyTimer = createEnemyTimerMax

--objekt gracza
player = { x = 200, y = 710, speed = 150, img = nil }
isAlive = true
score = 0

--pamięć grafiki
bulletImg = nil
enemyImg = nil

--pamięć dźwięku
gunSound = nil

--pamięć jednostek(pojawiających się na ekranie)
bullets = {} --tablica aktualnych pocisków, które są pobierane i aktualizowane
enemies = {} --tablica wrogów, którzy znajdują się na ekranie

--funkcja detekcji kolizji
--zwraca prawdę jeżeli dwa boxy(statki) się na siebie nakładają, fałsz jeśli nie
-- x1, y1 to lewy górny pasek pierwszego pudełka, podczas gdy w1, h1 to jego szerokość i wysokość
-- x2, y2, w2 & h2 są takie same, ale dla drugiego pudełka
--więcej o tej funkcji przeczytasz tu: https://love2d.org/wiki/BoundingBox.lua
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and
           x2 < x1+w1 and
           y1 < y2+h2 and
           y2 < y1+h1
  end

--wczytywanie (następuje tylko raz)
function love.load(arg)
    player.img = love.graphics.newImage('assets/plane.png')
    enemyImg = love.graphics.newImage('assets/enemy.png')
    bulletImg = love.graphics.newImage('assets/bullet.png')
    gunSound = love.audio.newSource("assets/gun-sound.wav", "static")
end

--odświeżanie, następuje w każdej sekundzie gry
function love.update(dt)
    --warto zacząć od łatwego wyjścia z gry
    if love.keyboard.isDown('escape') then
        love.event.push('quit')
    end

    --odstęp czasu w jakim będziesz mógł strzelać
    canShootTimer = canShootTimer - (1 * dt)
    if canShootTimer < 0 then 
        canShoot = true 
    end

    --czas na stworzenie wroga
    createEnemyTimer = createEnemyTimer - (1 * dt)
    if createEnemyTimer < 0 then
        createEnemyTimer = createEnemyTimerMax

        --stwórz wroga
        randomNumber = math.random(10, love.graphics.getWidth() - 10)
        newEnemy = { x = randomNumber, y = -10, img = enemyImg }
        table.insert(enemies, newEnemy)
    end
    
    --aktualizacja pozycji pocisków
    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - (250 * dt)

        if bullet.y < 0 then --usuwanie pocisków kiedy znikną za ekranem
            table.remove(bullets, i)
        end
    end

    --aktualizacja pozycji przeciwników
    for i, enemy in ipairs(enemies) do
        enemy.y = enemy.y + (200 * dt)

        if enemy.y > 850 then --usuwanie przeciwników kiedy znikną poza ekranem
            table.remove(enemies, i)
        end
    end

    --uruchamia nasze wykrywanie kolizji
    -- Ponieważ na ekranie będzie mniej wrogów niż kul, najpierw ich zapętlimy
    -- Musimy też sprawdzić, czy wrogowie uderzyli w naszego gracza
    for i, enemy in ipairs(enemies) do
        for j, bullet in ipairs(bullets) do
            if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                table.remove(bullets, j)
                table.remove(enemies, i)
                score = score + 1
            end
        end

        if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight())
        and isAlive then
            table.remove(enemies, i)
            isAlive = false
        end
    end

    --ruch poziomy
    if love.keyboard.isDown('left', 'a') then
        if player.x > 0 then --blokuje nas na mapie
            player.x = player.x - (player.speed * dt)
        end
    elseif love.keyboard.isDown('right', 'd') then
        if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
            player.x = player.x + (player.speed * dt)
        end
    end

    --ruch pionowy
    if love.keyboard.isDown('up', 'w') then
        if player.y > (love.graphics.getHeight() / 2) then
            player.y = player.y - (player.speed * dt)
        end

    elseif love.keyboard.isDown('down', 's') then
        if player.y < (love.graphics.getHeight() - 55) then
            player.y = player.y + (player.speed * dt)
        end
    end

    if love.keyboard.isDown('backspace', 'rctrl', 'lctrl') and canShoot then
        --stwórz nowe pociski
        newBullet = { x = player.x +(player.img:getWidth() / 2), y = player.y, img = bulletImg }
        table.insert(bullets, newBullet)
        gunSound:play()
        canShoot = false
        canShootTimer = canShootTimerMax
    end

    if not isAlive and love.keyboard.isDown('r') then
        --usuń wszystkie pociski i wrogów z ekranu
        bullets = {}
        enemies = {}

        --zresetuj timery
        canShootTimer = canShootTimerMax
        createEnemyTimer = createEnemyTimerMax

        --wróć gracza do początkowej pozycji 
        player.x = 50
        player.y = 710

        --zresetuj dane gry
        score = 0 
        isAlive = true
    end
end

--rysowanie
function love.draw(dt)
    for i, bullet in ipairs(bullets) do
        love.graphics.draw(bullet.img, bullet.x, bullet.y)
    end

    for i, enemy in ipairs(enemies) do
        love.graphics.draw(enemy.img, enemy.x, enemy.y)
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("SCORE: " .. tostring(score), 400, 10)

    if isAlive then
        love.graphics.draw(player.img, player.x, player.y)
    else
        love.graphics.print("Nacisnij R zeby zrestartowac", love.graphics:getWidth() / 2 - 80, love.graphics:getHeight() / 2 - 10)
    end

    if debug then
        fps = tostring(love.timer.getFPS())
        love.graphics.print("Aktualny FPS: "..fps, 9, 10)
    end
end