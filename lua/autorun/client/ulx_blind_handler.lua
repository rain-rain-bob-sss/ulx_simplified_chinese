local function handle_ulx_blind(um)
    local blind = um:ReadBool()
    local alpha = um:ReadShort()

    -- 在这里根据接收到的 blind 和 alpha 值处理屏幕变暗效果
    -- 您可能需要编写一个屏幕暗淡效果的函数，并在这里调用它
end

usermessage.Hook("ulx_blind", handle_ulx_blind)
