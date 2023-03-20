local levelLabels = {}
local timeLabels = {}
local bestTimeLabels = {}
local levelTimes = {}
local bestTimes = {}
local totalTimeLabel = nil
local totalTimePlayed = nil
local totalTimeObtained = false
local timeSpent = nil
local currentDisplayedLevel = 0
local level = UnitLevel("player")
local updateTimer = nil
local timeObtained = false



mainFrame = CreateFrame("Frame", "LevelSpeedRunnerMainFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")



-- Functions
local function SetLabelPoints()
    local topY = 50 -- y-position of top-most level label
    for i = 1, MAX_PLAYER_LEVEL do
        levelLabels[i] = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        levelLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 14)
        timeLabels[i] = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        timeLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 14)
        bestTimeLabels[i] = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bestTimeLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 14)
        if levelLabels[i] then
            levelLabels[i]:SetPoint("LEFT", mainFrame, "LEFT", 10, topY - (i - math.max(level, 1)) * 20)
        end
        if timeLabels[i] then
            timeLabels[i]:SetPoint("LEFT", mainFrame, "LEFT", 80, topY - (i - math.max(level, 1)) * 20)
        end
        if bestTimeLabels[i] then
            bestTimeLabels[i]:SetPoint("LEFT", mainFrame, "LEFT", 150, topY - (i - math.max(level, 1)) * 20)
        end
    end
end





local function CreateMainFrame()
    mainFrame:SetSize(225, 130)
    local framePosition = LevelSpeedRunnerDB and LevelSpeedRunnerDB.framePosition or {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        x = 0,
        y = 0
    }
    
        mainFrame:SetPoint(framePosition.point, UIParent, framePosition.relativePoint, framePosition.x, framePosition.y)
        mainFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",

        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.8)
end



-- create a table to store best times for each level for each faction


local function UpdateBestTimes(level, time, faction)
    if not LevelSpeedRunnerDB.bestTimes then
        LevelSpeedRunnerDB.bestTimes = {}
    end
    if not LevelSpeedRunnerDB.bestTimes[level] then
        LevelSpeedRunnerDB.bestTimes[level] = {}
    end

    if not LevelSpeedRunnerDB.bestTimes[level][faction] or time < LevelSpeedRunnerDB.bestTimes[level][faction] then
        LevelSpeedRunnerDB.bestTimes[level][faction] = time
        print("Saved best time:", faction, level, time)
    end

    -- Store time taken for each level for the character
    local characterName = UnitName("player")
    if not LevelSpeedRunnerDB.characterTimes then
        LevelSpeedRunnerDB.characterTimes = {}
    end
    if not LevelSpeedRunnerDB.characterTimes[characterName] then
        LevelSpeedRunnerDB.characterTimes[characterName] = {}
    end
    LevelSpeedRunnerDB.characterTimes[characterName][level] = time
end






local function FormatTime(seconds)
    if type(seconds) ~= "number" then
        return "00:00:00"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    seconds = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end





local function DisplayTime(timeInSeconds)
    return FormatTime(timeInSeconds)
end


local function DeltaTimeToString(current, best)
    if not best or best == 0 then
        return string.format("|cFFAAAAAA%s|r", DisplayTime(current))
    end

    local delta = current - best
    local color
    if delta < 0 then
        color = "|cFF00FF00" -- green
    elseif delta == 0 then
        color = "|cFFFFFF00" -- gold
    else
        color = "|cFFFF0000" -- red
    end

    return string.format("%s%s (%s%s)|r", color, DisplayTime(current), (delta < 0 and "-" or "+"), DisplayTime(abs(delta)))
end

local function GetBestTime(faction, level)
    if LevelSpeedRunnerDB.bestTimes[level] and LevelSpeedRunnerDB.bestTimes[level][faction] then
        return LevelSpeedRunnerDB.bestTimes[level][faction]
    else
        return nil
    end
end




