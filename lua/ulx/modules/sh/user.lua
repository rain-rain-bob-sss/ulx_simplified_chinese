local CATEGORY_NAME = "用户管理器"

local function checkForValidId(calling_ply, id)
    if id == "BOT" or id == "NULL" then -- Bot check
        return true
    elseif id:find("%.") then           -- Assume IP and check
        if not ULib.isValidIP(id) then
            ULib.tsayError(calling_ply, "无效的 IP.", true)
            return false
        end
    elseif id:find(":") then
        if not ULib.isValidSteamID(id) then -- Assume steamid and check
            ULib.tsayError(calling_ply, "无效的 steamid.", true)
            return false
        end
    elseif not tonumber(id) then -- Assume uniqueid and check
        ULib.tsayError(calling_ply, "无效的唯一 ID", true)
        return false
    end

    return true
end

ulx.group_names = {}
ulx.group_names_no_user = {}
local function updateNames()
    table.Empty(ulx.group_names) -- Don't reassign so we don't lose our refs
    table.Empty(ulx.group_names_no_user)

    for group_name, _ in pairs(ULib.ucl.groups) do
        table.insert(ulx.group_names, group_name)
        if group_name ~= ULib.ACCESS_ALL then
            table.insert(ulx.group_names_no_user, group_name)
        end
    end
end
hook.Add(ULib.HOOK_UCLCHANGED, "ULXGroupNamesUpdate", updateNames)
updateNames() -- Init

function ulx.usermanagementhelp(calling_ply)
    if calling_ply:IsValid() then
        ULib.clientRPC(calling_ply, "ulx.showUserHelp")
    else
        ulx.showUserHelp()
    end
end

local usermanagementhelp = ulx.command(CATEGORY_NAME, "ulx usermanagementhelp", ulx.usermanagementhelp)
usermanagementhelp:defaultAccess(ULib.ACCESS_ALL)
usermanagementhelp:help("查看用户管理帮助.")

function ulx.adduser(calling_ply, target_ply, group_name)
    local userInfo = ULib.ucl.authed[target_ply:UniqueID()]

    local id = ULib.ucl.getUserRegisteredID(target_ply)
    if not id then id = target_ply:SteamID() end

    ULib.ucl.addUser(id, userInfo.allow, userInfo.deny, group_name)

    ulx.fancyLogAdmin(calling_ply, "#A 将 #T 添加到权限组 #s", target_ply, group_name)
end

local adduser = ulx.command(CATEGORY_NAME, "ulx adduser", ulx.adduser, nil, false, false, true)
adduser:addParam { type = ULib.cmds.PlayerArg }
adduser:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names_no_user, hint = "权限组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
adduser:defaultAccess(ULib.ACCESS_SUPERADMIN)
adduser:help("添加用户到指定权限组.")

function ulx.adduserid(calling_ply, id, group_name)
    id = id:upper() -- Steam id needs to be upper

    -- Check for valid and properly formatted ID
    if not checkForValidId(calling_ply, id) then return false end

    -- Now add the fool!
    local userInfo = ULib.ucl.users[id] or ULib.DEFAULT_GRANT_ACCESS
    ULib.ucl.addUser(id, userInfo.allow, userInfo.deny, group_name)

    if ULib.ucl.users[id] and ULib.ucl.users[id].name then
        ulx.fancyLogAdmin(calling_ply, "#A 将 #s 添加到权限组 #s", ULib.ucl.users[id].name, group_name)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 将ID为 #s 的玩家添加到权限组 #s", id, group_name)
    end
end

local adduserid = ulx.command(CATEGORY_NAME, "ulx adduserid", ulx.adduserid, nil, false, false, true)
adduserid:addParam { type = ULib.cmds.StringArg, hint = "SteamID, IP, 或唯一ID" }
adduserid:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names_no_user, hint = "权限组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
adduserid:defaultAccess(ULib.ACCESS_SUPERADMIN)
adduserid:help("通过ID将玩家添加到\n特定权限组.")

function ulx.removeuser(calling_ply, target_ply)
    ULib.ucl.removeUser(target_ply:UniqueID())

    ulx.fancyLogAdmin(calling_ply, "#A 移除了 #T 的所有权限", target_ply)
end

