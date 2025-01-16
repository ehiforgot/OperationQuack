-- Levels File
local conf = require("conf")

local levels = conf.loadLevels()
local player = { x = 1, y = 1 }
local level = 10 -- Keeps track of current level
local totalLevels = 0
local TILE_SIZE = 32 -- Tile size in pixels
local score = 0 -- Current score
local entryScore = 0 -- Score at the start of the level
local userInput = ""
local dotCount = 0
local solved = 0
local doorLock = false

-- Grid dimensions
local GRID_WIDTH = 19
local GRID_HEIGHT = 17 

-- Game state
local resetStatus = {} -- Tracks whether each level has been reset
local levelsCompletedWithoutReset = {} -- Tracks levels completed without reset
local totalLevelsCompletedWithoutReset = 0 -- Final count of levels completed without reset
local state = "menu" -- Inital state is "menu": {menu, howToPlay, leaderboard, highscore, game, end}

-- Button dimensions
local buttonWidth = 150
local buttonHeight = 50

local button1X = (GRID_WIDTH * TILE_SIZE) / 2 - buttonWidth / 2 -- Position 1
local button1Y = (GRID_HEIGHT * TILE_SIZE) / 2 + 50
local button2X = (GRID_WIDTH * TILE_SIZE) / 2 - buttonWidth / 2 -- Position 2
local button2Y = (GRID_HEIGHT * TILE_SIZE) / 2 + 110
local button3X = (GRID_WIDTH * TILE_SIZE) / 2 - buttonWidth / 2 -- Position 3
local button3Y = (GRID_HEIGHT * TILE_SIZE) / 2 + 170
local button4X = (GRID_WIDTH * TILE_SIZE) / 2 - buttonWidth / 2 -- Position 4
local button4Y = (GRID_HEIGHT * TILE_SIZE) / 2 + 230
local button5X = TILE_SIZE - 10
local button5Y = 2
local button6X = TILE_SIZE * 14 - 10
local button6Y = 2

--local resetButtonX = (GRID_WIDTH * TILE_SIZE) - buttonWidth - 10
--local resetButtonY = GRID_HEIGHT * TILE_SIZE + 10
--local exitButtonX = (GRID_WIDTH * TILE_SIZE) / 2 - buttonWidth / 2
--local exitButtonY = GRID_HEIGHT * TILE_SIZE / 2 + 108
--local startButtonX = (GRID_WIDTH * TILE_SIZE) / 2 - buttonWidth / 2
--local startButtonY = (GRID_HEIGHT * TILE_SIZE) / 2 + 50
--local howToPlayButtonX = button1X
--local howToPlayButtonY = button1Y + buttonHeight + 10
--local menuButtonX = button1X
--local menuButtonY = GRID_HEIGHT * TILE_SIZE - buttonHeight - 20
--local leaderboardButtonX = button1X
--local leaderboardButtonY = howToPlayButtonY + buttonHeight + 10
local confirmButtonX = button1X
local confirmButtonY = GRID_HEIGHT * TILE_SIZE - buttonHeight - 20

local keypadButtonX = TILE_SIZE * 13
local keypadButtonY = TILE_SIZE * 17 + 5


-- Gif Data
local duckFrames = {}
local currentDuckFrame = 1
local duckFrameTime = 0.3 -- Set fps of GIF
local duckTimer = 0
local function loadPlayerGif()
    for i = 1, 2 do
        table.insert(duckFrames, love.graphics.newImage("images/duckGif/frame_" .. string.format("%d", i) .. ".png"))
    end
end
local skyFrames = {}
local currentSkyFrame = 1
local skyFrameTime = 0.8
local skyTimer = 0
local function loadSkyGif()
    for i = 1, 55 do
        table.insert(skyFrames, love.graphics.newImage("images/skyGif/frame_" .. string.format("%02d", i) .. ".png"))
    end
