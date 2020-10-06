
RunConsoleCommand("stopsound") --Lua refresh stuff

local audioStream

sound.PlayURL("https://media1.vocaroo.com/mp3/1neQhwkCnaTP", "noblock mono", function(stream)
    if not IsValid(stream) then return end
    audioStream = stream
end)


local bgCol = Color(30, 30, 30)
local particleCol = Color(255, 255, 255, 150)
local circleCol = Color(20, 20, 20)

local circleRot = 0
local circleAccel = 0

local barCount = 64
local bassBarCount = 16
local degPerBar = 360 / barCount
local radPerBar = math.rad(degPerBar)

local realBars = {}
for i = 1, barCount do realBars[i] = 0 end

local centerX, centerY = ScrW() * .5, ScrH() * .5
local circleRadius = ScrH() * .2

local particles = {}

local function createParticle(initialSetup)
    local direction = math.Rand(0, 360)
    local directionRad = math.rad(direction)

    if initialSetup then
        table.insert(particles, {
            x = centerX + math.sin(directionRad) * (circleRadius + math.Rand(0, ScrH() * .8)),
            y = centerY + math.cos(directionRad) * (circleRadius + math.Rand(0, ScrH() * .8)),
            speed = math.Rand(5, 15) / 10,
            direction = direction
        })

        return
    end

    table.insert(particles, {
        x = centerX + math.sin(directionRad) * circleRadius,
        y = centerY + math.cos(directionRad) * circleRadius,
        speed = math.Rand(5, 15) / 10,
        direction = direction
    })
end

for i = 1, 300 do
    createParticle(true)
end

hook.Add("HUDPaint", "tom.visualiser", function()
    if not audioStream then return end --Get the current audio data

    local bars = {}
    audioStream:FFT(bars, FFT_8192)

    for i = 1, barCount do
        realBars[i] = Lerp(FrameTime() * 20, realBars[i], bars[i])
    end

    local bassMultiplier = 0
    for i = 1, bassBarCount do
        bassMultiplier = bassMultiplier + bars[i] * (Lerp(i / bassBarCount, 1.5, .2))
    end

    bassMultiplier = bassMultiplier * 50

    local scrW, scrH = ScrW(), ScrH() --Draw the particles
    centerX, centerY = scrW * .5, scrH * .5

    draw.RoundedBox(0, 0, 0, scrW, scrH, bgCol)

    local particleRadius = scrH * .0025
    local particleDiameter = particleRadius * 2

    local particleBaseSpeed = (FrameTime() + bassMultiplier * .02) * 10
    local particleRemoved

    for i = 1, #particles do
        local particle = particles[i]
        local particleSpeed = particleBaseSpeed * particle.speed
        particle.x, particle.y = particle.x + math.sin(math.rad(particle.direction)) * particleSpeed, particle.y + math.cos(math.rad(particle.direction)) * particleSpeed
        draw.RoundedBox(particleRadius, particle.x - particleRadius, particle.y - particleRadius, particleDiameter, particleDiameter, particleCol)

        if particleRemoved then continue end
        if particle.x < 0 or particle.y < 0 or particle.x > scrW or particle.y > scrH then
            table.remove(particle, i)
            createParticle()
            particleRemoved = true
        end
    end

    circleRadius = scrH * .2 + (bassMultiplier * scrH / 1080) --Draw the visualiser
    local circleDiameter = circleRadius * 2

    circleAccel = math.Approach(circleAccel, 2 + bassMultiplier * 3, FrameTime() * 500)
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