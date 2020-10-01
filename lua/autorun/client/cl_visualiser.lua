
RunConsoleCommand("stopsound") --Lua refresh stuff

local audioStream

sound.PlayURL("https://media1.vocaroo.com/mp3/1neQhwkCnaTP", "noblock mono", function(stream)
    if not IsValid(stream) then return end
    audioStream = stream
end)

local bgCol = Color(30, 30, 30)
local circleCol = Color(20, 20, 20)

local circleRot = 0
local circleAccel = 0

local barCount = 64
local degPerBar = 360 / barCount
local radPerBar = math.rad(degPerBar)

local realBars = {}
for i = 1, barCount do realBars[i] = 0 end

hook.Add("HUDPaint", "tom.visualiser", function()
    if not audioStream then return end --Get the current audio data

    local bars = {}
    audioStream:FFT(bars, FFT_8192)

    for i = 1, barCount do
        realBars[i] = Lerp(FrameTime() * 20, realBars[i], bars[i])
    end

    local bassMultiplier = 0
    for i = 1, 20 do
        bassMultiplier = bassMultiplier + bars[i]
    end

    bassMultiplier = bassMultiplier * 30

    local scrW, scrH = ScrW(), ScrH() --Draw the visualiser
    draw.RoundedBox(0, 0, 0, scrW, scrH, bgCol)

    local centerX, centerY = scrW * .5, scrH * .5

    local circleRadius = scrH * .2 + (bassMultiplier * scrH / 1080)
    local circleDiameter = circleRadius * 2

    circleAccel = math.Approach(circleAccel, 2 + bassMultiplier * 4, FrameTime() * 500)
    circleRot = circleRot + FrameTime() * circleAccel

    local circleRotRad = math.rad(circleRot)

    draw.NoTexture()

    local barW = ScrH() * .016 + (bassMultiplier * scrH / 10800)

    for i = 1, barCount do
        local barAmplitude = (realBars[i] or 10) * 1400 + 14

        local barAngleRad = radPerBar * i + circleRotRad
        local distFromCenter = circleRadius - 5 + (barAmplitude * .5)
        local barX, barY = centerX + math.cos(barAngleRad) * distFromCenter, centerY + math.sin(barAngleRad) * distFromCenter

        local barAngleDeg = degPerBar * i + circleRot
        surface.SetDrawColor(HSVToColor(degPerBar * i, 1, 1))
        surface.DrawTexturedRectRotated(barX, barY, barAmplitude, barW, -barAngleDeg)
    end

    draw.RoundedBox(circleRadius, centerX - circleRadius, centerY - circleRadius, circleDiameter, circleDiameter, circleCol)
end)