end
local keyFrames = {}
local currentKeyFrame = 1
local keyFrameTime = 0.2
local keyTimer = 0
local function loadKeyGif()
    for i = 1 , 8 do
        table.insert(keyFrames, love.graphics.newImage("images/keyGif/frame_" .. string.format("%d", i) .. ".png"))
    end
end

-- Image Data
local images = {}
local imageNames = {"arcade", "dragon", "grapes", "no", "lock", "ladder", "door1", "door2", "floor", "fire", "wall1", "wall2", "bridge", "dirt1", "dirt2", "stand"} -- INCLUDE ANY /images/...".png"

local function loadImage() -- Load File
    for _, imageName in ipairs(imageNames) do
        local imagePath = "images/" .. imageName .. ".png"
        local info = love.filesystem.getInfo(imagePath)
        if info then
            images[imageName] = love.graphics.newImage(imagePath)
        else
            return 404
        end
    end
end

-- Draw background function
local function drawBackground()
    if images["wall2"] then
        love.graphics.setColor(1, 1, 1)
        local screenWidth = (18 * TILE_SIZE)
        local screenHeight = (24 * TILE_SIZE)
        local imageWidth = images["wall2"]:getWidth()
        local imageHeight = images["wall2"]:getHeight()

        -- Scale image to TILE_SIZE
        local scaleX = TILE_SIZE / imageWidth
        local scaleY = TILE_SIZE / imageHeight

        -- Tile image across the screen
        for y = 0, screenHeight, TILE_SIZE do
            for x = 0, screenWidth, TILE_SIZE do
                love.graphics.draw(images["wall2"], x, y, 0, scaleX, scaleY)
            end
        end
    end
end

-- Draw space for text function
local function drawBackgroundText()
    love.graphics.setColor(0, 0, 0) -- Black background
    love.graphics.rectangle("fill", TILE_SIZE * 1, TILE_SIZE * 2, TILE_SIZE * 17, TILE_SIZE * 16)
end

-- Draw arcade overlay
local function drawArcade()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images["arcade"], 0, 0, 0, TILE_SIZE * 19 / images["arcade"]:getWidth(), TILE_SIZE * 25 / images["arcade"]:getHeight())
end

-- Leaderboard data
local leaderboard = {}
--local leaderboardFilePath = love.filesystem.getSource() .. "/leaderboard.txt"

local function initializeLeaderboard() -- Initialize leaderboard if none found
    if not love.filesystem.getInfo("leaderboard.txt") then
        table.insert(leaderboard, { name = "DEV", score = 834 })
        table.insert(leaderboard, { name = "DFV", score = 831 })
        table.insert(leaderboard, { name = "LEX", score = 823 })
        table.insert(leaderboard, { name = "MIM", score = 719 })
        table.insert(leaderboard, { name = "NJV", score = 640 })
    end
end

local function loadLeaderboard() -- Load File
    leaderboard = {} -- Clear to prevent duplicates
    if love.filesystem.getInfo("leaderboard.txt") then
        for line in love.filesystem.lines("leaderboard.txt") do
            local name, score = line:match("(%a+)%s+(%d+)")
            if name and score then
                table.insert(leaderboard, { name = name, score = tonumber(score)})
            end
        end
        table.sort(leaderboard, function(a, b) return a.score > b.score end)
    end
end

local function saveLeaderboard() -- Save File
    local fileData = ""
    for _, entry in ipairs(leaderboard) do
        fileData = fileData .. string.format("%s %d\n", entry.name, entry.score)
    end
    love.filesystem.write("leaderboard.txt", fileData)
end

-- Maintain Gif render
function love.update(dt)
    duckTimer = duckTimer + dt
    skyTimer = skyTimer + dt
    keyTimer = keyTimer + dt
    if duckTimer >= duckFrameTime then
        duckTimer = duckTimer - duckFrameTime
        currentDuckFrame = currentDuckFrame % #duckFrames + 1
    end
    if skyTimer >= skyFrameTime then
        skyTimer = skyTimer - skyFrameTime
        currentSkyFrame = currentSkyFrame % #skyFrames + 1
    end
    if keyTimer >= keyFrameTime then
        keyTimer = keyTimer - keyFrameTime
        currentKeyFrame = currentKeyFrame % #keyFrames + 1
    end
