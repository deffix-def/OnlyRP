script_author('deffix | Denis_Mansory')
script_description('FOR Nice RolePlay on Mordor RolePlay')
require 'lib.moonloader'
local imgui = require 'mimgui'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
local wm = require 'lib.windows.message'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local inicfgfile = '..//OnlyRP.ini'
local inisettings = inicfg.load(inicfg.load({
    settings = {
        state = false,
        show_rp_chat = true,
        show_smi = false,
        show_sms = false,
        show_gnews = false,
        show_w = true,
        show_s = true,
        show_me = true,
        show_do = true,
        show_todo = true,
        show_ame = true,
        show_r = true,
        show_d = true
    }
}, inicfgfile))

local new = imgui.new
local canMove = 0
-- https://www.blast.hk/threads/13380/post-890308
function imgui.CustomCheckbox(label, bool)
    local result = false
    local drawList = imgui.GetWindowDrawList()
    local draw = imgui.GetCursorScreenPos()
    local lineHeight = imgui.GetTextLineHeight()
    local itemSpacing = imgui.GetStyle().ItemSpacing
    local boxSize = math.floor(lineHeight * 0.95)
    local clearance = boxSize * 0.2
    local corner = draw + imgui.ImVec2(0, itemSpacing.y + math.floor(0.5 * (lineHeight - boxSize)))
    local color = imgui.GetStyle().Colors[imgui.Col.Text]
    local changedColor = imgui.ImVec4(color.x, color.y, color.z, 0.25)
    local colorMark = color
    local name = string.gsub(label, "##.*", "")
    local radius = boxSize * 0.2
    local conv = imgui.ColorConvertFloat4ToU32
    local ImVec2 = imgui.ImVec2

    if not cMarks then cMarks = {} end
    if not cMarks[label] then cMarks[label] = 0 end

    imgui.BeginGroup()
        imgui.InvisibleButton(label, ImVec2(boxSize, boxSize))
        if #name > 0 then
            imgui.SameLine()
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 2.5)
            imgui.PushFont(norm)
            if bool[0] then
                imgui.Text(name)
            else
                imgui.TextDisabled(name)
            end
            if imgui.IsItemHovered() then
                canMove = 1
            end
            imgui.PopFont()
        end
    imgui.EndGroup()
    if imgui.IsItemClicked() then
        bool[0] = not bool[0]
        result = true
        if bool[0] then cMarks[label] = os.clock() end
    end

    changedColor.w = imgui.IsItemHovered() and 1.0 or 0.25
    drawList:AddRect(corner, corner + ImVec2(boxSize, boxSize), conv(changedColor), 0.0, 0, 1.0)

    if bool[0] then
        local pts = {
            corner + ImVec2(clearance, clearance + boxSize * 0.3),
            corner + ImVec2(boxSize * 0.5, boxSize - clearance),
            corner + ImVec2(boxSize - clearance, clearance)
        }
        drawList:AddLine(pts[1], pts[2], conv(colorMark), 1.0)
        drawList:AddLine(pts[2], pts[3], conv(colorMark), 1.0)
    end

    local timer = os.clock() - cMarks[label]
    if timer < 0.4 then
        local r = radius + timer*25
        if timer <= 0.2 then circColor = imgui.ImVec4(color.x, color.y, color.z, r/5)
        else circColor = imgui.ImVec4(color.x, color.y, color.z, r/75)
        end
        drawList:AddCircle(ImVec2(draw.x + boxSize/2, draw.y + boxSize - clearance), r, conv(circColor))
    end
    return result
end
function imgui.ToggleButton(str_id, bool)
    local rBool = false

    if LastActiveTime == nil then
        LastActiveTime = {}
    end
    if LastActive == nil then
        LastActive = {}
    end

    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end

    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()

    local height = imgui.GetTextLineHeightWithSpacing()
    local width = height * 1.70
    local radius = height * 0.50
    local ANIM_SPEED = type == 2 and 0.10 or 0.15
    local butPos = imgui.GetCursorPos()

    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        bool[0] = not bool[0]
        rBool = true
        LastActiveTime[tostring(str_id)] = os.clock()
        LastActive[tostring(str_id)] = true
    end

    imgui.SetCursorPos(imgui.ImVec2(butPos.x + width + 8, butPos.y + 2.5))
    imgui.Text( str_id:gsub('##.+', '') )

    local t = bool[0] and 1.0 or 0.0

    if LastActive[tostring(str_id)] then
        local time = os.clock() - LastActiveTime[tostring(str_id)]
        if time <= ANIM_SPEED then
            local t_anim = ImSaturate(time / ANIM_SPEED)
            t = bool[0] and t_anim or 1.0 - t_anim
        else
            LastActive[tostring(str_id)] = false
        end
    end

    local col_circle = bool[0] and imgui.ColorConvertFloat4ToU32(imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonActive])) or imgui.ColorConvertFloat4ToU32(imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.TextDisabled]))
    dl:AddRectFilled(p, imgui.ImVec2(p.x + width, p.y + height), imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.TitleBg]), height * 0.5)
    dl:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 1.5, col_circle)
    return rBool
