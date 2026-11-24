local look = require("../lib/look")
local calendar = require("../lib/calendar")

local weekdays = { "日", "一", "二", "三", "四", "五", "六" }

interval = 1

function render(ctx)
    local now = ctx.data.seconds
    local localTime = os.date("!*t", math.floor(now + ctx.format.offset(now)))
    local vertical = ctx.data.bar.style.vertical
    local scale = look.scale(ctx)
    local click = look.clockClick
    local content = {
        gap = if vertical then 0 else 8 * scale,
        pad = if vertical then 2 * scale else nil,
        onClick = click or ui.popout,
        onRightClick = if click then ui.popout else nil,
    }

    if ctx.select("settings", "icon") == true then
        content[#content + 1] = look.glyph{ name = "calendar", size = look.px(ctx, "symbol") }
    end

    if vertical then
        for _, part in { localTime.hour, localTime.min, localTime.sec } do
            content[#content + 1] = look.text{ text = string.format("%02d", part), size = 11 * scale, style = "mono" }
        end
    else
        if ctx.select("settings", "date") ~= false then
            local date = string.format("%d/%d(%s)", localTime.month, localTime.day, weekdays[localTime.wday])
            content[#content + 1] = look.text{ text = date, size = 13 * scale, weight = "regular" }
        end

        local time = string.format("%02d:%02d:%02d", localTime.hour, localTime.min, localTime.sec)
        content[#content + 1] = look.text{ text = time, size = 13 * scale, weight = "regular", reserve = "00:00:00" }
    end
    return look.bar(ctx, content)
end

function popout(ctx)
    return calendar.popout(ctx)
end
