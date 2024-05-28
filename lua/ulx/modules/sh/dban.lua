local CATEGORY_NAME = "功能"

function ulx.disconnects(calling_ply)
    if not calling_ply:IsAdmin() then
        ULib.tsayError(calling_ply, "您必须是管理员才能使用此命令!")
        return
    end

    calling_ply:ConCommand("menu_disconnects")
    ulx.fancyLogAdmin(calling_ply, true, "#A 打开离线名单!")
end

local disconnects = ulx.command(CATEGORY_NAME, "ulx disconnects", ulx.disconnects, "!disconnects")
disconnects:defaultAccess(ULib.ACCESS_ADMIN)
disconnects:help("获取最近断开连接的玩家列表.")