end
local ui_meta = {
    __index = function(self, v)
        if v == "switch" then
            local switch = function()
                if self.process and self.process:status() ~= "dead" then
                    return false
                end
                self.timer = os.clock()
                self.state = not self.state

                self.process = lua_thread.create(function()
                    local bringFloatTo = function(from, to, start_time, duration)
                        local timer = os.clock() - start_time
                        if timer >= 0.00 and timer <= duration then
                            local count = timer / (duration / 100)
                            return count * ((to - from) / 100)
                        end
                        return (timer > duration) and to or from
                    end

                    while true do wait(0)
                        local a = bringFloatTo(0.00, 1.00, self.timer, self.duration)
                        self.alpha = self.state and a or 1.00 - a
                        if a == 1.00 then break end
                    end
                end)
                return true
            end
            return switch
        end
 
        if v == "alpha" then
            return self.state and 1.00 or 0.00
        end
    end
}
local settings = { state = false, duration = 0.7 }
setmetatable(settings, ui_meta)

local checkbox_state = new.bool(inisettings.settings.state)
local checkbox_show_rp_chat = new.bool(inisettings.settings.show_rp_chat)
local checkbox_show_smi = new.bool(inisettings.settings.show_smi)
local checkbox_show_sms = new.bool(inisettings.settings.show_sms)
local checkbox_show_w = new.bool(inisettings.settings.show_w)
local checkbox_show_s = new.bool(inisettings.settings.show_s)
local checkbox_show_me = new.bool(inisettings.settings.show_me)
local checkbox_show_do = new.bool(inisettings.settings.show_do)
local checkbox_show_todo = new.bool(inisettings.settings.show_todo)
local checkbox_show_ame = new.bool(inisettings.settings.show_ame)
local checkbox_show_r = new.bool(inisettings.settings.show_r)
local checkbox_show_d = new.bool(inisettings.settings.show_d)
local checkbox_show_gnews = new.bool(inisettings.settings.show_gnews)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand('rp', settings.switch)
    
    while true do
        wait(0)
        if canMove == 1 then
            wait(888)
            canMove = 0
        end
    end
end

function onWindowMessage(msg, wparam, lparam)
    if wparam == 27 then
        if settings.state then
            if msg == wm.WM_KEYDOWN then
                consumeWindowMessage(true, false)
            end
            if msg == wm.WM_KEYUP then
                settings.switch()
            end
        end
    end
end

function sampev.onServerMessage(clr, text)
    if inisettings.settings.state then
        if clr == -577699926 and text:find('%w+_%w+ äîñòà¸ò ìîáèëüíûé òåëåôîí è îòïðàâëÿåò ÑÌÑ') then
            return false
        end
        if clr == -577699926 and text:find('%w+_%w+ îòïðàâèë ÑÌÑ') then
            return false
        end
        if clr == -1 and text:find('%w+_%w+%[%d+%] ãîâîðèò: ') then
            if not inisettings.settings.show_rp_chat then
                return false
            end
        elseif clr == -1112052737 and text:find('%w+_%w+ øåï÷åò: ') then
            if not inisettings.settings.show_w then
                return false
            end
        elseif clr == 1147587839 and text:find('%[Ãîñ. íîâîñòè%] %w+_%w+: ') then
            if not inisettings.settings.show_gnews then
                return false
            end
        elseif clr == -205835265 and (text:find('%[LS News%] %w+_%w+: ') or text:find('%[SF News%] %w+_%w+: ')) then
            if not inisettings.settings.show_smi then
                return false
            end
        elseif clr == -65281 and text:find('%[Ïåéäæåð%] îò %w+_?%w+%[%d+%]: ') then
            if not inisettings.settings.show_sms then
                return false
            end
        elseif clr == 1570844927 and text:find('%[R%] .+ %w+_?%w+%[%d+%]') then
            if not inisettings.settings.show_r then
                return false
            end
        elseif clr == 32767 and (text:find('%[D%]') and not text:find('(( %[D%]')) then
            if not inisettings.settings.show_d then
                return false
            end
        elseif clr == -4881153 and text:find('%w+_%w+%[%d+%] êðè÷èò: ') then
            if not inisettings.settings.show_s then
                return false
            end
        elseif clr == -1 and text:find('ñêàçàë %w+_%w+') and text:find('"') then
            if not inisettings.settings.show_todo then
                return false
            end
        elseif clr == -577699926 and text:find('%w+_%w+ >') then
            if not inisettings.settings.show_ame then
                return false
            end
        elseif clr == -577699926 and text:find(' | %w+_%w+') then
            if not inisettings.settings.show_do then
                return false
            end
        elseif clr == -577699926 and text:find('%w+_%w+ ') then
            if not inisettings.settings.show_me then
                return false
            end
        else
            return false
        end
    end