local removeuser = ulx.command(CATEGORY_NAME, "ulx removeuser", ulx.removeuser, nil, false, false, true)
removeuser:addParam { type = ULib.cmds.PlayerArg }
removeuser:defaultAccess(ULib.ACCESS_SUPERADMIN)
removeuser:help("永久移除一个玩家的权限.")

function ulx.removeuserid(calling_ply, id)
    id = id:upper() -- Steam id needs to be upper

    -- Check for valid and properly formatted ID
    if not checkForValidId(calling_ply, id) then return false end

    if not ULib.ucl.authed[id] and not ULib.ucl.users[id] then
        ULib.tsayError(calling_ply, "指定的玩家 \"" .. id .. "\" 不存在于ULib用户列表", true)
        return false
    end

    local name = (ULib.ucl.authed[id] and ULib.ucl.authed[id].name) or
        (ULib.ucl.users[id] and ULib.ucl.users[id].name)

    ULib.ucl.removeUser(id)

    if name then
        ulx.fancyLogAdmin(calling_ply, "#A 移除了 #s 的所有权限", name)
    else
        ulx.fancyLogAdmin(calling_ply, "#A 移除了ID为 #s 的所有权限", id)
    end
end

local removeuserid = ulx.command(CATEGORY_NAME, "ulx removeuserid", ulx.removeuserid, nil, false, false, true)
removeuserid:addParam { type = ULib.cmds.StringArg, hint = "SteamID, IP, 或唯一ID" }
removeuserid:defaultAccess(ULib.ACCESS_SUPERADMIN)
removeuserid:help("通过ID永久移除一个玩家\n的权限.")

function ulx.userallow(calling_ply, target_ply, access_string, access_tag)
    if access_tag then access_tag = access_tag end

    local accessTable
    if access_tag and access_tag ~= "" then
        accessTable = { [access_string] = access_tag }
    else
        accessTable = { access_string }
    end

    local id = ULib.ucl.getUserRegisteredID(target_ply)
    if not id then id = target_ply:SteamID() end

    local success = ULib.ucl.userAllow(id, accessTable)
    if not success then
        ULib.tsayError(calling_ply, string.format("玩家 \"%s\" 已经拥有权限 \"%s\"", target_ply:Nick(),
            access_string), true)
    else
        if not access_tag or access_tag == "" then
            ulx.fancyLogAdmin(calling_ply, "#A 给予权限 #q 到玩家 #T", access_string, target_ply)
        else
            ulx.fancyLogAdmin(calling_ply, "#A 给予权限 #q 伴随标签 #q 到玩家 #T", access_string, access_tag,
                target_ply)
        end
    end
end

local userallow = ulx.command(CATEGORY_NAME, "ulx userallow", ulx.userallow, nil, false, false, true)
userallow:addParam { type = ULib.cmds.PlayerArg }
userallow:addParam { type = ULib.cmds.StringArg, hint = "指令" } -- TODO, add completes for this
userallow:addParam { type = ULib.cmds.StringArg, hint = "标签", ULib.cmds.optional }
userallow:defaultAccess(ULib.ACCESS_SUPERADMIN)
userallow:help("给予玩家某个权限.")

function ulx.userallowid(calling_ply, id, access_string, access_tag)
    if access_tag then access_tag = access_tag end
    id = id:upper() -- Steam id needs to be upper

    -- Check for valid and properly formatted ID
    if not checkForValidId(calling_ply, id) then return false end

    if not ULib.ucl.authed[id] and not ULib.ucl.users[id] then
        ULib.tsayError(calling_ply, "指定的玩家 \"" .. id .. "\" 不存在于ULib用户列表", true)
        return false
    end

    local accessTable
    if access_tag and access_tag ~= "" then
        accessTable = { [access_string] = access_tag }
    else
        accessTable = { access_string }
    end

    local success = ULib.ucl.userAllow(id, accessTable)
    local name = (ULib.ucl.authed[id] and ULib.ucl.authed[id].name) or
        (ULib.ucl.users[id] and ULib.ucl.users[id].name) or id
    if not success then
        ULib.tsayError(calling_ply, string.format("玩家 \"%s\" 已经拥有权限 \"%s\"", name, access_string), true)
    else
        if not access_tag or access_tag == "" then
            ulx.fancyLogAdmin(calling_ply, "#A 给予权限 #q 到玩家 #s", access_string, name)
        else
            ulx.fancyLogAdmin(calling_ply, "#A 给予权限 #q 伴随标签 #q 到玩家 #s", access_string, access_tag,
                name)
        end
    end
