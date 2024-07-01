-- This module holds any type of chatting functions
CATEGORY_NAME = "聊天"

------------------------------ Psay ------------------------------
function ulx.psay(calling_ply, target_ply, message)
    if calling_ply:GetNWBool("ulx_muted", false) then
        ULib.tsayError(calling_ply, "你被静音了,因此不能说话!如果紧急,请使用 asay 进行管理员聊天.", true)
        return
    end

    local isAdmin = calling_ply:IsAdmin() or calling_ply:IsSuperAdmin()
    local callingPlyAlive = calling_ply:Alive()
    local targetPlyAlive = target_ply:Alive()

    if not isAdmin and (callingPlyAlive or targetPlyAlive) then
        ULib.tsayError(calling_ply, "只有死亡状态的玩家才能相互发送私密信息!", true)
        return
    end

    ulx.fancyLog({ target_ply, calling_ply }, "#P 发送到 #P: " .. message, calling_ply, target_ply)
end

local psay = ulx.command(CATEGORY_NAME, "ulx psay", ulx.psay, "!p", true)
psay:addParam { type = ULib.cmds.PlayerArg, target = "!^", ULib.cmds.ignoreCanTarget }
psay:addParam { type = ULib.cmds.StringArg, hint = "信息", ULib.cmds.takeRestOfLine }
psay:defaultAccess(ULib.ACCESS_ALL)
psay:help("发送私密信息到目标玩家.")

------------------------------ Asay ------------------------------
local seeasayAccess = "ulx seeasay"

if SERVER then
    ULib.ucl.registerAccess(seeasayAccess, ULib.ACCESS_OPERATOR, "Ability to see 'ulx asay'", "Other")
end

function ulx.asay(calling_ply, message)
    local isAdmin = IsValid(calling_ply) and calling_ply:IsPlayer() and calling_ply:IsAdmin()
    local plyName = IsValid(calling_ply) and calling_ply:IsPlayer() and calling_ply:Nick() or "Console"
    local admins = false

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsAdmin() then
            admins = true
            break
        end
    end

    if not admins then
        if IsValid(calling_ply) then
            calling_ply:ChatPrint("当前没有管理员在线")
        else
            print("当前没有管理员在线")
        end
        return
    end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and (ply:IsAdmin() or ply == calling_ply) then
            umsg.Start("ULXAsayColoredMessage", ply)
            umsg.String(plyName)
            umsg.String(message)
            umsg.Bool(isAdmin)
            umsg.End()
            if ply:IsAdmin() then
                ply:SendLua("surface.PlaySound(\"common/warning.wav\")")
            end
        end
    end
end

local asay = ulx.command(CATEGORY_NAME, "ulx asay", ulx.asay, { "@@", "!举报", "!report" }, true, true)
asay:addParam { type = ULib.cmds.StringArg, hint = "信息", ULib.cmds.takeRestOfLine }
asay:defaultAccess(ULib.ACCESS_ALL)
asay:help("发送信息给当前在线的管理员.")

if CLIENT then
    usermessage.Hook("ULXAsayColoredMessage", function(um)
        local name = um:ReadString()
        local message = um:ReadString()
        local isAdmin = um:ReadBool()
        local prefix = isAdmin and "[管理员] " or "[玩家举报] "

        chat.AddText(Color(255, 0, 0), prefix, Color(255, 0, 0), name .. ": " .. message)
    end)
end

------------------------------ Tsay ------------------------------
function ulx.tsay(calling_ply, message)
    ULib.tsay(_, message)

    if ULib.toBool(GetConVarNumber("ulx_logChat")) then
        ulx.logString(string.format("(tsay from %s) %s", calling_ply:IsValid() and calling_ply:Nick() or "Console", message))
    end
end

