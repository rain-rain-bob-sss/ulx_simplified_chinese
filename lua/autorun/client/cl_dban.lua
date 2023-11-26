local SetClipboardText = SetClipboardText -- #420LocalizeIt
local disconnectTable = disconnectTable or {}

local function OpenPanel(player, cmd, args, str)
    if IsValid(DcMain) then
        DcMain:Remove()
    end

    local ply = LocalPlayer()

    if (not ULib.ucl.query(ply, "ulx dban")) then
        ULib.tsayError(ply, "您无法使用该命令, " .. ply:Nick() .. "!")
        return
    end

    net.Start("DisconnectsRequestTable")
    net.SendToServer()

    DcMain = vgui.Create("DFrame")
    DcMain:SetPos(50, 50)
    DcMain:SetSize(500, 400)
    DcMain:SetTitle("近期断开连接的玩家")
    DcMain:SetVisible(true)
    DcMain:SetDraggable(true)
    DcMain:ShowCloseButton(false)
    DcMain:ShowCloseButton(true)
    DcMain:MakePopup()
    DcMain:Center()
    DcMain.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(78, 78, 78))
    end

    local list = vgui.Create("DListView", DcMain)
    list:SetPos(4, 27)
    list:SetSize(492, 369)
    list:SetMultiSelect(false)
    list:AddColumn("名字")
    list:AddColumn("SteamID")
    list:AddColumn("IP地址")
    list:AddColumn("断线时间")

    list.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(38, 38, 38, 125))
    end

    list.OnRowRightClick = function(main, line)
        local menu = DermaMenu()
        menu:AddOption("通过SteamID封禁", function()
            local Frame = vgui.Create("DFrame")
            Frame:SetSize(250, 98)
            Frame:Center()
            Frame:MakePopup()
            Frame:SetTitle("通过SteamID封禁...")

            local TimeLabel = vgui.Create("DLabel", Frame)
            TimeLabel:SetPos(5, 27)
            TimeLabel:SetColor(Color(0, 0, 0, 255))
            TimeLabel:SetFont("DermaDefault")
            TimeLabel:SetText("时长:")

            local Time = vgui.Create("DTextEntry", Frame)
            Time:SetPos(47, 27)
            Time:SetSize(198, 20)
            Time:SetText("")

            local ReasonLabel = vgui.Create("DLabel", Frame)
            ReasonLabel:SetPos(5, 50)
            ReasonLabel:SetColor(Color(0, 0, 0, 255))
            ReasonLabel:SetFont("DermaDefault")
            ReasonLabel:SetText("原因:")

            local Reason = vgui.Create("DTextEntry", Frame)
            Reason:SetPos(47, 50)
            Reason:SetSize(198, 20)
            Reason:SetText("")

            local execbutton = vgui.Create("DButton", Frame)
            execbutton:SetSize(75, 20)
            execbutton:SetPos(47, 73)
            execbutton:SetText("封禁死它!")
            execbutton.DoClick = function()
                RunConsoleCommand("ulx", "banid", tostring(list:GetLine(line):GetValue(2)), Time:GetText(),
                    Reason:GetText())
                Frame:Close()
            end

            local cancelbutton = vgui.Create("DButton", Frame)
            cancelbutton:SetSize(75, 20)
            cancelbutton:SetPos(127, 73)
            cancelbutton:SetText("取消")
            cancelbutton.DoClick = function(CButton)
                Frame:Close()
            end
        end):SetIcon("icon16/tag_blue_delete.png")

        menu:AddOption("通过IP地址封禁", function()
            local Frame = vgui.Create("DFrame")
            Frame:SetSize(250, 98)
            Frame:Center()
            Frame:MakePopup()
            Frame:SetTitle("通过IP地址封禁...")

            local TimeLabel = vgui.Create("DLabel", Frame)
            TimeLabel:SetPos(5, 27)
            TimeLabel:SetColor(Color(0, 0, 0, 255))
            TimeLabel:SetFont("DermaDefault")
            TimeLabel:SetText("时长:")

            local Time = vgui.Create("DTextEntry", Frame)
            Time:SetPos(47, 27)
            Time:SetSize(198, 20)
            Time:SetText("")

            local ReasonLabel = vgui.Create("DLabel", Frame)
            ReasonLabel:SetPos(5, 50)
            ReasonLabel:SetColor(Color(0, 0, 0, 255))
            ReasonLabel:SetFont("DermaDefault")
            ReasonLabel:SetText("原因:")

            local Reason = vgui.Create("DTextEntry", Frame)
            Reason:SetPos(47, 50)
            Reason:SetSize(198, 20)
            Reason:SetText("无需理由")
            Reason:SetDisabled(true)

            local execbutton = vgui.Create("DButton", Frame)
            execbutton:SetSize(75, 20)
            execbutton:SetPos(47, 73)
            execbutton:SetText("封禁!")
            execbutton.DoClick = function()
                RunConsoleCommand("ulx", "banip", Time:GetText(), list:GetLine(line):GetValue(3))
                Frame:Close()
            end

            local cancelbutton = vgui.Create("DButton", Frame)
            cancelbutton:SetSize(75, 20)
            cancelbutton:SetPos(127, 73)
            cancelbutton:SetText("取消")
            cancelbutton.DoClick = function(CButton)
                Frame:Close()
            end
        end):SetIcon("icon16/vcard_delete.png")

        menu:AddOption("复制名字", function()
            SetClipboardText(tostring(list:GetLine(line):GetValue(1)))
        end):SetIcon("icon16/user_edit.png")

        menu:AddOption("复制SteamID", function()
            SetClipboardText(tostring(list:GetLine(line):GetValue(2)))
        end):SetIcon("icon16/tag_blue_edit.png")

        if ply:IsAdmin() then
            menu:AddOption("复制IP地址", function()
                SetClipboardText(tostring(list:GetLine(line):GetValue(3)))
            end):SetIcon("icon16/vcard_edit.png")
        end

        menu:AddOption("复制断开时间", function()
            SetClipboardText(tostring(list:GetLine(line):GetValue(4)))
        end):SetIcon("icon16/time.png")

        menu:AddOption("查看个人资料", function()
            gui.OpenURL("http://steamcommunity.com/profiles/" ..
                util.SteamIDTo64(tostring(list:GetLine(line):GetValue(2))))
        end):SetIcon("icon16/world.png")

        if ply:IsAdmin() then
            menu:AddOption("Whois", function()
                gui.OpenURL("http://whois.net/ip-address-lookup/" .. tostring(list:GetLine(line):GetValue(3)))
            end):SetIcon("icon16/zoom.png")
        end

        menu:Open()
    end

    net.Receive("DisconnectsTransferTable", function()
        disconnectTable = net.ReadTable()
        if (IsValid(DcMain)) then
            for i = 1, #disconnectTable do
                list:AddLine(disconnectTable[i][2], disconnectTable[i][1], disconnectTable[i][3], disconnectTable[i][4])
            end
        end
    end)
end

concommand.Add("menu_disconnects", OpenPanel)
