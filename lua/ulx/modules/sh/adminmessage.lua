local CATEGORY_NAME = "管理员频道"

-- Initialize default positions and time
local DEFAULT_POS_X = 5 / 10
local DEFAULT_POS_Y = 25 / 10
local DEFAULT_TIME = 10

-- Table to store individual player settings on the server
local playerSettings = {}

if SERVER then
    util.AddNetworkString("SendCenterMessage")
    util.AddNetworkString("UpdateMessageSettings")
    util.AddNetworkString("AdminMessageColor")

    function ulx.setconfig(calling_ply, posX, posY, time)
        local adjustedPosX = posX / 10
        local adjustedPosY = posY / 10

        -- Save the settings for the calling player
        playerSettings[calling_ply] = { posX = adjustedPosX, posY = adjustedPosY, time = time }

        net.Start("UpdateMessageSettings")
        net.WriteFloat(adjustedPosX)
        net.WriteFloat(adjustedPosY)
        net.WriteFloat(time)
        net.Send(calling_ply)

        ulx.fancyLogAdmin(calling_ply, true, "#A 设置为 X: #s, Y: #s, 时间: #s", adjustedPosX, adjustedPosY, time)
    end
else
    local displayMessage
    local displayPosX = DEFAULT_POS_X
    local displayPosY = DEFAULT_POS_Y
    local displayTime = DEFAULT_TIME

    net.Receive("UpdateMessageSettings", function()
        displayPosX = net.ReadFloat()
        displayPosY = net.ReadFloat()
        displayTime = net.ReadFloat()
    end)

    function DisplayCenterMessage(msg, posX, posY, time)
        displayMessage = msg
        displayPosX = posX or displayPosX
        displayPosY = posY or displayPosY
        displayTime = time or displayTime

        --surface.PlaySound("common/warning.wav")

        -- Add timer to clear the message after displayTime seconds
        timer.Simple(displayTime, function()
            displayMessage = nil
        end)
    end

    function DrawCenterMessage()
        if displayMessage then
            local w = ScrW()
            local tw, th = surface.GetTextSize(displayMessage)

            draw.SimpleText(displayMessage, "DermaLarge", w * displayPosX, th * displayPosY, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    hook.Add("HUDPaint", "DisplayCenterMessage", DrawCenterMessage)

    net.Receive("SendCenterMessage", function()
        local msg = net.ReadString()

        DisplayCenterMessage(msg, displayPosX, displayPosY, displayTime)
    end)

    net.Receive("AdminMessageColor", function()
        local msg = net.ReadString()
        chat.AddText(Color(255, 0, 0, 255), msg)
    end)
end

-- Shared code
function SendCenterMessageToAllPlayers(msg)
    if SERVER then
        net.Start("SendCenterMessage")
        net.WriteString(msg)
        net.Broadcast()
    end
end

function ulx.adminmessage(calling_ply, msg)
    local playerName

    if IsValid(calling_ply) then
        playerName = calling_ply:Nick()
    else
        playerName = "控制台"
    end

    local formattedMsg = "[管理员频道] " .. playerName .. ": " .. msg

    SendCenterMessageToAllPlayers(formattedMsg)

    net.Start("AdminMessageColor")
    net.WriteString(formattedMsg)
    net.Broadcast()
end

local adminmessage = ulx.command(CATEGORY_NAME, "ulx adminmessage", ulx.adminmessage, "@", true, true)
adminmessage:addParam { type = ULib.cmds.StringArg, hint = "消息", ULib.cmds.takeRestOfLine }
adminmessage:defaultAccess(ULib.ACCESS_ADMIN)
adminmessage:help("给所有玩家发送信息在屏幕中间以及聊天框里.")

local setconfig = ulx.command(CATEGORY_NAME, "ulx setconfig", ulx.setconfig, "!setconfig")
setconfig:addParam { type = ULib.cmds.NumArg, hint = "X 位置", default = DEFAULT_POS_X * 10, min = 0, max = 1000, ULib.cmds.optional, ULib.cmds.round }
setconfig:addParam { type = ULib.cmds.NumArg, hint = "Y 位置", default = DEFAULT_POS_Y * 10, min = 0, max = 1000, ULib.cmds.optional, ULib.cmds.round }
setconfig:addParam { type = ULib.cmds.NumArg, hint = "时间", default = DEFAULT_TIME, min = 1, max = 60, ULib.cmds.optional, ULib.cmds.round }
setconfig:defaultAccess(ULib.ACCESS_ADMIN)
setconfig:help("设置默认的消息位置和时间.")
