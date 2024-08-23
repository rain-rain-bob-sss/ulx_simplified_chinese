local CATEGORY_NAME = "权限"

function ulx.explode(calling_ply, target_plys)
    for k, v in pairs(target_plys) do
        local playerpos = v:GetPos()

        local waterlevel = v:WaterLevel()

        timer.Simple(0.1, function()
            local traceworld = {}
            traceworld.start = playerpos
            traceworld.endpos = traceworld.start + (Vector(0, 0, -1) * 250)
            local trw = util.TraceLine(traceworld)
            local worldpos1 = trw.HitPos + trw.HitNormal
            local worldpos2 = trw.HitPos - trw.HitNormal
            util.Decal("Scorch", worldpos1, worldpos2)
        end)

        if GetConVarNumber("explode_ragdolls") == 1 then
            v:SetVelocity(Vector(0, 0, 10) * math.random(75, 150))
            timer.Simple(0.05, function() v:Kill() end)
        elseif GetConVarNumber("explode_ragdolls") == 0 then
            v:Kill()
        end

        util.ScreenShake(playerpos, 5, 5, 1.5, 200)

        if (waterlevel > 1) then
            local vPoint = playerpos + Vector(0, 0, 10)
            local effectdata = EffectData()
            effectdata:SetStart(vPoint)
            effectdata:SetOrigin(vPoint)
            effectdata:SetScale(1)
            util.Effect("WaterSurfaceExplosion", effectdata)
            local vPoint = playerpos + Vector(0, 0, 10)
            local effectdata = EffectData()
            effectdata:SetStart(vPoint)
            effectdata:SetOrigin(vPoint)
            effectdata:SetScale(1)
            util.Effect("HelicopterMegaBomb", effectdata)
        else
            local vPoint = playerpos + Vector(0, 0, 10)
            local effectdata = EffectData()
            effectdata:SetStart(vPoint)
            effectdata:SetOrigin(vPoint)
            effectdata:SetScale(1)
            util.Effect("HelicopterMegaBomb", effectdata)
            v:EmitSound(Sound("ambient/explosions/explode_4.wav"))
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 爆炸 #T", target_plys)
end

local explode = ulx.command(CATEGORY_NAME, "ulx explode", ulx.explode, "!explode")
explode:addParam { type = ULib.cmds.PlayersArg }
explode:defaultAccess(ULib.ACCESS_SUPERADMIN)
explode:help("爆炸某个玩家.")

------------------------------ Slap ------------------------------
function ulx.slap(calling_ply, target_plys, dmg)
    local affected_plys = {}

    for i = 1, #target_plys do
        local v = target_plys[i]
        if v:IsFrozen() then
            ULib.tsayError(calling_ply, v:Nick() .. " 已经被冻住了!", true)
        else
            ULib.slap(v, dmg)
            table.insert(affected_plys, v)
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 打了 #T 的脸并附带 #i 伤害", affected_plys, dmg)
end

local slap = ulx.command(CATEGORY_NAME, "ulx slap", ulx.slap, "!slap")
slap:addParam { type = ULib.cmds.PlayersArg }
slap:addParam { type = ULib.cmds.NumArg, min = 0, default = 0, hint = "伤害", ULib.cmds.optional, ULib.cmds.round }
slap:defaultAccess(ULib.ACCESS_ADMIN)
slap:help("打目标玩家的脸并附带伤害.")

------------------------------ Whip ------------------------------
function ulx.whip(calling_ply, target_plys, times, dmg)
    local affected_plys = {}

    for i = 1, #target_plys do
        local v = target_plys[i]

        if v.whipped then
            ULib.tsayError(calling_ply, v:Nick() .. " 正在被 " .. v.whippedby .. " 打脸!", true)
        elseif v:IsFrozen() then
            ULib.tsayError(calling_ply, v:Nick() .. " 被冻住了!", true)
        else
            local dtime = 0
            v.whipped = true
            v.whippedby = calling_ply:IsValid() and calling_ply:Nick() or "(Console)"
            v.whipcount = 0
            v.whipamt = times

            timer.Create("ulxWhip" .. v:EntIndex(), 0.5, 0,
                function() -- Repeat forever, we have an unhooker inside.
                    if not v:IsValid() then
                        timer.Remove("ulxWhip" .. v:EntIndex())
                        return
                    end -- Gotta make sure they're still there since this is a timer.
                    if v.whipcount == v.whipamt or not v:Alive() then
                        v.whipped = nil
                        v.whippedby = nil
                        v.whipcount = nil
                        v.whipamt = nil
                        timer.Remove("ulxWhip" .. v:EntIndex())
                    else
                        ULib.slap(v, dmg)
                        v.whipcount = v.whipcount + 1
                    end
                end)

            table.insert(affected_plys, v)
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 打了 #T 的脸 #i 次并附带 #i 伤害", affected_plys, times, dmg)
end

local whip = ulx.command(CATEGORY_NAME, "ulx whip", ulx.whip, "!whip")
whip:addParam { type = ULib.cmds.PlayersArg }
whip:addParam { type = ULib.cmds.NumArg, min = 2, max = 1000000, default = 10, hint = "次数", ULib.cmds.optional, ULib.cmds.round }
whip:addParam { type = ULib.cmds.NumArg, min = 0, max = 1000000, default = 0, hint = "伤害", ULib.cmds.optional, ULib.cmds.round }
whip:defaultAccess(ULib.ACCESS_ADMIN)
whip:help("设置打目标玩家多少次脸并\n且每次附带的伤害.")