end
local WinFlags = imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar
imgui.OnFrame(function()
    return settings.alpha > 0.00
end, function(player)
    player.HideCursor = not settings.state
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, settings.alpha)
    imgui.SetNextWindowPos(imgui.ImVec2(getScreenResolution() / 2, getScreenResolution() / 3.4), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(300, 370), imgui.Cond.Always)
    if canMove == 0 then
        WinFlags = imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar
    else
        WinFlags = imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove
    end
    imgui.Begin('Window', _, WinFlags)
    
    imgui.PushFont(big)
    local headerTextSize = imgui.CalcTextSize('OnlyRP')
    local centerX = (300 - headerTextSize.x) / 2
    imgui.SetCursorPosX(centerX)
    imgui.Text('OnlyRP')
    imgui.PopFont()

    imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
    if imgui.ToggleButton(u8'##Àêòèâàöèÿ ñêðèïòà', checkbox_state) then
        inisettings.settings.state = checkbox_state[0]
        inicfg.save(inisettings, inicfgfile)
    end
    imgui.SameLine(0, 4)
    imgui.PushFont(norm)
    if inisettings.settings.state then
        imgui.Text(u8'Àêòèâíîñòü ñêðèïòà')
    else
        imgui.TextDisabled(u8'Àêòèâíîñòü ñêðèïòà')
    end
    imgui.PopFont()

    imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü ÐÏ ÷àò', checkbox_show_rp_chat) then
        inisettings.settings.show_rp_chat = checkbox_show_rp_chat[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü /me', checkbox_show_me) then
        inisettings.settings.show_me = checkbox_show_me[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü /ame', checkbox_show_ame) then
        inisettings.settings.show_ame = checkbox_show_ame[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü /do', checkbox_show_do) then
        inisettings.settings.show_do = checkbox_show_do[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü /todo', checkbox_show_todo) then
        inisettings.settings.show_todo = checkbox_show_todo[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü ø¸ïîò (/w)', checkbox_show_w) then
        inisettings.settings.show_w = checkbox_show_w[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü êðèê (/s)', checkbox_show_s) then
        inisettings.settings.show_s = checkbox_show_s[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü ÷àò ðàöèè (/r)', checkbox_show_r) then
        inisettings.settings.show_r = checkbox_show_r[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü ÷àò äåïàðòàìåíòà (/d)', checkbox_show_d) then
        inisettings.settings.show_d = checkbox_show_d[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü ïåéäæåð (/sms)', checkbox_show_sms) then
        inisettings.settings.show_sms = checkbox_show_sms[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü Ãîñ. íîâîñòè (/gnews)', checkbox_show_gnews) then
        inisettings.settings.show_gnews = checkbox_show_gnews[0]
        inicfg.save(inisettings, inicfgfile)
    end
    if imgui.CustomCheckbox(u8'Ïîêàçûâàòü ýôèð (ÑÌÈ)', checkbox_show_smi) then
        inisettings.settings.show_smi = checkbox_show_smi[0]
        inicfg.save(inisettings, inicfgfile)
    end

    imgui.SetCursorPosX(imgui.GetCursorPosX() + 100)
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
    if imgui.Button(u8'Çàêðûòü', imgui.ImVec2(100, 20)) then
        settings.switch()
    end

    imgui.End()
    imgui.PopStyleVar()
end)

imgui.OnInitialize(function()
    decor()
    imgui.GetIO().IniFilename = nil
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 15.0, nil, glyph_ranges)
    norm = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 16.0, _, glyph_ranges)
    big = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 20.0, _, glyph_ranges)
end)

function decor()
    imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(3.5, 3.9)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1
    imgui.GetStyle().WindowRounding = 8
    imgui.GetStyle().ChildRounding = 8
    imgui.GetStyle().FrameRounding = 8
    imgui.GetStyle().PopupRounding = 8
    imgui.GetStyle().ScrollbarRounding = 8
    imgui.GetStyle().GrabRounding = 8
    imgui.GetStyle().TabRounding = 8
end