local function UpdateDisplay()
    local faction = UnitFactionGroup("player")
    timeSpent = math.max(time() - loginTime, 0)
    local time = 0
    currentDisplayedLevel = math.max(level - 10, 1)
    

    for i = math.max(level, 1), math.min(level + 5, MAX_PLAYER_LEVEL) do
        local displayedLevel = i
        if displayedLevel <= MAX_PLAYER_LEVEL then
            displayedLevel = i - level + math.max(level - 4, 1)
        end
        if totalTimePlayed then
            -- Retrieve time taken for this level for the current character
    
            local characterName = UnitName("player")
            if not LevelSpeedRunnerDB.characterTimes then
                LevelSpeedRunnerDB.characterTimes = {}
            end
            if not LevelSpeedRunnerDB.characterTimes[characterName] then
                LevelSpeedRunnerDB.characterTimes[characterName] = {}
            end
            time = levelTimes[displayedLevel] or (displayedLevel == level and totalTimePlayed + timeSpent or LevelSpeedRunnerDB.characterTimes[characterName][displayedLevel] or 0)
        end
        local bestTime = GetBestTime(faction, displayedLevel)
        local deltaTime = time - (bestTime or 0)

        if not totalTimeObtained then
            totalTimePlayed = select(1, RequestTimePlayed())
            totalTimeObtained = true -- Set the flag to true once you obtain the value
        end

        if displayedLevel > 0 and displayedLevel <= MAX_PLAYER_LEVEL then
            if not levelLabels[i] then
                levelLabels[i] = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

            end
    
            if not timeLabels[i] then
                timeLabels[i] = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

            end
    
            if not bestTimeLabels[i] then
                bestTimeLabels[i] = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            end
            
            if LevelSpeedRunnerDB.bestTimes and LevelSpeedRunnerDB.bestTimes[displayedLevel] and LevelSpeedRunnerDB.bestTimes[displayedLevel][faction] then
                bestTimeLabels[i]:SetText(FormatTime(LevelSpeedRunnerDB.bestTimes[displayedLevel][faction]))
            else
                bestTimeLabels[i]:SetText("")
            end
            

            levelLabels[i]:SetText("Level " .. displayedLevel .. ":")
            timeLabels[i]:SetText(FormatTime(time))


            if deltaTime < -100 then
                timeLabels[i]:SetTextColor(0, 1, 0) -- Green
            elseif deltaTime == time then
                timeLabels[i]:SetTextColor(0.5, 0.5, 0.5) -- gray
            elseif deltaTime > 0 then
                timeLabels[i]:SetTextColor(1, 0, 0) -- Red
            elseif deltaTime < 10 then
                timeLabels[i]:SetTextColor(1, 215/255, 0) -- Gold
            end
        else
            if levelLabels[i] then levelLabels[i]:SetText("") end
        end
    end    
end


local function OnUpdate(self, elapsed)
    UpdateDisplay()
end



-- Slash command handler
local function SlashCmdHandler(msg, editBox)
    if msg == "show" then
        mainFrame:Show()
    elseif msg == "hide" then
        mainFrame:Hide()
    else
        print("Level Speed Runner: Invalid command. Use /lsr show or /lsr hide.")
    end
end

-- Register slash command
SLASH_LevelSpeedRunner1 = "/lsr"
SlashCmdList["LevelSpeedRunner"] = SlashCmdHandler

local function SaveFramePosition()
    LevelSpeedRunnerDB.framePosition.point, _, LevelSpeedRunnerDB.framePosition.relativePoint, LevelSpeedRunnerDB.framePosition.x, LevelSpeedRunnerDB.framePosition.y = mainFrame:GetPoint()
end




local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        CreateMainFrame()
        SetLabelPoints()
        local addonName = ...
        if addonName == "LevelSpeedRunner" then

            bestTimes = LevelSpeedRunnerDB.bestTimes
            mainFrame:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        if not LevelSpeedRunnerDB then
            LevelSpeedRunnerDB = {
                bestTimes = { },
                framePosition = {
                    point = "CENTER",
                    relativePoint = "CENTER",
                    x = 0,
                    y = 0
                }
            }
        end
        if not totalTimeObtained then -- Check if total time played has been obtained
            totalTimePlayed = select(1, RequestTimePlayed())
            totalTimeObtained = true -- Set the flag to true once you obtain the value
        end
        loginTime = time()
        mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        local faction = UnitFactionGroup("player")
        local totalTimePlayed = ...
        UpdateBestTimes(level - 1, totalTimePlayed + timeSpent, faction)
        levelTimes[level] = totalTimePlayed + timeSpent
        SetLabelPoints()

    elseif event == "TIME_PLAYED_MSG" then
    if not timeObtained then -- Check if total time played has been obtained
        totalTimePlayed = select(1, ...)
        timeObtained = true -- Set the flag to true once you obtain the value
    end
    elseif event == "PLAYER_LOGOUT" then
        SaveFramePosition()
    end
end



-- Call the CreateMainFrame function



-- Register events and set scripts for mainFrame
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("PLAYER_LEVEL_UP")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("TIME_PLAYED_MSG")  
mainFrame:SetScript("OnUpdate", OnUpdate)
mainFrame:SetScript("OnEvent", OnEvent)
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