local tsay = ulx.command(CATEGORY_NAME, "ulx tsay", ulx.tsay, "@@@", true, true)
tsay:addParam { type = ULib.cmds.StringArg, hint = "信息", ULib.cmds.takeRestOfLine }
tsay:defaultAccess(ULib.ACCESS_ADMIN)
tsay:help("发送信息到每个玩家的\n聊天栏里.")

------------------------------ Csay ------------------------------
function ulx.csay(calling_ply, message)
    ULib.csay(_, message)

    if ULib.toBool(GetConVarNumber("ulx_logChat")) then
        ulx.logString(string.format("(csay from %s) %s", calling_ply:IsValid() and calling_ply:Nick() or "Console", message))
    end
end

local csay = ulx.command(CATEGORY_NAME, "ulx csay", ulx.csay, "@@@", true, true)
csay:addParam { type = ULib.cmds.StringArg, hint = "信息", ULib.cmds.takeRestOfLine }
csay:defaultAccess(ULib.ACCESS_ADMIN)
csay:help("发送信息到每个玩家的屏幕\n中央.")

------------------------------ Thetime ------------------------------
local waittime = 60
local lasttimeusage = -waittime
function ulx.thetime(calling_ply)
    if lasttimeusage + waittime > CurTime() then
        ULib.tsayError(calling_ply, "我只是告诉你时间的!请等待 " .. waittime .. " 秒后再次使用", true)
        return
    end

    lasttimeusage = CurTime()
    ulx.fancyLog("当前时间为 #s.", os.date("%I:%M %p"))
end

local thetime = ulx.command(CATEGORY_NAME, "ulx thetime", ulx.thetime, "!thetime")
thetime:defaultAccess(ULib.ACCESS_ALL)
thetime:help("显示当前时间.")


------------------------------ Adverts ------------------------------
ulx.adverts = ulx.adverts or {}
local adverts = ulx.adverts -- For XGUI, too lazy to change all refs

