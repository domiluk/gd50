--[[
    GD50 2018
    Pong Remake

    -- Main Program --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.
]]

-- push allows us to draw our game at a virtual resolution, instead of
-- however large our window is. https://github.com/Ulydev/push
push = require 'push'

-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

require 'Paddle'
require 'Ball'

-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
-- size we're trying to emulate with push
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
CENTER_X = VIRTUAL_WIDTH / 2
CENTER_Y = VIRTUAL_HEIGHT / 2

-- game constants
PADDLE_SPEED = 200
PADDLE_WIDTH = 5
PADDLE_HEIGHT = 20
BALL_SIZE = 4

function love.load()
    math.randomseed(os.time())
    love.window.setTitle('Pong')
    love.graphics.setDefaultFilter('nearest', 'nearest') -- nearest-neighbor filtering for a nice crisp 2D look

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    paddle1 = Paddle(10, 30, PADDLE_WIDTH, PADDLE_HEIGHT) -- x y w h
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, PADDLE_WIDTH, PADDLE_HEIGHT) -- x y w h

    ball = Ball(CENTER_X - BALL_SIZE / 2, CENTER_Y - BALL_SIZE / 2, BALL_SIZE, BALL_SIZE) -- x y w h

    player1IsAI = false
    player2IsAI = false

    player1Score = 0
    player2Score = 0

    servingPlayer = 1 -- either going to be 1 or 2
    winningPlayer = 0 -- not set to a proper value until the game is over

    -- the state of our game; can be any of the following:
    -- 1. 'start' (the beginning of the game, before first serve)
    -- 2. 'serve' (waiting on a key press to serve the ball)
    -- 3. 'play' (the ball is in play, bouncing between paddles)
    -- 4. 'gameover' (the game is over, with a victor, ready for restart)
    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt) -- `dt` is measured in seconds.
    if gameState == 'play' then
        detectPaddleHit()
        detectScreenBounce()
        detectScoringAPoint()
    end

    updatePaddles(dt)

    if gameState == 'play' then
        ball:update(dt)
    end
end

function detectPaddleHit()
    if ball:collides(paddle1) then
        ball.x = paddle1.x + paddle1.width
        -- bounce the ball, make x-velocity just a bit faster
        ball.dx = -ball.dx * 1.03
        -- keep y-velocity going in the same direction but randomly
        ball.dy = (ball.dy < 0 and -1 or 1) * math.random(10, 150)
        sounds['paddle_hit']:play()
    end
    if ball:collides(paddle2) then
        ball.x = paddle2.x - BALL_SIZE
        -- bounce the ball, make x-velocity just a bit faster
        ball.dx = -ball.dx * 1.03
        -- keep y-velocity going in the same direction but randomly
        ball.dy = (ball.dy < 0 and -1 or 1) * math.random(10, 150)
        sounds['paddle_hit']:play()
    end
end

function detectScreenBounce()
    -- detect TOP screen boundary collision
    if ball.y <= 0 then
        ball.y = 0
        ball.dy = -ball.dy
        sounds['wall_hit']:play()
    end
    -- detect BOTTOM screen boundary collision
    if ball.y >= VIRTUAL_HEIGHT - BALL_SIZE then
        ball.y = VIRTUAL_HEIGHT - BALL_SIZE
        ball.dy = -ball.dy
        sounds['wall_hit']:play()
    end
end

function detectScoringAPoint()
    -- detect LEFT screen boundary collision
    if ball.x < 0 then
        servingPlayer = 1
        player2Score = player2Score + 1
        sounds['score']:play()

        if player2Score == 10 then
            gameState = 'gameover'
            winningPlayer = 2
        else
            gameState = 'serve'
            ball:reset()
        end
    end
    -- detect RIGHT screen boundary collision
    if ball.x > VIRTUAL_WIDTH then
        servingPlayer = 2
        player1Score = player1Score + 1
        sounds['score']:play()

        if player1Score == 10 then
            gameState = 'gameover'
            winningPlayer = 1
        else
            gameState = 'serve'
            ball:reset()
        end
    end
end

function updatePaddles(dt)
    paddle1.dy = 0
    paddle2.dy = 0

    if player1IsAI then
        if gameState == 'serve' or gameState == 'play' then
            local paddleCenter = paddle1.y + PADDLE_HEIGHT / 2
            local yDistToBall = paddleCenter - ball.y
            if ball.dx <= 0 and math.abs(yDistToBall) > PADDLE_HEIGHT / 4 then
                paddle1.dy = (yDistToBall > 0 and -1 or 1) * PADDLE_SPEED
            end
        end
    else
        -- player controlled paddles can move no matter what state we're in
        if love.keyboard.isDown('w') then
            paddle1.dy = -PADDLE_SPEED
        end
        if love.keyboard.isDown('s') then
            paddle1.dy = PADDLE_SPEED
        end
    end

    if player2IsAI then
        if gameState == 'serve' or gameState == 'play' then
            local paddleCenter = paddle2.y + PADDLE_HEIGHT / 2
            local yDistToBall = paddleCenter - ball.y
            if ball.dx >= 0 and math.abs(yDistToBall) > PADDLE_HEIGHT / 4 then
                paddle2.dy = (yDistToBall > 0 and -1 or 1) * PADDLE_SPEED
            end
        end
    else
        -- player controlled paddles can move no matter what state we're in
        if love.keyboard.isDown('up') then
            paddle2.dy = -PADDLE_SPEED
        end
        if love.keyboard.isDown('down') then
            paddle2.dy = PADDLE_SPEED
        end
    end

    paddle1:update(dt)
    paddle2:update(dt)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'

        elseif gameState == 'serve' then
            gameState = 'play'
            -- initialize ball's direction based on player who last scored
            ball.dx = ((servingPlayer == 1) and 1 or -1) * math.random(140, 200)
            ball.dy = math.random(-50, 50)

        elseif gameState == 'gameover' then
            gameState = 'serve'
            ball:reset()
            player1Score = 0
            player2Score = 0
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    elseif key == 'f1' and gameState == 'start' then
        player1IsAI = not player1IsAI
    elseif key == 'f2' and gameState == 'start' then
        player2IsAI = not player2IsAI
    end
end

function love.draw()
    push:apply('start') -- begin drawing, in our virtual resolution

    love.graphics.clear(40/255, 45/255, 52/255, 255/255)
    
    displayUIMessages()
    displayScore()

    paddle1:render()
    paddle2:render()
    if gameState ~= 'start' then
        ball:render()
    end

    displayFPS()

    push:apply('end') -- end drawing
end

function displayUIMessages()
    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 110, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 120, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Player1 (' .. (player1IsAI and 'AI' or 'W/S') .. ')    Player2 (' .. (player2IsAI and 'AI' or 'UP/DOWN') .. ')', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press F1 or F2 for AI', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
    elseif gameState == 'gameover' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 40)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, 40)
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end
