local CATEGORY_NAME = "功能"

function ulx.giveammo(calling_ply, target_plys, amount, bSetAmmo)
    for i = 1, #target_plys do
        local ply = target_plys[i]
        local wep = ply:GetActiveWeapon()
        local ammo = wep:GetPrimaryAmmoType()
        if (bSetAmmo) then
            ply:SetAmmo(amount, ammo)
        else
            ply:GiveAmmo(amount, ammo)
        end
    end
    if (bSetAmmo) then
        ulx.fancyLogAdmin(calling_ply, "#A 将 #T的弹药设置为 #s", target_plys, amount)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 给了 #T #i 弹药", target_plys, amount)
    end
end

local giveammo = ulx.command(CATEGORY_NAME, "ulx giveammo", ulx.giveammo, "!giveammo")
giveammo:addParam { type = ULib.cmds.PlayersArg }
giveammo:addParam { type = ULib.cmds.NumArg, min = 0, hint = "数量" }
giveammo:addParam { type = ULib.cmds.BoolArg, invisible = true }
giveammo:defaultAccess(ULib.ACCESS_ADMIN)
giveammo:help("设置玩家的弹药")
giveammo:setOpposite("ulx setammo", { _, _, _, true }, "!setammo")

function ulx.giveweapon(calling_ply, target_plys, weapon)
    local affected_plys = {}
    for i = 1, #target_plys do
        local v = target_plys[i]

        if not v:Alive() then
            ULib.tsayError(calling_ply, v:Nick() .. " 死了", true)
        else
            v:Give(weapon)
            table.insert(affected_plys, v)
        end
    end
    ulx.fancyLogAdmin(calling_ply, "#A 给了 #T 一把 #s", affected_plys, weapon)
end

local giveweapon = ulx.command(CATEGORY_NAME, "ulx giveweapon", ulx.giveweapon, "!giveweapon")
giveweapon:addParam { type = ULib.cmds.PlayersArg }
giveweapon:addParam { type = ULib.cmds.StringArg, hint = "weapon_" }
giveweapon:defaultAccess(ULib.ACCESS_SUPERADMIN)
giveweapon:help("给予指定的玩家指定的武器")
