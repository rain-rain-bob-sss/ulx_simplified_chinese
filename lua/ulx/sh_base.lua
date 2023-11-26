local ulxBuildNumURL = ulx.release and "https://teamulysses.github.io/ulx/ulx.build" or "https://raw.githubusercontent.com/TeamUlysses/ulx/master/ulx.build"
ULib.registerPlugin {
    Name              = "ULX",
    Version           = string.format("%.2f", ulx.version),
    IsRelease         = ulx.release,
    Author            = "Team Ulysses",
    URL               = "http://ulyssesmod.net",
    WorkshopID        = 557962280,
    BuildNumLocal     = tonumber(ULib.fileRead("ulx.build")),
    BuildNumRemoteURL = ulxBuildNumURL,
    --BuildNumRemoteReceivedCallback = nil
}

function ulx.getVersion() -- This function will be removed in the future
    return ULib.pluginVersionStr("ULX")
end

local ulxCommand = inheritsFrom(ULib.cmds.TranslateCommand)

function ulxCommand:logString(str)
    Msg("警告: <ulx command>:logString() 被调用, 该方法即将过时!\n")
end

function ulxCommand:oppositeLogString(str)
    Msg("警告: <ulx command>:oppositeLogString() 被调用, 该方法即将过时!\n")
end

function ulxCommand:help(str)
    self.helpStr = str
end

function ulxCommand:getUsage(ply)
    local str = self:superClass().getUsage(self, ply)

    if self.helpStr or self.say_cmd or self.opposite then
        str = str:Trim() .. " - "
        if self.helpStr then
            str = str .. self.helpStr
        end
        if self.helpStr and self.say_cmd then
            str = str .. " "
        end
        if self.say_cmd then
            str = str .. "(say: " .. self.say_cmd[1] .. ")"
        end
        if self.opposite and (self.helpStr or self.say_cmd) then
            str = str .. " "
        end
        if self.opposite then
            str = str .. "(opposite: " .. self.opposite .. ")"
        end
    end

    return str
end

ulx.cmdsByCategory = ulx.cmdsByCategory or {}
function ulx.command(category, command, fn, say_cmd, hide_say, nospace, unsafe)
    if type(say_cmd) == "string" then say_cmd = { say_cmd } end
    local obj = ulxCommand(command, fn, say_cmd, hide_say, nospace, unsafe)
    obj:addParam { type = ULib.cmds.CallingPlayerArg }
    ulx.cmdsByCategory[category] = ulx.cmdsByCategory[category] or {}
    for cat, cmds in pairs(ulx.cmdsByCategory) do
        for i = 1, #cmds do
            if cmds[i].cmd == command then
                table.remove(ulx.cmdsByCategory[cat], i)
                break
            end
        end
    end
    table.insert(ulx.cmdsByCategory[category], obj)
    obj.category = category
    obj.say_cmd = say_cmd
    obj.hide_say = hide_say
    return obj
end

local function cc_ulx(ply, command, argv)
    local argn = #argv

    if argn == 0 then
        ULib.console(ply, "未输入任何指令. 如果你需要帮助, 请在控制台输入 \"ulx help\" 以获得帮助.")
    else
        -- TODO, need to make this cvar hack actual commands for sanity and autocomplete
        -- First, check if this is a cvar and they just want the value of the cvar
        local cvar = ulx.cvars[argv[1]:lower()]
        if cvar and not argv[2] then
            ULib.console(ply, "\"ulx " .. argv[1] .. "\" = \"" .. GetConVarString("ulx_" .. cvar.cvar) .. "\"")
            if cvar.help and cvar.help ~= "" then
                ULib.console(ply, cvar.help .. "\n  CVAR 由 ULX 生成")
            else
                ULib.console(ply, "  CVAR 由 ULX 生成")
            end
            return
        elseif cvar then -- Second, check if this is a cvar and they specified a value
            local args = table.concat(argv, " ", 2, argn)
            if ply:IsValid() then
                -- Workaround: gmod seems to choke on '%' when sending commands to players.
                -- But it's only the '%', or we'd use ULib.makePatternSafe instead of this.
                ply:ConCommand("ulx_" .. cvar.cvar .. " \"" .. args:gsub("(%%)", "%%%1") .. "\"")
            else
                cvar.obj:SetString(argv[2])
            end
            return
        end
        ULib.console(ply, "输入的指令无效. 如果你需要帮助, 请在控制台输入 \"ulx help\" 以获得帮助.")
    end
end
ULib.cmds.addCommand("ulx", cc_ulx)

function ulx.help(ply)
    ULib.console(ply, "ULX 帮助:")
    ULib.console(ply, "如果指令能接受多个目标, 通常使用 '*' 代表")
    ULib.console(ply, "选择所有人, '^' 代表对你自己使用, '@' for target your picker, '$<userid>' 代表利用ID来对其使用 (steamid,")
    ULib.console(ply, "唯一ID, userid, ip), '#<group>' 代表对特定权限组的玩家使用, 还有 '%<group>' 代表来针对")
    ULib.console(ply, "有这个用户组权限的玩家 (继承计数). 例如, ulx slap #user 扇所有在默认用户组")
    ULib.console(ply, "的玩家的脸. 这些指令也可以用前缀 '!' 来执行.")
    ULib.console(ply, "例如, ulx slap !^ 扇除了你以外的所有人的脸.")
    ULib.console(ply, "你还可以用逗号来指定多个目标. 例如, ulx slap bob,jeff,henry.")
    ULib.console(ply, "所有插件的指令必须以 \"ulx \" 开头, 例如 \"ulx slap\"")
    ULib.console(ply, "\n所有可用指令的帮助信息:\n")

    for category, cmds in pairs(ulx.cmdsByCategory) do
        local lines = {}
        for _, cmd in ipairs(cmds) do
            local tag = cmd.cmd
            if cmd.manual then tag = cmd.access_tag end
            if ULib.ucl.query(ply, tag) then
                local usage
                if not cmd.manual then
                    usage = cmd:getUsage(ply)
                else
                    usage = cmd.helpStr
                end
                table.insert(lines, string.format("\t指令 %s %s", cmd.cmd, usage:Trim()))
            end
        end

        if #lines > 0 then
            table.sort(lines)
            ULib.console(ply, "\n分类: " .. category)
            for _, line in ipairs(lines) do
                ULib.console(ply, line)
            end
            ULib.console(ply, "") -- New line
        end
    end


    ULib.console(ply, "\n-指令帮助结束\nULX 版本: " .. ULib.pluginVersionStr("ULX") .. "\n")
end

local help = ulx.command("菜单", "ulx help", ulx.help)
help:help("显示ULX插件帮助.")
help:defaultAccess(ULib.ACCESS_ALL)

function ulx.dumpTable(t, indent, done)
    done = done or {}
    indent = indent or 0
    local str = ""

    for k, v in pairs(t) do
        str = str .. string.rep("\t", indent)

        if type(v) == "table" and not done[v] then
            done[v] = true
            str = str .. tostring(k) .. ":" .. "\n"
            str = str .. ulx.dumpTable(v, indent + 1, done)
        else
            str = str .. tostring(k) .. "\t=\t" .. tostring(v) .. "\n"
        end
    end

    return str
end

function ulx.uteamEnabled()
    return ULib.isSandbox() and GAMEMODE.Name ~= "DarkRP"
end
