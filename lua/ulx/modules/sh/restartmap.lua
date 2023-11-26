local CATEGORY_NAME = "功能"

function ulx.restartmap(calling_ply)
    ulx.fancyLogAdmin(calling_ply, "#A 重启了地图.")
    game.ConsoleCommand("changelevel " .. string.format(game.GetMap(), ".bsp") .. "\n")
end

local restartmap = ulx.command(CATEGORY_NAME, "ulx restartmap", ulx.restartmap, "!restartmap")
restartmap:defaultAccess(ULib.ACCESS_SUPERADMIN)
restartmap:help("重启地图.")
