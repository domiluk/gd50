--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class { __includes = BaseState }

local GOLD_MEDAL = love.graphics.newImage('gold_medal.png')
local SILVER_MEDAL = love.graphics.newImage('silver_medal.png')
local BRONZE_MEDAL = love.graphics.newImage('bronze_medal.png')

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 32, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.print('Score: ' .. tostring(self.score), VIRTUAL_WIDTH / 2.25, 100)

    if self.score >= 30 then
        love.graphics.draw(GOLD_MEDAL, VIRTUAL_WIDTH / 2.75, 75)
    elseif self.score >= 20 then
        love.graphics.draw(SILVER_MEDAL, VIRTUAL_WIDTH / 2.75, 75)
    elseif self.score >= 10 then
        love.graphics.draw(BRONZE_MEDAL, VIRTUAL_WIDTH / 2.75, 75)
    end

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end
