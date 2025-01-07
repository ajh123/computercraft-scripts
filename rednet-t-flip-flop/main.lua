-- A program that is is used like a T Flip Flop:
-- The sate can be controled with a button press or remotely via rednet
-- The flip flop state is outputed on two sides (or one)

local output1 = "top"              -- The two sides that you want to output (can be the same if you want just one side)
local output2 = "bottom"           -- ^^
local input = "front"              -- The side of the computer that has a button
local modemSide = "back"           -- The side of the computer that has a modem
local redstoneState = false        -- The default state of the T Flip Flop, true or false

local logFile = "redstone_log.txt" -- File to store logs

----------------------------------------------------------------------------------------
-- MAIN PROGRAM CODE CONTINUES BELOW
----------------------------------------------------------------------------------------

-- Function to log messages to a file and print to terminal
local function log(message)
    local timestampedMessage = os.date("[%Y-%m-%d %H:%M:%S]") .. " " .. message

    -- Write to file
    local file = fs.open(logFile, "a")
    if file then
        file.writeLine(timestampedMessage)
        file.close()
    end

    -- Print to terminal
    print(timestampedMessage)
end

-- Function to check redstone input from the front side and toggle the internal boolean
local function checkRedstoneInput()
    while true do
        -- Read the redstone input from the front
        local redstoneInput = redstone.getInput(input)

        -- Toggle the boolean if redstone is active
        if redstoneInput then
            redstoneState = not redstoneState
            log("Redstone input detected. State toggled to: " .. tostring(redstoneState))
        end

        -- Wait for a short period before checking again (to avoid constant loop)
        sleep(0.1)
    end
end

-- Function to output redstone to top and bottom based on the internal boolean
local function outputRedstone()
    while true do
        if redstoneState then
            redstone.setOutput(output1, true)
            redstone.setOutput(output2, true)
        else
            redstone.setOutput(output1, false)
            redstone.setOutput(output2, false)
        end

        -- Log the current output state
        log("Output updated: " .. tostring(redstoneState))

        -- Wait for a short period before updating again (to avoid constant loop)
        sleep(0.1)
    end
end

-- Function to handle rednet messages for changing or retrieving the redstone state
local function handleRednet()
    -- Open the modem for rednet communication
    rednet.open(modemSide)
    log("Modem opened on side: " .. modemSide)

    while true do
        -- Wait for a message
        local senderId, message, protocol = rednet.receive()

        if protocol == "redstone_control" then
            if message.action == "POST" then
                -- Change the redstone state
                if type(message.state) == "boolean" then
                    redstoneState = message.state
                    rednet.send(senderId, { success = true }, protocol)
                    log("POST received from " .. senderId .. ". State set to: " .. tostring(redstoneState))
                else
                    rednet.send(senderId, { success = false, error = "Invalid state" }, protocol)
                    log("POST received from " .. senderId .. " with invalid state.")
                end
            elseif message.action == "GET" then
                -- Retrieve the redstone state
                rednet.send(senderId, { success = true, state = redstoneState }, protocol)
                log("GET received from " .. senderId .. ". State returned: " .. tostring(redstoneState))
            else
                rednet.send(senderId, { success = false, error = "Invalid action" }, protocol)
                log("Invalid action received from " .. senderId .. ": " .. tostring(message.action))
            end
        end
    end
end

-- Run all functions in parallel
parallel.waitForAll(checkRedstoneInput, outputRedstone, handleRednet)