end

local userallowid = ulx.command(CATEGORY_NAME, "ulx userallowid", ulx.userallowid, nil, false, false, true)
userallowid:addParam { type = ULib.cmds.StringArg, hint = "SteamID, IP, 或唯一ID" }
userallowid:addParam { type = ULib.cmds.StringArg, hint = "指令" } -- TODO, add completes for this
userallowid:addParam { type = ULib.cmds.StringArg, hint = "标签", ULib.cmds.optional }
userallowid:defaultAccess(ULib.ACCESS_SUPERADMIN)
userallowid:help("通过ID给予玩家某个权限.")

function ulx.userdeny(calling_ply, target_ply, access_string, should_use_neutral)
    local success = ULib.ucl.userAllow(target_ply:UniqueID(), access_string, should_use_neutral, true)
    if should_use_neutral then
        success = success or
            ULib.ucl.userAllow(target_ply:UniqueID(), access_string, should_use_neutral, false) -- Remove from both lists
    end

    if should_use_neutral then
        if success then
            ulx.fancyLogAdmin(calling_ply, "#A made access #q neutral to #T", access_string, target_ply)
        else
            ULib.tsayError(calling_ply,
                string.format("User \"%s\" isn't denied or allowed access to \"%s\"", target_ply:Nick(), access_string),
                true)
        end
    else
        if not success then
            ULib.tsayError(calling_ply,
                string.format("User \"%s\" is already denied access to \"%s\"", target_ply:Nick(), access_string), true)
        else
            ulx.fancyLogAdmin(calling_ply, "#A denied access #q to #T", access_string, target_ply)
        end
    end
end

local userdeny = ulx.command(CATEGORY_NAME, "ulx userdeny", ulx.userdeny, nil, false, false, true)
userdeny:addParam { type = ULib.cmds.PlayerArg }
userdeny:addParam { type = ULib.cmds.StringArg, hint = "command" } -- TODO, add completes for this
userdeny:addParam { type = ULib.cmds.BoolArg, hint = "remove explicit allow or deny instead of outright denying", ULib
    .cmds.optional }
userdeny:defaultAccess(ULib.ACCESS_SUPERADMIN)
userdeny:help("Remove from a user's access.")

function ulx.addgroup(calling_ply, group_name, inherit_from)
    if ULib.ucl.groups[group_name] ~= nil then
        ULib.tsayError(calling_ply, "此权限组已存在!", true)
        return
    end

    if not ULib.ucl.groups[inherit_from] then
        ULib.tsayError(calling_ply, "你所指定的继承权限组不存在!", true)
        return
    end

    ULib.ucl.addGroup(group_name, _, inherit_from)
    ulx.fancyLogAdmin(calling_ply, "#A 创建了权限组 #s 并继承权限组 #s 的权限", group_name, inherit_from)
end

local addgroup = ulx.command(CATEGORY_NAME, "ulx addgroup", ulx.addgroup, nil, false, false, true)
addgroup:addParam { type = ULib.cmds.StringArg, hint = "group" }
addgroup:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names, hint = "继承于", error =
"指定的用户组 \"%s\" 无效", ULib.cmds.restrictToCompletes, default = "user", ULib.cmds.optional }
addgroup:defaultAccess(ULib.ACCESS_SUPERADMIN)
addgroup:help("创建新权限组并指定继承于谁.")

function ulx.renamegroup(calling_ply, current_group, new_group)
    if ULib.ucl.groups[new_group] then
        ULib.tsayError(calling_ply, "目标用户组已存在!", true)
        return
    end

    ULib.ucl.renameGroup(current_group, new_group)
    ulx.fancyLogAdmin(calling_ply, "#A 重命名权限组 #s 到 #s", current_group, new_group)
end

local renamegroup = ulx.command(CATEGORY_NAME, "ulx renamegroup", ulx.renamegroup, nil, false, false, true)
renamegroup:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names_no_user, hint = "当前组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
renamegroup:addParam { type = ULib.cmds.StringArg, hint = "新权限组名" }
renamegroup:defaultAccess(ULib.ACCESS_SUPERADMIN)
renamegroup:help("重命名一个权限组.")