------------------------------ Slay ------------------------------
function ulx.slay(calling_ply, target_plys)
    local affected_plys = {}

    for i = 1, #target_plys do
        local v = target_plys[i]

        if ulx.getExclusive(v, calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
        elseif not v:Alive() then
            ULib.tsayError(calling_ply, v:Nick() .. " 已经死了!", true)
        elseif v:IsFrozen() then
            ULib.tsayError(calling_ply, v:Nick() .. " 被冻住了!", true)
        else
            v:Kill()
            table.insert(affected_plys, v)
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 杀死了 #T", affected_plys)
end

local slay = ulx.command(CATEGORY_NAME, "ulx slay", ulx.slay, "!slay")
slay:addParam { type = ULib.cmds.PlayersArg }
slay:defaultAccess(ULib.ACCESS_ADMIN)
slay:help("杀死某个玩家.")

------------------------------ Sslay ------------------------------
function ulx.sslay(calling_ply, target_plys)
    local affected_plys = {}

    for i = 1, #target_plys do
        local v = target_plys[i]

        if ulx.getExclusive(v, calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
        elseif not v:Alive() then
            ULib.tsayError(calling_ply, v:Nick() .. " 已经死了!", true)
        elseif v:IsFrozen() then
            ULib.tsayError(calling_ply, v:Nick() .. " 被冻住了!", true)
        else
            if v:InVehicle() then
                v:ExitVehicle()
            end

            v:KillSilent()
            table.insert(affected_plys, v)
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 悄咪咪地杀死了 #T", affected_plys)
end

local sslay = ulx.command(CATEGORY_NAME, "ulx sslay", ulx.sslay, "!sslay")
sslay:addParam { type = ULib.cmds.PlayersArg }
sslay:defaultAccess(ULib.ACCESS_ADMIN)
sslay:help("悄咪咪地杀死某个玩家.")

------------------------------ Ignite ------------------------------
function ulx.ignite(calling_ply, target_plys, seconds, should_extinguish)
    local affected_plys = {}

    for i = 1, #target_plys do
        local v = target_plys[i]

        if not should_extinguish then
            v:Ignite(seconds)
            v.ulx_ignited_until = CurTime() + seconds
            table.insert(affected_plys, v)
        elseif v:IsOnFire() then
            v:Extinguish()
            v.ulx_ignited_until = nil
            table.insert(affected_plys, v)
        end
    end

    if not should_extinguish then
        ulx.fancyLogAdmin(calling_ply, "#A 点燃了 #T #i 秒", affected_plys, seconds)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 给 #T 灭了火", affected_plys)
    end
end

local ignite = ulx.command(CATEGORY_NAME, "ulx ignite", ulx.ignite, "!ignite")
ignite:addParam { type = ULib.cmds.PlayersArg }
ignite:addParam { type = ULib.cmds.NumArg, min = 1, max = 300, default = 300, hint = "时长(秒)", ULib.cmds.optional,
    ULib.cmds.round }
ignite:addParam { type = ULib.cmds.BoolArg, invisible = true }
ignite:defaultAccess(ULib.ACCESS_ADMIN)
ignite:help("点燃某人.")
ignite:setOpposite("ulx unignite", { _, _, _, true }, "!unignite")

local function checkFireDeath(ply)
    if ply.ulx_ignited_until and ply.ulx_ignited_until >= CurTime() and ply:IsOnFire() then
        ply:Extinguish()
        ply.ulx_ignited_until = nil
    end
end
hook.Add("PlayerDeath", "ULXCheckFireDeath", checkFireDeath, HOOK_MONITOR_HIGH)

------------------------------ Unigniteall ------------------------------
function ulx.unigniteall(calling_ply)
    local flame_ents = ents.FindByClass('entityflame')
    for _, v in ipairs(flame_ents) do
        if v:IsValid() then
            v:Remove()
        end
    end

    local plys = player.GetAll()
    for _, v in ipairs(plys) do
        if v:IsOnFire() then
            v:Extinguish()
            v.ulx_ignited_until = nil
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 给所有实体灭火")
end

local unigniteall = ulx.command(CATEGORY_NAME, "ulx unigniteall", ulx.unigniteall, "!unigniteall")
unigniteall:defaultAccess(ULib.ACCESS_ADMIN)
unigniteall:help("给所有的玩家和实体灭火.")

------------------------------ Playsound ------------------------------
if SERVER then
    util.AddNetworkString("ulib_sound")
end

function ulx.playsound(calling_ply, sound)
    if not ULib.fileExists("sound/" .. sound) then
        ULib.tsayError(calling_ply, "这个音效不存在于服务器内!", true)
        return
    end

    net.Start("ulib_sound")
    net.WriteString(Sound(sound))
    net.Broadcast()

    ulx.fancyLogAdmin(calling_ply, "#A 播放音效 #s", sound)
end

local playsound = ulx.command(CATEGORY_NAME, "ulx playsound", ulx.playsound)
playsound:addParam { type = ULib.cmds.StringArg, hint = "sound", autocomplete_fn = ulx.soundComplete }
playsound:defaultAccess(ULib.ACCESS_ADMIN)
playsound:help("播放音效 (需要绝对路径).")

------------------------------ Freeze ------------------------------
function ulx.freeze(calling_ply, target_plys, should_unfreeze)
    local affected_plys = {}
    for i = 1, #target_plys do
        if not should_unfreeze and ulx.getExclusive(target_plys[i], calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(target_plys[i], calling_ply), true)
        else
            local v = target_plys[i]
            if v:InVehicle() then
                v:ExitVehicle()
            end

            if not should_unfreeze then
                v:Lock()
                v.frozen = true
                ulx.setExclusive(v, "被冻住了")
            else
                v:UnLock()
                v.frozen = nil
                ulx.clearExclusive(v)
            end

            v:DisallowSpawning(not should_unfreeze)
            ulx.setNoDie(v, not should_unfreeze)
            table.insert(affected_plys, v)

            if v.whipped then
                v.whipcount = v.whipamt -- Will make it remove
            end
        end
    end

    if not should_unfreeze then
        ulx.fancyLogAdmin(calling_ply, "#A 冻住了 #T", affected_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 解冻了 #T", affected_plys)
    end
end

local freeze = ulx.command(CATEGORY_NAME, "ulx freeze", ulx.freeze, "!freeze")
freeze:addParam { type = ULib.cmds.PlayersArg }
freeze:addParam { type = ULib.cmds.BoolArg, invisible = true }
freeze:defaultAccess(ULib.ACCESS_ADMIN)
freeze:help("冻住某玩家.")
freeze:setOpposite("ulx unfreeze", { _, _, true }, "!unfreeze")

------------------------------ God ------------------------------
function ulx.god(calling_ply, target_plys, should_revoke)
    if not target_plys[1]:IsValid() then
        if not should_revoke then
            Msg("控制台要什么无敌.\n")
        else
            Msg("你的上帝地位是不可改变的如果你不喜欢它,离开矩阵.\n")
        end
        return
    end

    local affected_plys = {}
    for i = 1, #target_plys do
        local v = target_plys[i]

        if ulx.getExclusive(v, calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
        else
            if not should_revoke then
                v:GodEnable()
                v.ULXHasGod = true
            else
                v:GodDisable()
                v.ULXHasGod = nil
            end
            table.insert(affected_plys, v)
        end
    end

    if not should_revoke then
        ulx.fancyLogAdmin(calling_ply, "#A 为 #T 开启无敌模式", affected_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 为 #T 移除无敌模式", affected_plys)
    end
end

local god = ulx.command(CATEGORY_NAME, "ulx god", ulx.god, "!god")
god:addParam { type = ULib.cmds.PlayersArg, ULib.cmds.optional }
god:addParam { type = ULib.cmds.BoolArg, invisible = true }
god:defaultAccess(ULib.ACCESS_ADMIN)
god:help("为某玩家开启/关闭无敌.")
god:setOpposite("ulx ungod", { _, _, true }, "!ungod")

------------------------------ Hp ------------------------------
function ulx.hp(calling_ply, target_plys, amount)
    for i = 1, #target_plys do
        target_plys[i]:SetHealth(amount)
    end
    ulx.fancyLogAdmin(calling_ply, "#A 设置 #T 的血量为 #i", target_plys, amount)
end

local hp = ulx.command(CATEGORY_NAME, "ulx hp", ulx.hp, "!hp")
hp:addParam { type = ULib.cmds.PlayersArg }
hp:addParam { type = ULib.cmds.NumArg, min = 1, max = 2 ^ 32 / 2 - 1, hint = "血量值", ULib.cmds.round }
hp:defaultAccess(ULib.ACCESS_ADMIN)
hp:help("设置目标玩家血量.")

------------------------------ Armor ------------------------------
function ulx.armor(calling_ply, target_plys, amount)
    for i = 1, #target_plys do
        target_plys[i]:SetArmor(amount)
    end
    ulx.fancyLogAdmin(calling_ply, "#A 设置 #T 的护甲为 #i", target_plys, amount)
end

local armor = ulx.command(CATEGORY_NAME, "ulx armor", ulx.armor, "!armor")
armor:addParam { type = ULib.cmds.PlayersArg }
armor:addParam { type = ULib.cmds.NumArg, min = 0, max = 255, hint = "护甲值", ULib.cmds.round }
armor:defaultAccess(ULib.ACCESS_ADMIN)
armor:help("设置目标玩家的护甲.")

------------------------------ Cloak ------------------------------
function ulx.cloak(calling_ply, target_plys, amount, should_uncloak)
    if not target_plys[1]:IsValid() then
        Msg("你隐身效果还是**:**呢.\n")
        return
    end

    amount = 255 - amount

    for i = 1, #target_plys do
        ULib.invisible(target_plys[i], not should_uncloak, amount)
    end

    if not should_uncloak then
        ulx.fancyLogAdmin(calling_ply, "#A 设置 #T 的透明度为 #i", target_plys, amount)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 为 #T 关闭透明度", target_plys)
    end
end

local cloak = ulx.command(CATEGORY_NAME, "ulx cloak", ulx.cloak, "!cloak")
cloak:addParam { type = ULib.cmds.PlayersArg, ULib.cmds.optional }
cloak:addParam { type = ULib.cmds.NumArg, min = 0, max = 255, default = 255, hint = "透明度", ULib.cmds.round, ULib.cmds.optional }
cloak:addParam { type = ULib.cmds.BoolArg, invisible = true }
cloak:defaultAccess(ULib.ACCESS_ADMIN)
cloak:help("给目标玩家设置透明度.")
cloak:setOpposite("ulx uncloak", { _, _, _, true }, "!uncloak")

------------------------------ Blind ------------------------------
if SERVER then
    util.AddNetworkString("ulx_blind")
end
function ulx.blind(calling_ply, target_plys, amount, should_unblind)
    for i = 1, #target_plys do
        local v = target_plys[i]

        net.Start("ulx_blind")
        net.WriteBool(not should_unblind)
        net.WriteInt(amount, 16)
        net.Send(v)

        if should_unblind then
            if v.HadCamera then
                v:Give("gmod_camera")
            end
            v.HadCamera = nil
        else
            if v.HadCamera == nil then -- In case blind is run twice
                v.HadCamera = v:HasWeapon("gmod_camera")
            end
            v:StripWeapon("gmod_camera")
        end
    end

    if not should_unblind then
        ulx.fancyLogAdmin(calling_ply, "#A 戳瞎了 #T 的眼睛,透明度为 #i", target_plys, amount)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 恢复了 #T 的眼睛", target_plys)
    end
end

local blind = ulx.command(CATEGORY_NAME, "ulx blind", ulx.blind, "!blind")
blind:addParam { type = ULib.cmds.PlayersArg }
blind:addParam { type = ULib.cmds.NumArg, min = 0, max = 255, default = 255, hint = "透明度", ULib.cmds.round, ULib.cmds.optional }
blind:addParam { type = ULib.cmds.BoolArg, invisible = true }
blind:defaultAccess(ULib.ACCESS_ADMIN)
blind:help("搞瞎某个玩家.")
blind:setOpposite("ulx unblind", { _, _, _, true }, "!unblind")

------------------------------ Jail ------------------------------
local doJail
local jailableArea
function ulx.jail(calling_ply, target_plys, seconds, should_unjail)
    local affected_plys = {}
    for i = 1, #target_plys do
        local v = target_plys[i]

        if not should_unjail then
            if ulx.getExclusive(v, calling_ply) then
                ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
            elseif not jailableArea(v:GetPos()) then
                ULib.tsayError(calling_ply, v:Nick() .. " 没有足够的空间放置监狱!", true)
            else
                doJail(v, seconds)

                table.insert(affected_plys, v)
            end
        elseif v.jail then
            v.jail.unjail()
            v.jail = nil
            table.insert(affected_plys, v)
        end
    end

    if not should_unjail then
        local str = "#A 监禁了 #T"
        if seconds > 0 then
            str = str .. " #i 秒"
        end
        ulx.fancyLogAdmin(calling_ply, str, affected_plys, seconds)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 放出了 #T", affected_plys)
    end
end

local jail = ulx.command(CATEGORY_NAME, "ulx jail", ulx.jail, "!jail")
jail:addParam { type = ULib.cmds.PlayersArg }
jail:addParam { type = ULib.cmds.NumArg, min = 0, default = 0, hint = "监禁时长(秒),0为无限", ULib.cmds.round,
    ULib.cmds.optional }
jail:addParam { type = ULib.cmds.BoolArg, invisible = true }
jail:defaultAccess(ULib.ACCESS_ADMIN)
jail:help("监禁某个玩家.")
jail:setOpposite("ulx unjail", { _, _, _, true }, "!unjail")

------------------------------ Jail TP ------------------------------
function ulx.jailtp(calling_ply, target_ply, seconds)
    local t = {}
    t.start = calling_ply:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
    t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
    t.filter = target_ply
    if target_ply ~= calling_ply then
        t.filter = { target_ply, calling_ply }
    end
    local tr = util.TraceEntity(t, target_ply)

    local pos = tr.HitPos

    if ulx.getExclusive(target_ply, calling_ply) then
        ULib.tsayError(calling_ply, ulx.getExclusive(target_ply, calling_ply), true)
        return
    elseif not target_ply:Alive() then
        ULib.tsayError(calling_ply, target_ply:Nick() .. " 已经死了!", true)
        return
    elseif not jailableArea(pos) then
        ULib.tsayError(calling_ply, "没有足够的空间放置监狱!", true)
        return
    else
        target_ply.ulx_prevpos = target_ply:GetPos()
        target_ply.ulx_prevang = target_ply:EyeAngles()

        if target_ply:InVehicle() then
            target_ply:ExitVehicle()
        end

        target_ply:SetPos(pos)
        target_ply:SetLocalVelocity(Vector(0, 0, 0)) -- Stop!

        doJail(target_ply, seconds)
    end

    local str = "#A 传送并监禁了 #T"
    if seconds > 0 then
        str = str .. " #i 秒"
    end
    ulx.fancyLogAdmin(calling_ply, str, target_ply, seconds)
end

local jailtp = ulx.command(CATEGORY_NAME, "ulx jailtp", ulx.jailtp, "!jailtp")
jailtp:addParam { type = ULib.cmds.PlayerArg }
jailtp:addParam { type = ULib.cmds.NumArg, min = 0, default = 0, hint = "监禁时长(秒),0为无限", ULib.cmds.round, ULib.cmds.optional }
jailtp:defaultAccess(ULib.ACCESS_ADMIN)
jailtp:help("传送至准星所指的地方,再监\n禁玩家.")

local function jailCheck()
    local remove_timer = true
    local players = player.GetAll()
    for i = 1, #players do
        local ply = players[i]
        if ply.jail then
            remove_timer = false
        end
        if ply.jail and (ply.jail.pos - ply:GetPos()):LengthSqr() >= 6500 then
            ply:SetPos(ply.jail.pos)
            if ply.jail.jail_until then
                doJail(ply, ply.jail.jail_until - CurTime())
            else
                doJail(ply, 0)
            end
        end
    end

    if remove_timer then
        timer.Remove("ULXJail")
    end
end

jailableArea = function(pos)
    entList = ents.FindInBox(pos - Vector(35, 35, 5), pos + Vector(35, 35, 110))
    for i = 1, #entList do
        if entList[i]:GetClass() == "trigger_remove" then
            return false
        end
    end

    return true
end

local mdl1 = Model("models/props_building_details/Storefront_Template001a_Bars.mdl")
local jail = {
    { pos = Vector(0, 0, -5), ang = Angle(90, 0, 0), mdl = mdl1 },
    { pos = Vector(0, 0, 97), ang = Angle(90, 0, 0), mdl = mdl1 },
    { pos = Vector(21, 31, 46), ang = Angle(0, 90, 0), mdl = mdl1 },
    { pos = Vector(21, -31, 46), ang = Angle(0, 90, 0), mdl = mdl1 },
    { pos = Vector(-21, 31, 46), ang = Angle(0, 90, 0), mdl = mdl1 },
    { pos = Vector(-21, -31, 46), ang = Angle(0, 90, 0), mdl = mdl1 },
    { pos = Vector(-52, 0, 46), ang = Angle(0, 0, 0), mdl = mdl1 },
    { pos = Vector(52, 0, 46), ang = Angle(0, 0, 0), mdl = mdl1 },
}
doJail = function(v, seconds)
    if v.jail then -- They're already jailed
        v.jail.unjail()
    end

    if v:InVehicle() then
        local vehicle = v:GetParent()
        v:ExitVehicle()
        vehicle:Remove()
    end

    -- Force other players to let go of this player
    if v.physgunned_by then
        for ply, v in pairs(v.physgunned_by) do
            if ply:IsValid() and ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" then
                ply:ConCommand("-attack")
            end
        end
    end

    if v:GetMoveType() == MOVETYPE_NOCLIP then -- Take them out of noclip
        v:SetMoveType(MOVETYPE_WALK)
    end

    local pos = v:GetPos()

    local walls = {}
    for _, info in ipairs(jail) do
        local ent = ents.Create("prop_physics")
        ent:SetModel(info.mdl)
        ent:SetPos(pos + info.pos)
        ent:SetAngles(info.ang)
        ent:Spawn()
        ent:GetPhysicsObject():EnableMotion(false)
        ent:SetMoveType(MOVETYPE_NONE)
        ent.jailWall = true
        table.insert(walls, ent)
    end

    local key = {}
    local function unjail()
        if not v:IsValid() or not v.jail or v.jail.key ~= key then -- Nope
            return
        end

        for _, ent in ipairs(walls) do
            if ent:IsValid() then
                ent:DisallowDeleting(false)
                ent:Remove()
            end
        end
        if not v:IsValid() then return end -- Make sure they're still connected

        v:DisallowNoclip(false)
        v:DisallowMoving(false)
        v:DisallowSpawning(false)
        v:DisallowVehicles(false)

        ulx.clearExclusive(v)
        ulx.setNoDie(v, false)

        v.jail = nil
    end
    if seconds > 0 then
        timer.Simple(seconds, unjail)
    end

    local function newWall(old, new)
        table.insert(walls, new)
    end

    for _, ent in ipairs(walls) do
        ent:DisallowDeleting(true, newWall)
        ent:DisallowMoving(true)
    end
    v:DisallowNoclip(true)
    v:DisallowMoving(true)
    v:DisallowSpawning(true)
    v:DisallowVehicles(true)
    v.jail = { pos = pos, unjail = unjail, key = key }
    if seconds > 0 then
        v.jail.jail_until = CurTime() + seconds
    end
    ulx.setExclusive(v, "在监狱里了")
    ulx.setNoDie(v, true)

    timer.Create("ULXJail", 1, 0, jailCheck)
end

local function jailDisconnectedCheck(ply)
    if ply.jail then
        ply.jail.unjail()
    end
end
hook.Add("PlayerDisconnected", "ULXJailDisconnectedCheck", jailDisconnectedCheck, HOOK_MONITOR_HIGH)

local function playerPickup(ply, ent)
    if CLIENT then return end
    if ent:IsPlayer() then
        ent.physgunned_by = ent.physgunned_by or {}
        ent.physgunned_by[ply] = true
    end
end
hook.Add("PhysgunPickup", "ulxPlayerPickupJailCheck", playerPickup, HOOK_MONITOR_HIGH)

local function playerDrop(ply, ent)
    if CLIENT then return end
    if ent:IsPlayer() and ent.physgunned_by then
        ent.physgunned_by[ply] = nil
    end
end
hook.Add("PhysgunDrop", "ulxPlayerDropJailCheck", playerDrop)

------------------------------ Ragdoll ------------------------------
function ulx.ragdollPlayer(v)
    if v:InVehicle() then
        v:ExitVehicle()
    end

    ULib.getSpawnInfo(v) -- Collect information so we can respawn them in the same state.

    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll.ragdolledPly = v

    ragdoll:SetPos(v:GetPos())
    local velocity = v:GetVelocity()
    ragdoll:SetAngles(v:GetAngles())
    ragdoll:SetModel(v:GetModel())
    ragdoll:Spawn()
    ragdoll:Activate()
    v:SetParent(ragdoll) -- So their player ent will match up (position-wise) with where their ragdoll is.
    -- Set velocity for each piece of the ragdoll
    local j = 1
    while true do -- Break inside
        local phys_obj = ragdoll:GetPhysicsObjectNum(j)
        if phys_obj then
            phys_obj:SetVelocity(velocity)
            j = j + 1
        else
            break
        end
    end

    v:Spectate(OBS_MODE_CHASE)
    v:SpectateEntity(ragdoll)
    v:StripWeapons() -- Otherwise they can still use the weapons.

    ragdoll:DisallowDeleting(true, function(_, new)
        if v:IsValid() then v.ragdoll = new end
    end)
    v:DisallowSpawning(true)

    v.ragdoll = ragdoll
    ulx.setExclusive(v, "被布娃娃化了")
end

function ulx.unragdollPlayer(v)
    v:DisallowSpawning(false)
    v:SetParent()

    v:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox

    local ragdoll = v.ragdoll
    v.ragdoll = nil -- Gotta do this before spawn or our hook catches it

    if not ragdoll:IsValid() then -- Something must have removed it, just spawn
        ULib.spawn(v, true)
    else
        local pos = ragdoll:GetPos()
        pos.z = pos.z + 10 -- So they don't end up in the ground

        ULib.spawn(v, true)
        v:SetPos(pos)
        v:SetVelocity(ragdoll:GetVelocity())
        local yaw = ragdoll:GetAngles().yaw
        v:SetAngles(Angle(0, yaw, 0))
        ragdoll:DisallowDeleting(false)
        ragdoll:Remove()
    end

    ulx.clearExclusive(v)
end

function ulx.ragdoll(calling_ply, target_plys, should_unragdoll)
    local affected_plys = {}
    for i = 1, #target_plys do
        local v = target_plys[i]

        if not should_unragdoll then
            if ulx.getExclusive(v, calling_ply) then
                ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
            elseif not v:Alive() then
                ULib.tsayError(calling_ply, v:Nick() .. " 已经死了并且不能被布娃娃化!", true)
            else
                ulx.ragdollPlayer(v)
                table.insert(affected_plys, v)
            end
        elseif v.ragdoll then -- Only if they're ragdolled...
            ulx.unragdollPlayer(v)
            table.insert(affected_plys, v)
        end
    end

    if not should_unragdoll then
        ulx.fancyLogAdmin(calling_ply, "#A 布娃娃化了 #T", affected_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 解除了 #T 的布娃娃化", affected_plys)
    end
end

local ragdoll = ulx.command(CATEGORY_NAME, "ulx ragdoll", ulx.ragdoll, "!ragdoll")
ragdoll:addParam { type = ULib.cmds.PlayersArg }
ragdoll:addParam { type = ULib.cmds.BoolArg, invisible = true }
ragdoll:defaultAccess(ULib.ACCESS_ADMIN)
ragdoll:help("布娃娃化某玩家.")
ragdoll:setOpposite("ulx unragdoll", { _, _, true }, "!unragdoll")

local function ragdollSpawnCheck(ply)
    if ply.ragdoll then
        timer.Simple(0.01, function() -- Doesn't like us using it instantly
            if not ply:IsValid() then return end -- Make sure they're still here
            ply:Spectate(OBS_MODE_CHASE)
            ply:SpectateEntity(ply.ragdoll)
            ply:StripWeapons() -- Otherwise they can still use the weapons.
        end)
    end
end
hook.Add("PlayerSpawn", "ULXRagdollSpawnCheck", ragdollSpawnCheck)

local function ragdollDisconnectedCheck(ply)
    if ply.ragdoll then
        ply.ragdoll:DisallowDeleting(false)
        ply.ragdoll:Remove()
    end
end
hook.Add("PlayerDisconnected", "ULXRagdollDisconnectedCheck", ragdollDisconnectedCheck, HOOK_MONITOR_HIGH)

local function removeRagdollOnCleanup()
    local players = player.GetAll()
    for i = 1, #players do
        local ply = players[i]
        if ply.ragdoll then
            ply.ragdollAfterCleanup = true
            ulx.unragdollPlayer(ply)
        end
    end
end
hook.Add("PreCleanupMap", "ULXRagdollBeforeCleanup", removeRagdollOnCleanup)

local function createRagdollAfterCleanup()
    local players = player.GetAll()
    for i = 1, #players do
        local ply = players[i]
        if ply.ragdollAfterCleanup then
            ply.ragdollAfterCleanup = nil
            timer.Simple(0.1, function() -- Doesn't like us re-creating the ragdoll immediately
                ulx.ragdollPlayer(ply)
            end)
        end
    end
end
hook.Add("PostCleanupMap", "ULXRagdollAfterCleanup", createRagdollAfterCleanup)

------------------------------ Maul ------------------------------
local zombieDeath -- We need these registered up here because functions reference each other.
local checkMaulDeath

local function newZombie(pos, ang, ply, b)
    local ent = ents.Create("npc_fastzombie")
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ent:AddRelationship("player D_NU 98") -- Don't attack other players
    ent:AddEntityRelationship(ply, D_HT, 99) -- Hate target

    ent:DisallowDeleting(true, _, true)
    ent:DisallowMoving(true)

    if not b then
        ent:CallOnRemove("NoDie", zombieDeath, ply)
    end

    return ent
end

-- Utility function
zombieDeath = function(ent, ply)
    if ply.maul_npcs then -- Recreate!
        local pos = ent:GetPos()
        local ang = ent:GetAngles()
        ULib.queueFunctionCall(function() -- Create it next frame because 1. Old NPC won't be in way and 2. We won't overflow the server while shutting down with someone being mauled
            if not ply:IsValid() then return end -- Player left

            local ent2 = newZombie(pos, ang, ply)
            table.insert(ply.maul_npcs, ent2) -- Don't worry about removing the old one, doesn't matter.

            -- Make sure we didn't make a headcrab!
            local ents = ents.FindByClass("npc_headcrab_fast")
            for _, ent in ipairs(ents) do
                dist = ent:GetPos():Distance(pos)
                if dist < 128 then -- Assume it's from the zombies
                    ent:Remove()
                end
            end
        end)
    end
end

-- Another utility for maul
local function maulMoreDamage()
    local players = player.GetAll()
    for _, ply in ipairs(players) do
        if ply.maul_npcs and ply:Alive() then
            if CurTime() > ply.maulStart + 10 then
                local damage = math.ceil(ply.maulStartHP / 10) -- Damage per second
                damage = damage * FrameTime() -- Damage this frame
                damage = math.ceil(damage)
                local newhp = ply:Health() - damage
                if newhp < 1 then newhp = 1 end
                ply:SetHealth(newhp) -- We don't use takedamage because the player slides across the ground.
                if CurTime() > ply.maulStart + 20 then
                    ply:Kill() -- Worst case senario.
                    checkMaulDeath(ply) -- Just in case the death hook is broken
                end
            end
            ply.maul_lasthp = ply:Health()
        end
    end
end

function ulx.maul(calling_ply, target_plys)
    local affected_plys = {}
    for i = 1, #target_plys do
        local v = target_plys[i]

        if ulx.getExclusive(v, calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
        elseif not v:Alive() then
            ULib.tsayError(calling_ply, v:Nick() .. " 已经死了!", true)
        else
            local pos = {}
            local testent = newZombie(Vector(0, 0, 0), Angle(0, 0, 0), v, true) -- Test ent for traces

            local yawForward = v:EyeAngles().yaw
            local directions = { -- Directions to try
                math.NormalizeAngle(yawForward - 180), -- Behind first
                math.NormalizeAngle(yawForward + 90), -- Right
                math.NormalizeAngle(yawForward - 90), -- Left
                yawForward,
            }

            local t = {}
            t.start = v:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
            t.filter = { v, testent }

            for i = 1, #directions do -- Check all directions
                t.endpos = v:GetPos() + Angle(0, directions[i], 0):Forward() * 47 -- (33 is player width, this is sqrt( 33^2 * 2 ))
                local tr = util.TraceEntity(t, testent)

                if not tr.Hit then
                    table.insert(pos, v:GetPos() + Angle(0, directions[i], 0):Forward() * 47)
                end
            end

            testent:DisallowDeleting(false)
            testent:Remove() -- Don't forget to remove our friend now!

            if #pos > 0 then
                v.maul_npcs = {}
                for _, newpos in ipairs(pos) do
                    local newang = (v:GetPos() - newpos):Angle()

                    local ent = newZombie(newpos, newang, v)
                    table.insert(v.maul_npcs, ent)
                end

                v:SetMoveType(MOVETYPE_WALK)
                v:DisallowNoclip(true)
                v:DisallowSpawning(true)
                v:DisallowVehicles(true)
                v:GodDisable()
                v:SetArmor(0) -- Armor takes waaaay too long for them to take down
                v.maulOrigWalk = v:GetWalkSpeed()
                v.maulOrigSprint = v:GetRunSpeed()
                v:SetWalkSpeed(1)
                v:SetRunSpeed(1)

                v.maulStart = CurTime()
                v.maulStartHP = v:Health()
                hook.Add("Think", "MaulMoreDamageThink", maulMoreDamage)

                ulx.setExclusive(v, "被围攻了")

                table.insert(affected_plys, v)
            else
                ULib.tsayError(calling_ply, "找不到位置放置NPC在 " .. v:Nick() .. " 的身边", true)
            end
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 放僵尸围攻了 #T", affected_plys)
end

local maul = ulx.command(CATEGORY_NAME, "ulx maul", ulx.maul, "!maul")
maul:addParam { type = ULib.cmds.PlayersArg }
maul:defaultAccess(ULib.ACCESS_SUPERADMIN)
maul:help("围攻目标玩家.")

checkMaulDeath = function(ply, weapon, killer)
    if ply.maul_npcs then
        if killer == ply and CurTime() < ply.maulStart + 20 then -- Suicide
            ply:AddFrags(1) -- Won't show on scoreboard
            local pos = ply:GetPos()
            local ang = ply:EyeAngles()
            ULib.queueFunctionCall(function()
                if not ply:IsValid() then return end -- They left

                ply:Spawn()
                ply:SetPos(pos)
                ply:SetEyeAngles(ang)
                ply:SetArmor(0)
                ply:SetHealth(ply.maul_lasthp)
                timer.Simple(0.1, function()
                    if not ply:IsValid() then return end -- They left
                    ply:SetCollisionGroup(COLLISION_GROUP_WORLD)
                    ply:SetWalkSpeed(1)
                    ply:SetRunSpeed(1)
                end)
            end)
            return true -- Don't register their death on HUD
        end

        local npcs = ply.maul_npcs
        ply.maul_npcs = nil -- We have to do it this way to signal that we're done mauling
        for _, ent in ipairs(npcs) do
            if ent:IsValid() then
                ent:DisallowDeleting(false)
                ent:Remove()
            end
        end
        ulx.clearExclusive(ply)
        ply.maulStart = nil
        ply.maul_lasthp = nil

        ply:DisallowNoclip(false)
        ply:DisallowSpawning(false)
        ply:DisallowVehicles(false)
        ply:SetWalkSpeed(ply.maulOrigWalk)
        ply:SetRunSpeed(ply.maulOrigSprint)
        ply.maulOrigWalk = nil
        ply.maulOrigSprint = nil

        ulx.clearExclusive(ply)

        -- Now let's check if there's still players being mauled
        local players = player.GetAll()
        for _, ply in ipairs(players) do
            if ply.maul_npcs then
                return
            end
        end

        -- No more? Remove hook.
        hook.Remove("Think", "MaulMoreDamageThink")
    end
end
hook.Add("PlayerDeath", "ULXCheckMaulDeath", checkMaulDeath, HOOK_HIGH) -- Hook it first because we're changing speed. Want others to override us.

local function maulDisconnectedCheck(ply)
    checkMaulDeath(ply) -- Just run it through the death function
end
hook.Add("PlayerDisconnected", "ULXMaulDisconnectedCheck", maulDisconnectedCheck, HOOK_MONITOR_HIGH)

------------------------------ Strip ------------------------------
function ulx.stripweapons(calling_ply, target_plys)
    for i = 1, #target_plys do
        target_plys[i]:StripWeapons()
    end

    ulx.fancyLogAdmin(calling_ply, "#A 扒光了 #T 身上的所有武器", target_plys)
end

local strip = ulx.command(CATEGORY_NAME, "ulx strip", ulx.stripweapons, "!strip")
strip:addParam { type = ULib.cmds.PlayersArg }
strip:defaultAccess(ULib.ACCESS_ADMIN)
strip:help("扒光目标玩家身上的武器.")

--------------------- Set Players model ---------------------------
function ulx.setmodel(calling_ply, target_plys, modelPath, should_uncloak)
    if not target_plys[1]:IsValid() then
        Msg("目标玩家无效.\n")
        return
    end

    for i = 1, #target_plys do
        local ents = target_plys[i]
        ents:SetModel(modelPath)
        ents:SetupHands()
    end

    ulx.fancyLogAdmin(calling_ply, "#A 设置 #T 的模型为 " .. modelPath, target_plys)
end

local setmodel = ulx.command(CATEGORY_NAME, "ulx setmodel", ulx.setmodel, "!setmodel")
setmodel:addParam { type = ULib.cmds.PlayersArg, ULib.cmds.optional }
setmodel:addParam { type = ULib.cmds.StringArg, hint = "模型路径" }
setmodel:addParam { type = ULib.cmds.BoolArg, invisible = true }
setmodel:defaultAccess(ULib.ACCESS_SUPERADMIN)
setmodel:help("给目标玩家设置模型.")

------------------------------ Set Bodygroups ------------------------------
function ulx.setbody(calling_ply, target_plys, id, val)
    local affected_plys = {}

    for i = 1, #target_plys do
        local v = target_plys[i]
        v:SetBodygroup(id, val)
    end

    ulx.fancyLogAdmin(calling_ply, "#A 设置 #T 的模型附件序号 #i 为 #i", affected_plys, id, val)
end

local boday = ulx.command(CATEGORY_NAME, "ulx setbody", ulx.setbody, "!setbody")
boday:addParam { type = ULib.cmds.PlayersArg }
boday:addParam { type = ULib.cmds.NumArg, min = 0, default = 0, hint = "序号", ULib.cmds.optional, ULib.cmds.round }
boday:addParam { type = ULib.cmds.NumArg, min = 0, default = 0, hint = "数值", ULib.cmds.optional, ULib.cmds.round }
boday:defaultAccess(ULib.ACCESS_SUPERADMIN)
boday:help("调整目标玩家的模型附件.")

--------------------- SCP 4016 Watermelon ---------------------------
function ulx.watamelon(calling_ply)
    if not calling_ply:IsValid() then
        Msg("无法从服务器控制台创建实体.\n")
        return
    end

    local shiet = ents.Create("prop_physics")
    local trace = calling_ply:GetEyeTrace()
    local vector = trace.HitPos
    vector.z = vector.z + 20
    shiet:SetModel("models/props_junk/watermelon01.mdl")
    shiet:SetName("4016")
    shiet:SetKeyValue("Damagetype", 1)
    shiet:SetKeyValue("ExplodeDamage", 1000000)
    shiet:SetKeyValue("ExplodeRadius", 10000)
    shiet:SetKeyValue("massScale", 2)
    shiet:SetKeyValue("spawnflags", 258)
    shiet:SetKeyValue("PerformanceMode", 1)
    shiet:SetPos(vector)
    shiet:Spawn()

    undo.Create("ulx_ent")
    undo.AddEntity(shiet)
    undo.SetPlayer(calling_ply)
    undo.Finish()

    ulx.fancyLogAdmin(calling_ply, "#A 生成了一个小西瓜")
end

local watamelon = ulx.command(CATEGORY_NAME, "ulx watermelon", ulx.watamelon, "!melon", false, false, true)
watamelon:addParam { type = ULib.cmds.PlayersArg }
watamelon:defaultAccess(ULib.ACCESS_SUPERADMIN)
watamelon:help("生成SCP4016-小西瓜.")

function injectPointshopModule()
    hook.Add("PlayerInitialSpawn", "ULX_VariableSet", function(ply)
        timer.Simple(10, function()
            if (IsValid(ply)) then
                ply.canbrag = true
            end
        end)
    end)
    function startTimer(ply)
        timer.Simple(180, function()
            if (IsValid(ply)) then
                ply.canbrag = true
            end
        end)
    end

    function ulx.brag(calling_ply)
        if (IsValid(calling_ply) and calling_ply.canbrag) then
            calling_ply.canbrag = false
            startTimer(calling_ply)
            local pts = tonumber(calling_ply:PS_GetPoints())
            if (isnumber(pts) and (pts ~= 0)) then
                for _, v in ipairs(player.GetHumans()) do
                    if (IsValid(v)) then
                        v:ChatPrint("[BRAG]: " .. ((calling_ply.Nick and calling_ply:Nick()) or "?") .. " has " .. tostring(pts) .. " points!")
                    end
                end
            else
                ULib.tsayError(calling_ply, "[ERROR]: What are you gonna do, brag about being broke?")
            end
        elseif (IsValid(calling_ply) and not calling_ply.canbrag) then
            ULib.tsayError(calling_ply, "[ERROR]: You can't brag yet!")
        end
    end

    local brag = ulx.command("Pointshop", "ulx brag", ulx.brag, { "!brag", "!mypoints" }, true)
    brag:defaultAccess(ULib.ACCESS_ALL)
    brag:help("吹嘘你的积分商店积分!")
    function ulx.viewpoints(calling_ply, target_plys)
        for _, v in ipairs(target_plys) do
            if (IsValid(v)) then
                local pts = v:PS_GetPoints()
                calling_ply:ChatPrint("[POINTS]: " .. ((v.Nick and v:Nick()) or "?") .. " has " .. pts .. " points!")
            else
                ULib.tsayError(calling_ply, "[ERROR]: Not a valid player!")
            end
        end
    end

    local viewpoints = ulx.command("Pointshop", "ulx viewpoints", ulx.viewpoints, "!viewpoints", true)
    viewpoints:addParam({ type = ULib.cmds.PlayersArg })
    viewpoints:defaultAccess(ULib.ACCESS_ALL)
    viewpoints:help("查看玩家积分")
    function ulx.givepoints(calling_ply, target_plys, points)
        for _, v in ipairs(target_plys) do
            if (IsValid(v) and not v:IsBot()) then
                v:PS_GivePoints(tonumber(points) or 0)
                v:ChatPrint(calling_ply:Nick() .. " has given you " .. (tostring(points) or 0) .. " points!")
            end
        end
        ulx.fancyLogAdmin(calling_ply, "#A 给 #i 点数给 #T", points, target_plys)
    end

    local givepoints = ulx.command("Pointshop", "ulx givepoints", ulx.givepoints, "!givepoints", true)
    givepoints:addParam({ type = ULib.cmds.PlayersArg })
    givepoints:addParam({ type = ULib.cmds.NumArg, min = 5, max = 99999999, hint = "点数", ULib.cmds.round })
    givepoints:help("给玩家点商店点数.")
    givepoints:defaultAccess(ULib.ACCESS_SUPERADMIN)
end

timer.Simple(3, function(MadeByZero)
    if (istable(PS)) then
        print("[ULX]: 点数商店1已安装!添加点商店模块!")
        injectPointshopModule()
    end
end)

function ulx.speed(calling_ply, target_plys, W, R)
    W = tonumber(W)
    R = tonumber(R)
    for k, v in ipairs(target_plys) do
        if (W == 0 and R == 0) then
            GAMEMODE:SetPlayerSpeed(v, v.pWalk, v.pRun)
            ulx.fancyLogAdmin(calling_ply, "#A 重置 #T 的步行和跑步速度", target_plys)
        else
            GAMEMODE:SetPlayerSpeed(v, W, R)
            ulx.fancyLogAdmin(calling_ply, "#A 将 #T 的速度设置为 #s 和 #i", target_plys, W, R)
        end
    end
end

local speed = ulx.command(CATEGORY_NAME, "ulx speed", ulx.speed, "!speed")
speed:addParam { type = ULib.cmds.PlayersArg }
speed:addParam { type = ULib.cmds.NumArg, default = 0, hint = "数字步行速度", min = 0, max = 20000 }
speed:addParam { type = ULib.cmds.NumArg, default = 0, hint = "数运行速度", min = 0, max = 20000 }
speed:defaultAccess(ULib.ACCESS_SUPERADMIN)
speed:help("设置目标的速度.\n将两个值都设置为 0 以重置.")

function ulx.scale(calling_ply, target_plys, scale)
    if (scale > 65535) then scale = 65535 end
    for k, v in pairs(target_plys) do
        if v:IsValid() then
            v:SetModelScale(scale, 1)
        end
    end
    ulx.fancyLogAdmin(calling_ply, "#A 将 #T 的比例设置为 #i", target_plys, scale)
end

local scale = ulx.command(CATEGORY_NAME, "ulx scale", ulx.scale, "!scale")
scale:addParam { type = ULib.cmds.PlayersArg }
scale:addParam { type = ULib.cmds.NumArg, min = 0, default = 1, hint = "乘数（默认为1）" }
scale:defaultAccess(ULib.ACCESS_ADMIN)
scale:help("设置玩家的模型比例.")

if SERVER then
    util.AddNetworkString("ulxcc_blur")
    util.AddNetworkString("SendViewModelCalc")

    net.Receive("ulxcc_blur", function()
        local n = 10
        local t = 0.1
        local k = 1.1
        for i = 1, n do
            t = t + 0.2
            k = k - 0.1
            timer.Simple(t, function()
                hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                    DrawMotionBlur(0.1, k, 0.05)
                end)
            end)
            timer.Simple(2.5, function()
                hook.Remove("RenderScreenspaceEffects", "DrawMotionBlur")
            end)
        end
    end)
    net.Receive("SendViewModelCalc", function()
        local pScale = net.ReadInt(16)
        local normal = net.ReadBool()
        if (normal) then
            hook.Remove("CalcView", "ScaleCalcView")
        else
            hook.Add("CalcView", "ScaleCalcView", function(ply, pos, angles, fov)
                local view = {
                    origin = pos + Vector(0, 0, pScale * 55),
                    angles = angles,
                    fov = fov,
                    drawviewer = false
                }
                return view
            end)
        end
    end)
end

local zaptable = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav"
}

function ulx.shock(calling_ply, target_plys, damage)
    for k, v in ipairs(target_plys) do
        if not IsValid(v) then return end
        local eData = EffectData()
        eData:SetEntity(v)
        eData:SetOrigin(v:GetPos())
        eData:SetStart(v:GetPos())
        eData:SetScale(1)
        eData:SetMagnitude(15)
        util.Effect("TeslaHitBoxes", eData)
        v:EmitSound(tostring(table.Random(zaptable)))
        local dmginfo = DamageInfo()
        dmginfo:SetDamage(damage)
        dmginfo:SetAttacker(calling_ply) -- Set the attacker to avoid NULL entity error
        v:TakeDamageInfo(dmginfo)
        if SERVER then
            util.AddNetworkString("ulx_blinds")
            net.Start("ulx_blinds")
            net.WriteBool(true)
            net.WriteInt(255, 16)
            net.Send(v)
            timer.Simple(0.2, function()
                for i = -255, 0 do
                    net.Start("ulx_blinds")
                    if i > 0 then
                        net.WriteBool(true)
                        net.WriteInt(math.abs(i), 16)
                    else
                        net.WriteBool(false)
                        net.WriteInt(0, 16)
                    end

                    net.Send(v)
                end
            end)

            net.Start("ulxcc_blur")
            net.Send(v)
        end
    end

    if damage and damage > 0 then
        ulx.fancyLogAdmin(calling_ply, "#A 电击 #T 给予 #i 伤害", target_plys, damage)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 电击 #T", target_plys)
    end
end

local shock = ulx.command(CATEGORY_NAME, "ulx shock", ulx.shock, "!shock")
shock:addParam { type = ULib.cmds.PlayersArg }
shock:addParam { type = ULib.cmds.NumArg, min = 0, hint = "伤害", ULib.cmds.optional }
shock:defaultAccess(ULib.ACCESS_ADMIN)
shock:help("电击玩家.")

--[[if (CLIENT) then
    usermessage.Hook("StartBlur", function()
        hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
            DrawMotionBlur(0.1, 1, 0.05)
        end)
        timer.Simple(0.3, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.9, 0.05)
            end)
        end)
        timer.Simple(0.5, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.8, 0.05)
            end)
        end)
        timer.Simple(0.7, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.7, 0.05)
            end)
        end)
        timer.Simple(0.9, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.6, 0.05)
            end)
        end)
        timer.Simple(1.1, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.5, 0.05)
            end)
        end)
        timer.Simple(1.3, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.4, 0.05)
            end)
        end)
        timer.Simple(1.5, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.3, 0.05)
            end)
        end)
        timer.Simple(1.7, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.2, 0.05)
            end)
        end)
        timer.Simple(1.9, function()
            hook.Add("RenderScreenspaceEffects", "DrawMotionBlur", function()
                DrawMotionBlur(0.1, 0.1, 0.05)
            end)
        end)
        timer.Simple(2.1, function()
            hook.Remove("RenderScreenspaceEffects", "DrawMotionBlur")
        end)
    end)