end

-- Initialize game
function love.load()
    levels = conf.loadLevels()
    totalLevels = 0

    for key, value in pairs(levels) do
        totalLevels = totalLevels + 1
    end

    initializeLeaderboard()
    loadPlayerGif()
    loadSkyGif()
    loadKeyGif()
    loadImage()
    loadLeaderboard()
    if resetStatus[level] == nil then
        resetStatus[level] = false -- Initialize reset tracking
    end
    if levelsCompletedWithoutReset[level] == nil then
        levelsCompletedWithoutReset[level] = false -- Initialize completion tracking
    end
    entryScore = score -- Save the entry score
    grid = levels[level].grid
    -- Find start position
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x] == "S" then
                player.x = x
                player.y = y
            end
            if grid[y][x] == "." or grid[y][x] == "K" or grid[y][x] == "L" or grid[y][x] == "S" or grid[y][x] == "," then
                dotCount = dotCount + 1
            elseif grid[y][x] == "B" then
                dotCount = dotCount + 2
            end
        end
    end
end

-- Draw game state
function love.draw()
    drawBackground()
    drawArcade()

    --Draw main menu
    if state == "menu" then
        love.graphics.setColor(0, 0, 0) -- Black background
        love.graphics.rectangle("fill", TILE_SIZE * 5, TILE_SIZE * 4, TILE_SIZE * 9, TILE_SIZE * 1)

        -- Draw Title
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(32)
        love.graphics.printf("Operation Quack.", 0, (TILE_SIZE * 4) - 4, (GRID_WIDTH * TILE_SIZE) + 2, "center")

        -- Draw the Start button
        love.graphics.setColor(0.2, 0.8, 0.2) -- Green button
        love.graphics.rectangle("fill", button1X, button1Y, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.setNewFont(16)
        love.graphics.printf("Start", button1X, button1Y + (buttonHeight / 2) - 10, buttonWidth, "center")

        --Draw the How To Play button
        love.graphics.setColor(0.2, 0.2, 0.2) -- Dark grey button
        love.graphics.rectangle("fill", button2X, button2Y, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.setNewFont(16)
        love.graphics.printf("How To Play?", button2X, button2Y + 15, buttonWidth, "center")

        -- Draw the Leaderboard button
        love.graphics.setColor(0.2, 0.2, 0.8) -- Blue button
        love.graphics.rectangle("fill", button3X, button3Y, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.printf("Leaderboard", button3X, button3Y + (buttonHeight / 2) - 10, buttonWidth, "center")
        
        

    -- Draw instrucstions screen
    elseif state == "howToPlay" then
        yPos = GRID_HEIGHT * TILE_SIZE / 4 - 10
        drawBackgroundText()
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(30)
        love.graphics.printf("How To Play?", 0, yPos, GRID_WIDTH * TILE_SIZE, "center")

        yPos = yPos + 100 -- Adjust y position for next line
        love.graphics.setNewFont(14)
        love.graphics.printf("Objective:", 70, yPos, GRID_WIDTH * TILE_SIZE, "left")
        love.graphics.printf("Mr. Duck has classified details on a lemonade stand.\nHelp Mr. Duck find the stand by guiding him through\nthe obstacles. Earn extra points by completely\nsolving levels. Try to earn as many points as possible!", 160, yPos, GRID_WIDTH * TILE_SIZE, "left")
        yPos = yPos + 100 -- Adjust y position for next line
        love.graphics.printf("Controls:", 70, yPos, GRID_WIDTH * TILE_SIZE, "left")
        love.graphics.printf("Use Arrow Keys (Up, Down, Left, Right) to move.", 160, yPos, GRID_WIDTH * TILE_SIZE, "left")
        yPos = yPos + 90 -- Adjust y position for next line
        love.graphics.setNewFont(13)
        love.graphics.printf("Beware!  Tiles on fire can no longer be crossed.", 0, yPos, GRID_WIDTH * TILE_SIZE, "center")

        --Draw menu button
        love.graphics.setColor(0.8, 0.8, 0.8) -- Light grey button
        love.graphics.rectangle("fill", button3X, button3Y, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0) -- Black Text
        love.graphics.setNewFont(16)
        love.graphics.printf("Back", button3X, button3Y + 15, buttonWidth, "center")


    -- Draw the Leaderboard screen
    elseif state == "leaderboard" then
        yPos = GRID_HEIGHT * TILE_SIZE / 4 - 10
        drawBackgroundText()
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.setNewFont(30)
        love.graphics.printf("Leaderboard", 0, yPos, GRID_WIDTH * TILE_SIZE, "center")

        yPos = yPos + 90
        love.graphics.setNewFont(16)
        for i, entry in ipairs(leaderboard) do
            love.graphics.printf(string.format("%d.", i), 210, yPos, GRID_WIDTH * TILE_SIZE, "left")
            love.graphics.printf(string.format("%s", entry.name), -45, yPos, GRID_WIDTH * TILE_SIZE, "center")
            love.graphics.printf("-", 0, yPos, GRID_WIDTH * TILE_SIZE, "center")
            love.graphics.printf(string.format("%d", entry.score), 340, yPos, GRID_WIDTH * TILE_SIZE, "left")
            yPos = yPos + 40
        end

        -- Draw menu button
        love.graphics.setColor(0.8, 0.8, 0.8) -- Light grey button
        love.graphics.rectangle("fill", button3X, button3Y, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0) -- Black text
        love.graphics.setNewFont(16)
        love.graphics.printf("Back", button3X, button3Y + 15, buttonWidth, "center")


    -- Draw the grid
    elseif state == "game" or state == "highscore" or state == "end" then
        love.graphics.setColor(1, 1, 1) -- Set color to white (default)
        for y = 1, #grid do
            for x = 1, #grid[y] do
                local tile = grid[y][x]
                --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
                if tile == "." or tile == "," then
                    love.graphics.draw(images["floor"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["floor"]:getWidth(), TILE_SIZE / images["floor"]:getHeight())
                elseif tile == "B" then
                    love.graphics.draw(images["bridge"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["bridge"]:getWidth(), TILE_SIZE / images["bridge"]:getHeight())
                elseif tile == "K" then
                    love.graphics.draw(images["floor"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["floor"]:getWidth(), TILE_SIZE / images["floor"]:getHeight())
                    love.graphics.draw(keyFrames[currentKeyFrame], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, (TILE_SIZE+5)/ keyFrames[currentKeyFrame]:getWidth(), (TILE_SIZE + 2)/ keyFrames[currentKeyFrame]:getHeight())
                elseif tile == "L" then
                    love.graphics.draw(images["floor"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["floor"]:getWidth(), TILE_SIZE / images["floor"]:getHeight())
                    love.graphics.draw(images["lock"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["lock"]:getWidth(), TILE_SIZE / images["lock"]:getHeight())
                elseif tile == "T" then
                    love.graphics.draw(images["dirt2"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["dirt2"]:getWidth(), TILE_SIZE / images["dirt2"]:getHeight())
                elseif tile == "I" then
                    love.graphics.draw(images["dirt1"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["dirt1"]:getWidth(), TILE_SIZE / images["dirt1"]:getHeight())
                elseif tile == "#" then
                    love.graphics.draw(images["wall2"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["wall2"]:getWidth(), TILE_SIZE / images["wall2"]:getHeight())
                elseif tile == "S" then
                    love.graphics.draw(images["door1"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["door1"]:getWidth(), TILE_SIZE / images["door1"]:getHeight())
                elseif tile == "G" then
                    love.graphics.draw(images["door2"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["door2"]:getWidth(), TILE_SIZE / images["door2"]:getHeight())
                elseif tile == " " then
                    if level == totalLevels then
                        love.graphics.draw(images["dirt1"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["dirt1"]:getWidth(), TILE_SIZE / images["dirt1"]:getHeight())
                    else
                        
                        love.graphics.draw(images["floor"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["floor"]:getWidth(), TILE_SIZE / images["floor"]:getHeight())
                        love.graphics.draw(images["fire"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["fire"]:getWidth(), TILE_SIZE / images["fire"]:getHeight())
                    end
                elseif tile == "_" then
                    love.graphics.draw(images["dirt2"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["dirt2"]:getWidth(), TILE_SIZE / images["dirt2"]:getHeight())
                elseif tile == "|" then
                    if level == totalLevels then
                        love.graphics.draw(images["dirt1"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["dirt1"]:getWidth(), TILE_SIZE / images["dirt1"]:getHeight())
                    else
                        love.graphics.draw(images["door1"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["door1"]:getWidth(), TILE_SIZE / images["door1"]:getHeight())
                        love.graphics.draw(images["fire"], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE, 0, TILE_SIZE / images["fire"]:getWidth(), TILE_SIZE / images["fire"]:getHeight())
                    end
                end
            end
            
        end

        -- Draw last level
        if level == totalLevels then
            love.graphics.setColor(1, 1, 1) -- Set color to white (default)
            love.graphics.draw(skyFrames[currentSkyFrame], 0, 0, 0, TILE_SIZE * 20 / skyFrames[currentSkyFrame]:getWidth(), TILE_SIZE * 13 / skyFrames[currentSkyFrame]:getHeight())
            love.graphics.draw(images["stand"], TILE_SIZE * 14, TILE_SIZE * 9, 0, (TILE_SIZE * 4) / images["stand"]:getWidth(), (TILE_SIZE * 4) / images["stand"]:getHeight())
            if player.x == 15 and player.y == 13 then -- Draw duck text bubble
                love.graphics.draw(images["grapes"], TILE_SIZE * 10.5, TILE_SIZE * 11, 0, (TILE_SIZE * 3.5) / images["grapes"]:getWidth(), (TILE_SIZE * 1) / images["grapes"]:getHeight())
            end
            if state == "end" and player.x ~= 15 then -- Draw man text bubble
                love.graphics.draw(images["no"], TILE_SIZE * 17, TILE_SIZE * 9.5, 0, (TILE_SIZE * 1.5) / images["no"]:getWidth(), (TILE_SIZE * 1.5) / images["no"]:getHeight())
            end
        end

        -- Draw the player
        love.graphics.setColor(1, 1, 1) -- Reset to white (default)
        if flipX then
            love.graphics.draw(duckFrames[currentDuckFrame], ((player.x-1)*TILE_SIZE)+32, (player.y-1)*TILE_SIZE, 0, -TILE_SIZE / duckFrames[currentDuckFrame]:getWidth(), TILE_SIZE / duckFrames[currentDuckFrame]:getHeight())  --Left facing
        else
            love.graphics.draw(duckFrames[currentDuckFrame], (player.x-1)*TILE_SIZE, (player.y-1)*TILE_SIZE, 0, TILE_SIZE / duckFrames[currentDuckFrame]:getWidth(), TILE_SIZE / duckFrames[currentDuckFrame]:getHeight()) -- Right facing
        end
        
        -- Draw keypad
        --love.graphics.setColor(1, 1, 1) -- Reset to white (default)
        --love.graphics.draw(images["keypad"], TILE_SIZE * 13, TILE_SIZE * 16, 0, (TILE_SIZE * 4) / images["keypad"]:getWidth(), (TILE_SIZE * 4) / images["keypad"]:getHeight())

        if state == "game" then
            -- Draw level counter
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(20)
            love.graphics.print("Level", 72, 69)
            love.graphics.printf(level, TILE_SIZE * 4, 69, TILE_SIZE, "center")

            -- Draw available points for current level
            love.graphics.setColor(1,1,1)
            love.graphics.printf(score - entryScore, TILE_SIZE * 7 - 4, 69, TILE_SIZE * 2, "right")
            love.graphics.printf("/", 276, 69, TILE_SIZE, "center")
            love.graphics.printf(dotCount, TILE_SIZE * 9 + 10, 69, TILE_SIZE * 2, "left")

            -- Draw levels solved counter
            love.graphics.print("Solved", 445, 69)
            love.graphics.printf(solved, TILE_SIZE * 16, 69, TILE_SIZE, "center")

            -- Draw current user score
            love.graphics.print("Points", TILE_SIZE, TILE_SIZE * 15 + 68)
            love.graphics.printf(score, TILE_SIZE * 3 + 9, TILE_SIZE * 15 + 68, TILE_SIZE * 3)

            drawArcade()

            -- Draw the menu button
            love.graphics.setNewFont(16)
            love.graphics.setColor(0.8, 0.8, 0.8) -- Light grey button
            love.graphics.rectangle("fill", button5X, button5Y, buttonWidth, buttonHeight)
            love.graphics.setColor(0, 0, 0) -- Black Text
            love.graphics.printf("Back To Menu", button5X, button5Y + (buttonHeight / 2) - 10, buttonWidth, "center")

            -- Draw the reset button
            love.graphics.setColor(0.8, 0, 0) -- Red button
            love.graphics.rectangle("fill", button6X, button6Y, buttonWidth, buttonHeight)
            love.graphics.setColor(1, 1, 1) -- White text
            love.graphics.printf("Reset Level", button6X, button6Y + (buttonHeight / 2) - 10, buttonWidth, "center")

        elseif state == "highscore" then
            drawArcade()

            love.graphics.setNewFont(30)
            love.graphics.printf("New Highscore!", 0, GRID_HEIGHT * TILE_SIZE / 4, GRID_WIDTH * TILE_SIZE, "center")
            
            yPos = GRID_HEIGHT * TILE_SIZE / 4 + 60
            love.graphics.setNewFont(30)
            love.graphics.printf(score, 0, yPos, GRID_WIDTH * TILE_SIZE, "center")
            yPos = yPos + 70
            love.graphics.setNewFont(14)
            love.graphics.printf("Enter your 3-letter name: ", 0, yPos, GRID_WIDTH * TILE_SIZE, "center")
            yPos = yPos + 50 -- Adjust y position for next line
            love.graphics.printf(userInput, 0, yPos, GRID_WIDTH * TILE_SIZE, "center")

            --Draw menu button
            love.graphics.setColor(0.8, 0.8, 0.8) -- Light grey button
            love.graphics.rectangle("fill", confirmButtonX, confirmButtonY, buttonWidth, buttonHeight)
            love.graphics.setColor(0, 0, 0) -- Black Text
            love.graphics.setNewFont(16)
            love.graphics.printf("Confirm", confirmButtonX, confirmButtonY + 15, buttonWidth, "center")

        elseif state == "end" then
            drawArcade()

            -- Draw end game player stats
            love.graphics.printf("You Win!", 0, GRID_HEIGHT * TILE_SIZE / 2 - 50, GRID_WIDTH * TILE_SIZE, "center")
            love.graphics.printf("Final Score: " .. score, 0, GRID_HEIGHT * TILE_SIZE / 2, GRID_WIDTH * TILE_SIZE, "center")
            love.graphics.printf("Levels Completed Without Reset: " .. totalLevelsCompletedWithoutReset, 0, GRID_HEIGHT * TILE_SIZE / 2 + 30, GRID_WIDTH * TILE_SIZE, "center")

            -- Draw leaderboard button
            love.graphics.setColor(0.2, 0.2, 0.8) -- Blue button
            love.graphics.rectangle("fill", button3X, button3Y, buttonWidth, buttonHeight)
            love.graphics.setColor(1, 1, 1) -- White text
            love.graphics.printf("Leaderboard", button3X, button3Y + (buttonHeight / 2) - 10, buttonWidth, "center")

            --Draw menu button
            love.graphics.setColor(0.2, 0.2, 0.2) -- Dark grey button
            love.graphics.rectangle("fill", button4X, button4Y, buttonWidth, buttonHeight)
            love.graphics.setColor(1, 1, 1) -- White text
            love.graphics.setNewFont(16)
            love.graphics.printf("Main Menu", button4X, button4Y + 15, buttonWidth, "center")
        end
    end
end

-- Handle player movement
function love.keypressed(key)
    if key == "h" then state = "highscore" end --++
    if key == "e" then 
        state = "end" 
        level = 12
    end --++

    if state == "game" or state == "end" then
        local dx, dy = 0, 0
        if key == "up" then dy = -1 end
        if key == "down" then dy = 1 end
        if key == "left" then
            dx = -1 
            flipX = false
        end
        if key == "right" then
            dx = 1 
            flipX = true
        end

        local newX = player.x + dx
        local newY = player.y + dy

        if newX > 0 and newX <= GRID_WIDTH and newY > 0 and newY <= GRID_HEIGHT then
            local targetTile = grid[newY][newX]
            -- Allow movement only to uncrossed tiles (".", "G")
            if targetTile == "." or targetTile == "G" or targetTile == "B" or targetTile == "F" or targetTile == "," or targetTile == "X" or targetTile == "K" then
                -- Mark the current tile as crossed, but do not overwrite the goal
                if grid[player.y][player.x] == "S" then -- Check for start position
                    grid[player.y][player.x] = "|" -- Keeps .draw("door") in view
                elseif grid[player.y][player.x] == "." then -- Passing tile
                    grid[player.y][player.x] = " " -- Burn
                elseif grid[player.y][player.x] == "," then -- For final level render
                    grid[player.y][player.x] = "_" -- Render grass
                elseif grid[player.y][player.x] == "B" then -- For bridge
                    grid[player.y][player.x] = "." -- bridge spent
                elseif grid[player.y][player.x] == "K" then
                    grid[player.y][player.x] = " "
                elseif grid[player.y][player.x] == "F" then -- Final level loop
                    grid[player.y][player.x] = "F" -- Loop
                elseif grid[player.y][player.x] == "X" then
                    grid[player.y][player.x] = "F"
                end

                -- Handle lock tile
                local adjacentPositions = {
                    {x = newX - 1, y = newY}, -- Left
                    {x = newX + 1, y = newY}, -- Right
                    {x = newX, y = newY - 1}, -- Up
                    {x = newX, y = newY + 1}  -- Down
                }
                if doorLock then
                    for _, pos in ipairs(adjacentPositions) do
                        if pos.x >= 0 and pos.x <= GRID_WIDTH and pos.y > 0 and pos.y <= GRID_HEIGHT then
                            local adjacentTile = grid[pos.y][pos.x]
                            if adjacentTile == "L" then
                                grid[pos.y][pos.x] = "." -- Open the lock tile                    
                            end
                        end
                    end
                end
                -- Handle key tile
                if targetTile == "K" then
                    grid[newY][newX] = "." -- Remove the key
                    doorLock = true
                end

                -- Move the player
                player.x = newX
                player.y = newY
                if grid[player.y][player.x] ~= "F" then
                    score = score + 1 -- Increment the score for each move
                end
                
                -- Check for goal
                if targetTile == "G" or targetTile == "X" then
                    if resetStatus[level] == nil or resetStatus[level] == false then
                        levelsCompletedWithoutReset[level] = true
                        if score - entryScore == dotCount then
                            score = score + 100
                            solved = solved + 1
                        end
                    else
                        levelsCompletedWithoutReset[level] = false
                    end
                    dotCount = 0
                    doorLock = false
                    
                    -- Check Load next level
                    if targetTile == "G" and levels[level] then
                        level = level + 1 -- Increment level
                        love.load() -- Reload level
                    elseif targetTile == "X" then -- Last level reached
                        for _, completed in pairs(levelsCompletedWithoutReset) do
                            if completed then totalLevelsCompletedWithoutReset = totalLevelsCompletedWithoutReset + 1 end
                        end
                        if checkHighscore(leaderboard, score) then
                            state = "highscore"
                        else
                            state = "end"
                        end
                    end
                end
            end
        end

    elseif state == "highscore" then
        if key == "backspace" then
            userInput = userInput:sub(1, -2)
            isValidInput = true  -- Valid if there is any input (to allow re-entry)
        end
    end
end

-- Handle mouse input for buttons
function love.mousepressed(x, y, button)
    if button == 1 then
        if state == "menu" then
            if x >= button1X and x <= button1X + buttonWidth and y >= button1Y and y <= button1Y + buttonHeight then
                state = "game"
            elseif x >= button2X and x <= button2X + buttonWidth and y >= button2Y and y <= button2Y + buttonHeight then
                state = "howToPlay"
            elseif x >= button3X and x <= button3X + buttonWidth and y >= button3Y and y <= button3Y + buttonHeight then
                loadLeaderboard() -- Reload leaderboard to ensure it's up to date
                state = "leaderboard"
            end

        elseif state == "howToPlay" then
            if x >= button3X and x <= button3X + buttonWidth and y >= button3Y and y <= button3Y + buttonHeight then
                state = "menu"
            end

        elseif state == "leaderboard" then
            if x >= button3X and x <= button3X + buttonWidth and y >= button3Y and y <= button3Y + buttonHeight then
                state = "menu"
            end

        elseif state == "game" then
            if x >= button6X and x <= button6X + buttonWidth and y >= button6Y and y <= button6Y + buttonHeight then
                resetStatus[level] = true
                score = entryScore
                doorLock = false
                dotCount = 0
                love.load()
            elseif x >= button5X and x <= button5X + buttonWidth and y >= button5Y and y <= button5Y + buttonHeight then
                freshRestart()
            end

        elseif state == "highscore" then
            if x >= confirmButtonX and x <= confirmButtonX + buttonWidth and y >= confirmButtonY and y <= confirmButtonY + buttonHeight then
                if #userInput == 3 then
                    table.insert(leaderboard, { name = userInput, score = score })
                    table.sort(leaderboard, function(a, b) return a.score > b.score end)
                    
                    while #leaderboard > 5 do
                        table.remove(leaderboard)
                    end

                    saveLeaderboard()
                    state = "end"
                else
                    isValidInput = false
                end
            end

        elseif state == "end" then
            if x >= button3X and x <= button3X + buttonWidth and y >= button3Y and y <= button3Y + buttonHeight then
                state = "leaderboard"
                freshRestart()
            elseif x >= button4X and x <= button4X + buttonWidth and y >= button4Y and y <= button4Y + buttonHeight then
                freshRestart()
            end
        end
    end
end


function love.textinput(text)
    if #userInput < 3 and text:match("%a") then
        userInput = userInput .. string.upper(text)
        isValidInput = true
    end
end

-- Checks if score is eliable for leaderboard
function checkHighscore(leaderboard, score)
    local maxEntries = 5
    local smallestScore = math.huge
    for _, entry in ipairs(leaderboard) do
        if entry.score < smallestScore then
            smallestScore = entry.score
        end
    end
    if #leaderboard < maxEntries or score > smallestScore then
        return true
    end
    return false
end

-- Creates a default game state
function freshRestart()
    for i = 1, #levelsCompletedWithoutReset do
        levelsCompletedWithoutReset[i] = false
        resetStatus[i] = false
    end
    totalLevelsCompletedWithoutReset = 0
    level = 1
    score = 0
    entryScore = 0
    dotCount = 0
    solved = 0
    doorLock = false
    userInput = ""
    love.load()
    state = "menu"
end