local function doAdvert(group, id)
    if adverts[group][id] == nil then
        if adverts[group].removed_last then
            adverts[group].removed_last = nil
            id = 1
        else
            id = #adverts[group]
        end
    end

    local info = adverts[group][id]

    local message = string.gsub(info.message, "%%curmap%%", game.GetMap())
    message = string.gsub(message, "%%host%%", GetConVarString("hostname"))
    message = string.gsub(message, "%%ulx_version%%", ULib.pluginVersionStr("ULX"))

    if not info.len then -- tsay
        local lines = ULib.explode("\\n", message)

        for i, line in ipairs(lines) do
            local trimmed = line:Trim()
            if trimmed:len() > 0 then
                ULib.tsayColor(_, true, info.color, trimmed) -- Delaying runs one message every frame (to ensure correct order)
            end
        end
    else
        ULib.csay(_, message, info.color, info.len)
    end

    ULib.queueFunctionCall(function()
        local nextid = math.fmod(id, #adverts[group]) + 1
        timer.Remove("ULXAdvert" .. type(group) .. group)
        timer.Create("ULXAdvert" .. type(group) .. group, adverts[group][nextid].rpt, 1, function() doAdvert(group, nextid) end)
    end)
end

-- Whether or not it's a csay is determined by whether there's a value specified in "len"
function ulx.addAdvert(message, rpt, group, color, len)
    local t

    if group then
        t = adverts[tostring(group)]
        if not t then
            t = {}
            adverts[tostring(group)] = t
        end
    else
        group = table.insert(adverts, {})
        t = adverts[group]
    end

    local id = table.insert(t, { message = message, rpt = rpt, color = color, len = len })

    if not timer.Exists("ULXAdvert" .. type(group) .. group) then
        timer.Create("ULXAdvert" .. type(group) .. group, rpt, 1, function() doAdvert(group, id) end)
    end
end

------------------------------ Gimp ------------------------------
ulx.gimpSays = ulx.gimpSays or {} -- Holds gimp says
local gimpSays = ulx.gimpSays     -- For XGUI, too lazy to change all refs
local ID_GIMP = 1
local ID_MUTE = 2

function ulx.addGimpSay(say)
    table.insert(gimpSays, say)
end

function ulx.clearGimpSays()
    table.Empty(gimpSays)
end

function ulx.gimp(calling_ply, target_plys, should_ungimp)
    for i = 1, #target_plys do
        local v = target_plys[i]
        if should_ungimp then
            v.gimp = nil
        else
            v.gimp = ID_GIMP
        end
        v:SetNWBool("ulx_gimped", not should_ungimp)
    end

    if not should_ungimp then
        ulx.fancyLogAdmin(calling_ply, "#A 使 #T 开始胡言乱语", target_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 使 #T 停止胡言乱语", target_plys)
    end
end

local gimp = ulx.command(CATEGORY_NAME, "ulx gimp", ulx.gimp, "!gimp")
gimp:addParam { type = ULib.cmds.PlayersArg }
gimp:addParam { type = ULib.cmds.BoolArg, invisible = true }
gimp:defaultAccess(ULib.ACCESS_ADMIN)
gimp:help("让指定玩家胡言乱语.")
gimp:setOpposite("ulx ungimp", { _, _, true }, "!ungimp")

------------------------------ Mute ------------------------------
function ulx.mute(calling_ply, target_plys, should_unmute)
    for i = 1, #target_plys do
        local v = target_plys[i]
        if should_unmute then
            v.gimp = nil
        else
            v.gimp = ID_MUTE
        end
        v:SetNWBool("ulx_muted", not should_unmute)
    end

    if not should_unmute then
        ulx.fancyLogAdmin(calling_ply, "#A 禁用 #T 的打字功能", target_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 给 #T 解除禁言", target_plys)
    end
end

local mute = ulx.command(CATEGORY_NAME, "ulx mute", ulx.mute, "!mute")
mute:addParam { type = ULib.cmds.PlayersArg }
mute:addParam { type = ULib.cmds.BoolArg, invisible = true }
mute:defaultAccess(ULib.ACCESS_ADMIN)
mute:help("禁言目标玩家使其无法聊天.")
mute:setOpposite("ulx unmute", { _, _, true }, "!unmute")

if SERVER then
    local function gimpCheck(ply, strText)
        if ply.gimp == ID_MUTE then return "" end
        if ply.gimp == ID_GIMP then
            if #gimpSays < 1 then return nil end
            return gimpSays[math.random(#gimpSays)]
        end
    end
    hook.Add("PlayerSay", "ULXGimpCheck", gimpCheck, HOOK_LOW)
end

------------------------------ MuteID ------------------------------
function ulx.muteid(calling_ply, steamid, should_unmute)
    steamid = steamid:upper()
    if not ULib.isValidSteamID(steamid) then
        ULib.tsayError(calling_ply, "无效的STEAMID.")
        return
    end

    local name, target_ply
    local plys = player.GetAll()
    for i = 1, #plys do
        if plys[i]:SteamID() == steamid then
            target_ply = plys[i]
            name = target_ply:Nick()
            break
        end
    end
    if should_unmute then
        target_ply.gimp = nil
    else
        target_ply.gimp = ID_MUTE
    end
    target_ply:SetNWBool("ulx_muted", not should_unmute)

    if not should_unmute then
        ulx.fancyLogAdmin(calling_ply, "#A 对 #T 禁言", target_ply)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 对 #T 取消禁言", target_ply)
    end
end

local muteid = ulx.command(CATEGORY_NAME, "ulx muteid", ulx.muteid, "!muteid")
muteid:addParam { type = ULib.cmds.StringArg, hint = "STEAM_0:0:" }
muteid:addParam { type = ULib.cmds.BoolArg, invisible = true }
muteid:defaultAccess(ULib.ACCESS_ADMIN)
muteid:help("使目标STEAMID禁言,使其无\n法聊天.")
muteid:setOpposite("ulx unmuteid", { _, _, true }, "!unmuteid")

if SERVER then
    local function gimpCheck(ply, strText)
        if ply.gimp == ID_MUTE then return "" end
        if ply.gimp == ID_GIMP then
            if #gimpSays < 1 then return nil end
            return gimpSays[math.random(#gimpSays)]
        end
    end
    hook.Add("PlayerSay", "ULXGimpCheck", gimpCheck, HOOK_LOW)
end

if SERVER then
    util.AddNetworkString("ignored")
end

if CLIENT then
    net.Receive("ignored", function()
        local ply = net.ReadEntity()
        local should_unignore = net.ReadBool()

        ply:SetMuted(not should_unignore)
    end)
end

function ulx.ignore(calling_ply, target_ply, should_unignore)
    net.Start("ignored")
    net.WriteEntity(target_ply)
    net.WriteBool(should_unignore)
    net.Send(calling_ply)

    if should_unignore then
        ULib.tsayColor(nil, false, Color(255, 0, 0), calling_ply:Nick(), Color(255, 255, 255), " 取消静音了 ", Color(255, 0, 0), target_ply:Nick())
    else
        ULib.tsayColor(nil, false, Color(255, 0, 0), calling_ply:Nick(), Color(255, 255, 255), " 静音了 ", Color(255, 0, 0), target_ply:Nick())
    end
end

local ignore = ulx.command(CATEGORY_NAME, "ulx ignore", ulx.ignore, "!ignore")
ignore:addParam { type = ULib.cmds.PlayerArg }
ignore:addParam { type = ULib.cmds.BoolArg, invisible = true }
ignore:defaultAccess(ULib.ACCESS_ALL)
ignore:help("在本地静音或取消静音目标玩家.")
ignore:setOpposite("ulx unignore", { _, _, true }, "!unignore")

------------------------------ Gag ------------------------------
function ulx.gag(calling_ply, target_plys, should_ungag)
    local players = player.GetAll()
    for i = 1, #target_plys do
        local v = target_plys[i]
        v.ulx_gagged = not should_ungag
        v:SetNWBool("ulx_gagged", v.ulx_gagged)
    end

    if not should_ungag then
        ulx.fancyLogAdmin(calling_ply, "#A 禁言了 #T 的麦克风", target_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 解禁了 #T 的麦克风", target_plys)
    end
end

local gag = ulx.command(CATEGORY_NAME, "ulx gag", ulx.gag, "!gag")
gag:addParam { type = ULib.cmds.PlayersArg }
gag:addParam { type = ULib.cmds.BoolArg, invisible = true }
gag:defaultAccess(ULib.ACCESS_ADMIN)
gag:help("禁言目标玩家麦克风.")
gag:setOpposite("ulx ungag", { _, _, true }, "!ungag")

local function gagHook(listener, talker)
    if talker.ulx_gagged then
        return false
    end
end
hook.Add("PlayerCanHearPlayersVoice", "ULXGag", gagHook)

------------------------------ GagID ------------------------------
function ulx.gagid(calling_ply, steamid, should_ungag)
    steamid = steamid:upper()
    if not ULib.isValidSteamID(steamid) then
        ULib.tsayError(calling_ply, "无效的STEAMID.")
        return
    end

    local name, target_ply
    local plys = player.GetAll()
    for i = 1, #plys do
        if plys[i]:SteamID() == steamid then
            target_ply = plys[i]
            name = target_ply:Nick()
            break
        end
    end
    target_ply.ulx_gagged = not should_ungag
    target_ply:SetNWBool("ulx_gagged", target_ply.ulx_gagged)

    if not should_ungag then
        ulx.fancyLogAdmin(calling_ply, "#A 对 #T 禁了语音", target_ply)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 对 #T 解禁语音", target_ply)
    end
end

local gagid = ulx.command(CATEGORY_NAME, "ulx gagid", ulx.gagid, "!gagid")
gagid:addParam { type = ULib.cmds.StringArg, hint = "STEAM_0:0:" }
gagid:addParam { type = ULib.cmds.BoolArg, invisible = true }
gagid:defaultAccess(ULib.ACCESS_ADMIN)
gagid:help("对目标STEAMID禁止语音.")
gagid:setOpposite("ulx ungagid", { _, _, true }, "!ungagid")

ULXColors = {
    ["白色"] = Color(255, 255, 255),
    ["红色"] = Color(255, 0, 0),
    ["栗色"] = Color(128, 0, 0),
    ["蓝"] = Color(0, 0, 255),
    ["绿"] = Color(0, 255, 0),
    ["橙色"] = Color(255, 127, 0),
    ["紫色"] = Color(51, 0, 102),
    ["粉色"] = Color(255, 0, 97),
    ["黄色"] = Color(255, 255, 0),
    ["黑"] = Color(0, 0, 0),
    ["灰色"] = Color(96, 96, 96)
}

ULXColorTblTxt = {}
local mov = 1
for k, v in pairs(ULXColors) do
    table.insert(ULXColorTblTxt, mov, k)
    mov = mov + 1
end

function ulx.tsaycolor(calling_ply, message, color)
    message = tostring(message)
    color = string.lower(tostring(color))
    for k, v in pairs(ULXColors) do
        if (k == color) then
            ULib.tsayColor(calling_ply, false, ULXColors[k], message)
        end
    end
    if (GetConVar("ulx_logChat"):GetInt() > 0) then
        ulx.logString(string.format("(Tsay 来自 %s) %s", (IsValid(calling_ply)) and ((calling_ply.Nick and calling_ply:Nick()) or "控制台"), message))
    end
end

local tsaycolor = ulx.command(CATEGORY_NAME, "ulx tsaycolor", ulx.tsaycolor, { "!tcol", "!tcolor", "!color", "!tsaycolor" }, true, true)
tsaycolor:addParam { type = ULib.cmds.StringArg, hint = "消息" }
tsaycolor:addParam { type = ULib.cmds.StringArg, hint = "请选择颜色", completes = ULXColorTblTxt, ULib.cmds.restrictToCompletes }
tsaycolor:defaultAccess(ULib.ACCESS_ADMIN)
tsaycolor:help("向所有人发送彩色信息.")

local notiTypesTxt = {
    "generic",
    "error",
    "hint",
    "cleanup",
    "undo",
    "progress"
}
function ulx.notifications(calling_ply, target_plys, text, ntype, duration)
    duration = tonumber(duration)
    for _, v in ipairs(target_plys) do
        if (ntype == "progress") then
            local num = math.random()
            v:SendLua("notification.AddProgress(" .. num .. ", \"" .. text .. "\")")
            timer.Simple(duration, function()
                v:SendLua("notification.Kill(" .. num .. ")")
            end)
        else
            ntype = "NOTIFY_" .. string.upper(ntype)
            v:SendLua("notification.AddLegacy(\"" .. text .. "\", " .. ntype .. ", " .. duration .. ")")
        end
        ULib.console(v, "Notification: " .. text)
        v:SendLua("surface.PlaySound(\"buttons/button15.wav\")")
    end
end

local notifications = ulx.command(CATEGORY_NAME, "ulx notifications", ulx.notifications, { "!notifications", "!notify", "!noti" }, false)
notifications:addParam { type = ULib.cmds.PlayersArg }
notifications:addParam { type = ULib.cmds.StringArg, hint = "文本" }
notifications:addParam { type = ULib.cmds.StringArg, hint = "类型", completes = notiTypesTxt, ULib.cmds.restrictToCompletes }
notifications:addParam { type = ULib.cmds.NumArg, default = 5, min = 3, max = 15, hint = "期间", ULib.cmds.optional }
notifications:defaultAccess(ULib.ACCESS_ADMIN)
notifications:help("向玩家发送沙盒类型的通知.")

function ulx.csaycolor(calling_ply, message, color)
    message = tostring(message)
    color = string.lower(tostring(color))
    for k, v in pairs(ULXColors) do
        if (k == color) then
            ULib.csay(calling_ply, message, ULXColors[k])
        end
    end
    if (GetConVar("ulx_logChat"):GetInt() > 0) then
        ulx.logString(string.format("(Csay 来自 %s) %s", (IsValid(calling_ply)) and ((calling_ply.Nick and calling_ply:Nick()) or "控制台"), message))
    end
end

local csaycolor = ulx.command(CATEGORY_NAME, "ulx csaycolor", ulx.csaycolor, { "!csaycolor", "!ccolor" }, true, true)
csaycolor:addParam { type = ULib.cmds.StringArg, hint = "消息" }
csaycolor:addParam { type = ULib.cmds.StringArg, hint = "请选择颜色", completes = ULXColorTblTxt, ULib.cmds.restrictToCompletes }
csaycolor:defaultAccess(ULib.ACCESS_ADMIN)
csaycolor:help("向每个人发送彩色的、居中的信息.")

local function gagHook(listener, talker)
    if talker.ulx_gagged then
        return false
    end
end
hook.Add("PlayerCanHearPlayersVoice", "ULXGag", gagHook)

-- Anti-spam stuff
if SERVER then
    local chattime_cvar = ulx.convar("chattime", "1.5", "<time> - Players can only chat every x seconds (anti-spam). 0 to disable.", ULib.ACCESS_ADMIN)
    local function playerSay(ply)
        if not ply.lastChatTime then ply.lastChatTime = 0 end

        local chattime = chattime_cvar:GetFloat()
        if chattime <= 0 then return end

        if ply.lastChatTime + chattime > CurTime() then
            return ""
        else
            ply.lastChatTime = CurTime()
            return
        end
    end
    hook.Add("PlayerSay", "ulxPlayerSay", playerSay, HOOK_LOW)

    local function meCheck(ply, strText, bTeam)
        local meChatEnabled = GetConVarNumber("ulx_meChatEnabled")

        if ply.gimp or meChatEnabled == 0 or (meChatEnabled ~= 2 and GAMEMODE.Name ~= "Sandbox") then return end -- Don't mess

        if strText:sub(1, 4) == "/me " then
            strText = string.format("*** %s %s", ply:Nick(), strText:sub(5))
            if not bTeam then
                ULib.tsay(_, strText)
            else
                strText = "(TEAM) " .. strText
                local teamid = ply:Team()
                local players = team.GetPlayers(teamid)
                for _, ply2 in ipairs(players) do
                    ULib.tsay(ply2, strText)
                end
            end

            if game.IsDedicated() then
                Msg(strText .. "\n") -- Log to console
            end
            if ULib.toBool(GetConVarNumber("ulx_logChat")) then
                ulx.logString(strText)
            end

            return ""
        end
    end
    hook.Add("PlayerSay", "ULXMeCheck", meCheck, HOOK_LOW) -- Extremely low priority
end

local function showWelcome(ply)
    local message = GetConVarString("ulx_welcomemessage")
    if not message or message == "" then return end

    message = string.gsub(message, "%%curmap%%", game.GetMap())
    message = string.gsub(message, "%%host%%", GetConVarString("hostname"))
    message = string.gsub(message, "%%ulx_version%%", ULib.pluginVersionStr("ULX"))

    ply:ChatPrint(message) -- We're not using tsay because ULib might not be loaded yet. (client side)
end

hook.Add("PlayerInitialSpawn", "ULXWelcome", showWelcome)

if SERVER then
    ulx.convar("meChatEnabled", "1", "Allow players to use '/me' in chat. 0 = Disabled, 1 = Sandbox only (Default), 2 = Enabled", ULib.ACCESS_ADMIN)
    ulx.convar("welcomemessage", "", "<msg> - This is shown to players on join.", ULib.ACCESS_ADMIN)
end
