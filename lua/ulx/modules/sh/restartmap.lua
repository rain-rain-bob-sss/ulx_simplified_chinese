local CATEGORY_NAME = "功能"

function ulx.mapreload(calling_ply, delay)
    local delay = delay or 10

    if delay == 0 then
        game.ConsoleCommand('changelevel "' .. game.GetMap() .. '"\n')
    elseif delay > 0 then
        timer.Create("map_reload", delay, 1,function() game.ConsoleCommand('changelevel "' .. game.GetMap() .. '"\n') end)
        ulx.fancyLogAdmin(calling_ply, "#A 计划了地图重新加载，将在 #i 秒后执行!", delay)
        net.Start("map_reload")
        net.WriteFloat(delay)
        net.Broadcast()
    else
        timer.Remove("map_reload")
        ulx.fancyLogAdmin(calling_ply, "#A 取消了地图重新加载计划!")
        net.Start("map_reload")
        net.WriteFloat(-1)
        net.Broadcast()
    end
end

local mapreload = ulx.command(CATEGORY_NAME, "ulx mapreload", ulx.mapreload, "!mapreload")
mapreload:addParam { type = ULib.cmds.NumArg, hint = "延迟(秒)", default = 10, ULib.cmds.optional, ULib.cmds.round }
mapreload:defaultAccess(ULib.ACCESS_SUPERADMIN)
mapreload:help("重启地图，可选择延迟时间。将延迟设为 -1 可取消延迟。")