end--]]

function ulx.gravity(calling_ply, target_plys, gravnumber)
    for k, v in pairs(target_plys) do
        if tonumber(gravnumber) == 0 then
            v:SetGravity(0.000000000000000000000001) -- because float is dumb
        elseif tonumber(gravnumber) > 0 then
            v:SetGravity(gravnumber)
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A 将 #T 的重力设置为 #s", target_plys, gravnumber)
end

local gravity = ulx.command(CATEGORY_NAME, "ulx gravity", ulx.gravity, "!gravity")
gravity:addParam { type = ULib.cmds.PlayersArg }
gravity:addParam { type = ULib.cmds.StringArg, hint = "重力" }
gravity:defaultAccess(ULib.ACCESS_SUPERADMIN)
gravity:help("设置目标的重力.")

function ulx.launch(calling_ply, target_plys)
    for k, v in ipairs(target_plys) do
        v:SetVelocity(Vector(0, 0, 50) * 50)
    end
    ulx.fancyLogAdmin(calling_ply, "#A 推出 #T", target_plys)
end

local launch = ulx.command(CATEGORY_NAME, "ulx launch", ulx.launch, "!launch")
launch:addParam { type = ULib.cmds.PlayersArg }
launch:defaultAccess(ULib.ACCESS_ADMIN)
launch:help("是否有可能在没有火箭的情\n况下将某人送上月球.")