function ulx.setGroupCanTarget(calling_ply, group, can_target)
    if can_target and can_target ~= "" and can_target ~= "*" then
        ULib.ucl.setGroupCanTarget(group, can_target)
        ulx.fancyLogAdmin(calling_ply, "#A 使权限组 #s 只能针对权限组 #s 使用权限", group, can_target)
    else
        ULib.ucl.setGroupCanTarget(group, nil)
        ulx.fancyLogAdmin(calling_ply, "#A 使权限组 #s 能够针对所有人使用权限", group)
    end
end

local setgroupcantarget = ulx.command(CATEGORY_NAME, "ulx setgroupcantarget", ulx.setGroupCanTarget, nil, false, false,
    true)
setgroupcantarget:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names, hint = "权限组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
setgroupcantarget:addParam { type = ULib.cmds.StringArg, hint = "目标权限组名称", ULib.cmds.optional }
setgroupcantarget:defaultAccess(ULib.ACCESS_SUPERADMIN)
setgroupcantarget:help("设置权限组能够针对\n谁使用权限")

function ulx.removegroup(calling_ply, group_name)
    ULib.ucl.removeGroup(group_name)
    ulx.fancyLogAdmin(calling_ply, "#A 移除了权限组 #s", group_name)
end

local removegroup = ulx.command(CATEGORY_NAME, "ulx removegroup", ulx.removegroup, nil, false, false, true)
removegroup:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names_no_user, hint = "权限组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
removegroup:defaultAccess(ULib.ACCESS_SUPERADMIN)
removegroup:help("移除权限组. 请小心使用.")

function ulx.groupallow(calling_ply, group_name, access_string, access_tag)
    access_tag = access_tag

    local accessTable
    if access_tag and access_tag ~= "" then
        accessTable = { [access_string] = access_tag }
    else
        accessTable = { access_string }
    end

    local success = ULib.ucl.groupAllow(group_name, accessTable)
    if not success then
        ULib.tsayError(calling_ply, string.format("权限组 \"%s\" 已经拥有权限 \"%s\"", group_name, access_string),
            true)
    else
        if not access_tag or access_tag == "" then
            ulx.fancyLogAdmin(calling_ply, "#A 给予权限 #q 到权限组 #s", access_string, group_name)
        else
            ulx.fancyLogAdmin(calling_ply, "#A 给予权限 #q 伴随标签 #q 到权限组 #s", access_string,
                access_tag, group_name)
        end
    end
end

local groupallow = ulx.command(CATEGORY_NAME, "ulx groupallow", ulx.groupallow, nil, false, false, true)
groupallow:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names, hint = "权限组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
groupallow:addParam { type = ULib.cmds.StringArg, hint = "指令" } -- TODO, add completes for this
groupallow:addParam { type = ULib.cmds.StringArg, hint = "标签", ULib.cmds.optional }
groupallow:defaultAccess(ULib.ACCESS_SUPERADMIN)
groupallow:help("给予权限组权限.")

function ulx.groupdeny(calling_ply, group_name, access_string)
    local accessTable
    if access_tag and access_tag ~= "" then
        accessTable = { [access_string] = access_tag }
    else
        accessTable = { access_string }
    end

    local success = ULib.ucl.groupAllow(group_name, access_string, true)
    if success then
        ulx.fancyLogAdmin(calling_ply, "#A 移除了权限 #q 从权限组 #s", access_string, group_name)
    else
        ULib.tsayError(calling_ply, string.format("权限组 \"%s\" 已经无权访问 \"%s\"", group_name, access_string),
            true)
    end
end

local groupdeny = ulx.command(CATEGORY_NAME, "ulx groupdeny", ulx.groupdeny, nil, false, false, true)
groupdeny:addParam { type = ULib.cmds.StringArg, completes = ulx.group_names, hint = "权限组", error =
"指定的权限组 \"%s\" 无效", ULib.cmds.restrictToCompletes }
groupdeny:addParam { type = ULib.cmds.StringArg, hint = "指令" } -- TODO, add completes for this
groupdeny:defaultAccess(ULib.ACCESS_SUPERADMIN)
groupdeny:help("移除权限组的权限.")
