--Sandbox settings module for ULX GUI -- by Stickly Man!
--Defines sbox cvar limits and sandbox specific settings for the sandbox gamemode.

xgui.prepareDataType("sboxlimits")
local sbox_settings = xlib.makepanel { parent = xgui.null }

local sidepanel = xlib.makescrollpanel { x = 5, y = 5, w = 160, h = 322, spacing = 4, parent = sbox_settings }
xlib.makecheckbox { dock = TOP, dockmargin = { 0, 0, 0, 0 }, label = "启用基础武器", convar = xlib.ifListenHost("sbox_weapons"), repconvar = xlib.ifNotListenHost("rep_sbox_weapons"), parent = sidepanel }
xlib.makecheckbox { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "启用无敌", convar = xlib.ifListenHost("sbox_godmode"), repconvar = xlib.ifNotListenHost("rep_sbox_godmode"), parent = sidepanel }

xlib.makecheckbox { dock = TOP, dockmargin = { 0, 20, 0, 0 }, label = "启用PVP伤害", convar = xlib.ifListenHost("sbox_playershurtplayers"), repconvar = xlib.ifNotListenHost("rep_sbox_playershurtplayers"), parent = sidepanel }
xlib.makecheckbox { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "启用穿墙", convar = xlib.ifListenHost("sbox_noclip"), repconvar = xlib.ifNotListenHost("rep_sbox_noclip"), parent = sidepanel }
xlib.makecheckbox { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "骨骼操纵:NPC", convar = xlib.ifListenHost("sbox_bonemanip_npc"), repconvar = xlib.ifNotListenHost("rep_sbox_bonemanip_npc"), parent = sidepanel }
xlib.makecheckbox { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "骨骼操纵:玩家", convar = xlib.ifListenHost("sbox_bonemanip_player"), repconvar = xlib.ifNotListenHost("rep_sbox_bonemanip_player"), parent = sidepanel }
xlib.makecheckbox { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "骨骼操纵:一切", convar = xlib.ifListenHost("sbox_bonemanip_misc"), repconvar = xlib.ifNotListenHost("rep_sbox_bonemanip_misc"), parent = sidepanel }

xlib.makecheckbox { dock = TOP, dockmargin = { 0, 20, 0, 0 }, label = "物理枪限制", convar = xlib.ifListenHost("physgun_limited"), repconvar = xlib.ifNotListenHost("rep_physgun_limited"), parent = sidepanel }
xlib.makelabel { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "最大光束范围", parent = sidepanel }
xlib.makeslider { dock = TOP, dockmargin = { 0, 2, 5, 0 }, label = "<--->", w = 125, min = 128, max = 8192, convar = xlib.ifListenHost("physgun_maxrange"), repconvar = xlib.ifNotListenHost("rep_physgun_maxrange"), parent = sidepanel, fixclip = true }
xlib.makelabel { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "传送距离", parent = sidepanel }
xlib.makeslider { dock = TOP, dockmargin = { 0, 2, 5, 0 }, label = "<--->", w = 125, min = 0, max = 10000, convar = xlib.ifListenHost("physgun_teleportDistance"), repconvar = xlib.ifNotListenHost("rep_physgun_teleportDistance"), parent = sidepanel, fixclip = true }
xlib.makelabel { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "最大Prop速度", parent = sidepanel }
xlib.makeslider { dock = TOP, dockmargin = { 0, 2, 5, 0 }, label = "<--->", w = 125, min = 0, max = 10000, convar = xlib.ifListenHost("physgun_maxSpeed"), repconvar = xlib.ifNotListenHost("rep_physgun_maxSpeed"), parent = sidepanel, fixclip = true }
xlib.makelabel { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "最大Angular速度", parent = sidepanel }
xlib.makeslider { dock = TOP, dockmargin = { 0, 2, 5, 0 }, label = "<--->", w = 125, min = 0, max = 10000, convar = xlib.ifListenHost("physgun_maxAngular"), repconvar = xlib.ifNotListenHost("rep_physgun_maxAngular"), parent = sidepanel, fixclip = true }
xlib.makelabel { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "到达时间", parent = sidepanel }
xlib.makeslider { dock = TOP, dockmargin = { 0, 2, 5, 0 }, label = "<--->", w = 125, min = 0, max = 2, decimal = 2, convar = xlib.ifListenHost("physgun_timeToArrive"), repconvar = xlib.ifNotListenHost("rep_physgun_timeToArrive"), parent = sidepanel, fixclip = true }
xlib.makelabel { dock = TOP, dockmargin = { 0, 5, 0, 0 }, label = "到达时间(布娃娃)", parent = sidepanel }
xlib.makeslider { dock = TOP, dockmargin = { 0, 2, 5, 0 }, label = "<--->", w = 125, min = 0, max = 2, decimal = 2, convar = xlib.ifListenHost("physgun_timeToArriveRagdoll"), repconvar = xlib.ifNotListenHost("rep_physgun_timeToArriveRagdoll"), parent = sidepanel, fixclip = true }

xlib.makelabel { dock = TOP, dockmargin = { 0, 20, 0, 0 }, w = 138, label = "持久性文件:", parent = sidepanel }
xlib.maketextbox { h = 25, dock = TOP, dockmargin = { 0, 5, 5, 0 }, label = "持久化道具", convar = xlib.ifListenHost("sbox_persist"), repconvar = xlib.ifNotListenHost("rep_sbox_persist"), parent = sidepanel }

xlib.makelabel { dock = TOP, dockmargin = { 0, 20, 0, 0 }, w = 138, wordwrap = true, label = "注意：沙盒设置是为方便起见而提供的，在服务器重启或崩溃后不会保存。", parent = sidepanel }

sbox_settings.plist = xlib.makelistlayout { x = 170, y = 5, h = 322, w = 410, spacing = 1, padding = 2, parent = sbox_settings }

function sbox_settings.processLimits()
    sbox_settings.plist:Clear()
    for g, limits in ipairs(xgui.data.sboxlimits) do
        if #limits > 0 then
            local panel = xlib.makepanel { dockpadding = { 0, 0, 0, 5 } }
            local i = 0
            for _, cvar in ipairs(limits) do
                local cvardata = string.Explode(" ", cvar) --Split the cvarname and max slider value number
                xgui.queueFunctionCall(xlib.makelabel, "sboxlimits", { x = 10 + (i % 2 * 195), y = 5 + math.floor(i / 2) * 40, w = 185, label = "最大数量 " .. cvardata[1]:sub(9), parent = panel })
                xgui.queueFunctionCall(xlib.makeslider, "sboxlimits", { x = 10 + (i % 2 * 195), y = 20 + math.floor(i / 2) * 40, w = 185, label = "<--->", min = 0, max = cvardata[2], convar = xlib.ifListenHost(cvardata[1]), repconvar = xlib.ifNotListenHost("rep_" .. cvardata[1]), parent = panel, fixclip = true })
                i = i + 1
            end
            sbox_settings.plist:Add(xlib.makecat { label = limits.title .. " (" .. #limits .. " 个限制" .. ((#limits > 1) and "s" or "") .. ")", contents = panel, expanded = (g == 1) })
        end
    end
end

sbox_settings.processLimits()

xgui.hookEvent("sboxlimits", "process", sbox_settings.processLimits, "sandboxProcessLimits")
xgui.addSettingModule("沙盒", sbox_settings, "icon16/box.png", "xgui_gmsettings")
