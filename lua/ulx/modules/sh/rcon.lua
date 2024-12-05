-- This module holds any type of remote execution functions (IE, 'dangerous')
local CATEGORY_NAME = "执行"

function ulx.rcon(calling_ply, command)
    ULib.consoleCommand(command .. "\n")

    ulx.fancyLogAdmin(calling_ply, true, "#A 运行了RCON指令: #s", command)
end

local rcon = ulx.command(CATEGORY_NAME, "ulx rcon", ulx.rcon, "!rcon", true, false, true)
rcon:addParam { type = ULib.cmds.StringArg, hint = "command", ULib.cmds.takeRestOfLine }
rcon:defaultAccess(ULib.ACCESS_SUPERADMIN)
rcon:help("从服务器控制台运行指令.")

function ulx.luaRun(calling_ply, command)
    local return_results = false
    if command:sub(1, 1) == "=" then
        command = "tmp_var" .. command
        return_results = true
    end

    local error = RunString(command, "["..calling_ply:Nick().."]", false)
    if error~=nil and isstring(error) then
        local lines = ULib.explode("\n", ulx.dumpTable(error))
        local chunk_size = 50
        for i = 1, #lines, chunk_size do -- Break it up so we don't overflow the client
            ULib.queueFunctionCall(function()
                for j = i, math.min(i + chunk_size - 1, #lines) do
                    ULib.console(calling_ply, lines[j]:gsub("%%", "<p>"))
                end
            end)
        end
    end

    if return_results then
        if type(tmp_var) == "table" then
            ULib.console(calling_ply, "结果:")
            local lines = ULib.explode("\n", ulx.dumpTable(tmp_var))
            local chunk_size = 50
            for i = 1, #lines, chunk_size do -- Break it up so we don't overflow the client
                ULib.queueFunctionCall(function()
                    for j = i, math.min(i + chunk_size - 1, #lines) do
                        ULib.console(calling_ply, lines[j]:gsub("%%", "<p>"))
                    end
                end)
            end
        else
            ULib.console(calling_ply, "结果: " .. tostring(tmp_var):gsub("%%", "<p>"))
        end
    end

    ulx.fancyLogAdmin(calling_ply, true, "#A 运行了lua脚本: #s", command)
end

local luarun = ulx.command(CATEGORY_NAME, "ulx luarun", ulx.luaRun, nil, false, false, true)
luarun:addParam { type = ULib.cmds.StringArg, hint = "command", ULib.cmds.takeRestOfLine }
luarun:defaultAccess(ULib.ACCESS_SUPERADMIN)
luarun:help("在服务器控制台运行lua脚本. (使用 '=' 输出)")

function ulx.exec(calling_ply, config)
    if string.sub(config, -4) ~= ".cfg" then config = config .. ".cfg" end
    if not ULib.fileExists("cfg/" .. config) then
        ULib.tsayError(calling_ply, "cfg文件未找到!", true)
        return
    end

    ULib.execFile("cfg/" .. config)
    ulx.fancyLogAdmin(calling_ply, "#A 执行cfg文件 #s 里的内容", config)
end

local exec = ulx.command(CATEGORY_NAME, "ulx exec", ulx.exec, nil, false, false, true)
exec:addParam { type = ULib.cmds.StringArg, hint = "file" }
exec:defaultAccess(ULib.ACCESS_SUPERADMIN)
exec:help("在服务器cfg目录里运行cfg文\n件.")

function ulx.cexec(calling_ply, target_plys, command)
    for _, v in ipairs(target_plys) do
        v:ConCommand(command)
    end

    ulx.fancyLogAdmin(calling_ply, "#A 运行了指令 #s 于 #T 的控制台", command, target_plys)
end

local cexec = ulx.command(CATEGORY_NAME, "ulx cexec", ulx.cexec, "!cexec", false, false, true)
cexec:addParam { type = ULib.cmds.PlayersArg }
cexec:addParam { type = ULib.cmds.StringArg, hint = "command", ULib.cmds.takeRestOfLine }
cexec:defaultAccess(ULib.ACCESS_SUPERADMIN)
cexec:help("在目标玩家的控制台运行指令.")

function ulx.ent(calling_ply, classname, params)
    if not calling_ply:IsValid() then
        Msg("无法从服务器控制台创建实体.\n")
        return
    end

    classname = classname:lower()
    newEnt = ents.Create(classname)

    -- Make sure it's a valid ent
    if not newEnt or not newEnt:IsValid() then
        ULib.tsayError(calling_ply, "未知实体类型 (" .. classname .. "), 正在取消操作.", true)
        return
    end

    local trace = calling_ply:GetEyeTrace()
    local vector = trace.HitPos
    vector.z = vector.z + 20

    newEnt:SetPos(vector) -- Note that the position can be overridden by the user's flags

    params:gsub("([^|:\"]+)\"?:\"?([^|]+)", function(key, value)
        key = key:Trim()
        value = value:Trim()
        newEnt:SetKeyValue(key, value)
    end)

    newEnt:Spawn()
    newEnt:Activate()

    params:gsub("([^|:\"]+)\"?:\"?([^|]+)", function(key, value)
        key = key:Trim()
        value = value:Trim()
        newEnt:SetKeyValue(key, value)
    end)

    undo.Create("ulx_ent")
    undo.AddEntity(newEnt)
    undo.SetPlayer(calling_ply)
    undo.Finish()

    if not params or params == "" then
        ulx.fancyLogAdmin(calling_ply, "#A 生成实体 #s", classname)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 生成实体 #s 并附带参数 #s", classname, params)
    end
end

local ent = ulx.command(CATEGORY_NAME, "ulx ent", ulx.ent, "!ent", false, false, true)
ent:addParam { type = ULib.cmds.StringArg, hint = "实体名称" }
ent:addParam { type = ULib.cmds.StringArg, hint = "<标签>:<值>|", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
ent:defaultAccess(ULib.ACCESS_SUPERADMIN)
ent:help("生成实体, 使用':'来分开标签与值, \"标签:值\"组用 '|' 分开.")

function ulx.physent(calling_ply, modelpath)
    if not calling_ply:IsValid() then
        Msg("无法从服务器控制台创建实体.\n")
        return
    end

    local shiet = ents.Create("prop_physics")
    local trace = calling_ply:GetEyeTrace()
    local vector = trace.HitPos
    vector.z = vector.z + 20
    shiet:SetPos(vector)
    shiet:SetModel(modelpath)
    shiet:Spawn()
    shiet:Activate()

    undo.Create("ulx_ent")
    undo.AddEntity(shiet)
    undo.SetPlayer(calling_ply)
    undo.Finish()

    ulx.fancyLogAdmin(calling_ply, "#A 生成物理实体 #s", modelpath)
end

local physent = ulx.command(CATEGORY_NAME, "ulx physent", ulx.physent, "!physent", false, false, true)
physent:addParam { type = ULib.cmds.StringArg, hint = "模型路径" }
physent:defaultAccess(ULib.ACCESS_SUPERADMIN)
physent:help("生成物理实体.")
