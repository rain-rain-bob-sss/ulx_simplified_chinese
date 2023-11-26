--此东西无任何权限只是在TTT2显示开发者的标志
if CLIENT then
    -- Use string or string.format("%.f",<steamid64>)
    -- 在记分牌上添加软件开发者的标志
    hook.Add("TTT2FinishedLoading", "TTT2RegistermexikoediAddonDev", function()
        AddTTT2AddonDev("76561199046379906")
        AddTTT2AddonDev("76561198444795757")
    end)
end
