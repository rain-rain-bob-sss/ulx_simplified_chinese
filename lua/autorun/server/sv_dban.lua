if SERVER then
    util.AddNetworkString("DisconnectsRequestTable")
    util.AddNetworkString("DisconnectsTransferTable")
end

DisconnectedPlayers = {}
local mov = 1

hook.Add("PlayerDisconnected", "TrackInformation", function(leaver)
    local sid = tostring(leaver:SteamID())
    local nick = tostring(leaver:Nick())
    local lip = leaver:IPAddress()

    for i = 1, #DisconnectedPlayers do
        if (DisconnectedPlayers[i][1] == sid) then
            return
        end
    end

    DisconnectedPlayers[mov] = {
        tostring(sid),
        tostring(nick),
        tostring(string.sub(tostring(lip), 1, string.len(lip) - 6)),
        tostring(os.date("%H:%M")),
    }

    mov = mov + 1
end)

concommand.Add("print_disconnects", function(ply)
    if (not IsValid(ply) and SERVER) then
        PrintTable(DisconnectedPlayers, 4)
    elseif (IsValid(ply)) then
        ply:ChatPrint("[ERROR]： 这是一条服务器控制台命令.")
    end
end)

net.Receive("DisconnectsRequestTable", function(_, sender)
    if (IsValid(sender) and sender:IsAdmin() and table.Count(DisconnectedPlayers) ~= 0) then
        net.Start("DisconnectsTransferTable")
        net.WriteTable(DisconnectedPlayers)
        net.Send(sender)
    elseif (table.Count(DisconnectedPlayers) == 0) then 
        sender:ChatPrint("[ERROR]: 断开连接表为空, " .. (sender.Nick and tostring(sender:Nick())) .. "!")
    elseif (IsValid(sender)) then
        sender:ChatPrint("[ERROR]: 您无法使用该命令, " .. (sender.Nick and tostring(sender:Nick())) .. "!")
    end
end)
