script_author('INVILSO')
script_name('Banlist Tool 2.2')


local imgui = require 'imgui'
local copas = require 'copas'
local http = require 'copas.http'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local banlist = {}
local finded = 0
local prefix = '{FFabac}[BT]: {FFFFFF}'
local serverip = 'http://banlist-tool.fly.dev'
local serverport = '80'

local data_for_longpoll = {}
local data_for_get = {}
local chat_buff = imgui.ImBuffer(200)
local settings = {
    global = {
        active = true,
        server = 0,
        count = 0,
    },
}

local settings_imgui = {
    global = {
        active = imgui.ImBool(true),
        window = imgui.ImBool(false),
        servers = {'Trinity RPG', 'Trinity RP1', 'Trinity RP2'},
        server = imgui.ImInt(0),
        count = imgui.ImInt(0),
    },
    find = {
        find_text = imgui.ImBuffer(200),
        presets = {
            'Отключен', 
            'Баны за \naim/spread', 
            'Баны за \nмод. стрельбы', 
            'Баны HC-const', 
            'Баны HR-const', 
            'Баны C', 
            'Баны R', 
            'Варны', 
            'Разбаны', 
            'Джайлы',
            'Все',
        },
        preset_int = imgui.ImInt(0),
        presets_time = {
            'Всё время', 
            'Сегодня', 
            'Вчера', 
            'Позавчера', 
            'В этом месяце', 
            'В прошлом\nмесяце'
        },
        preset_time_int = imgui.ImInt(0),
    }
}

--------------[GUI]--------------------------
function imgui.OnDrawFrame()
    if settings_imgui['global']['window'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(700, 450), imgui.Cond.FirstUseEver, imgui.ImVec2(0.6, 0.6))
        imgui.SetNextWindowSize(imgui.ImVec2(900, 500), imgui.Cond.FirstUseEver)
        imgui.Begin('BanlistTool by INVILSO', settings_imgui['global']['window'], imgui.WindowFlags.NoResize)
            imgui.BeginChild('left_up', imgui.ImVec2(70, 35), true)
                if imgui.Button(("НАСТР."), imgui.ImVec2(0, 20)) then
                    getSettings()
                    imgui.OpenPopup(("Настройки"))
                end
                if imgui.BeginPopupModal(("Настройки"), nil, imgui.WindowFlags.AlwaysAutoResize) then -- imgui.WindowFlags.NoMove
                    imgui.ToggleButton('##bannotf', settings_imgui.global.active); imgui.SameLine(); imgui.Text('<< Уведомления о новых строках')
                    imgui.PushItemWidth(100)
                    imgui.Combo(' << Сервер', settings_imgui.global.server, settings_imgui.global.servers, #settings_imgui.global.servers)
                    imgui.PushItemWidth(100)
                    imgui.InputInt('<< Количество загружаемых cтрок', settings_imgui.global.count, 1)
                    imgui.Separator()
                    if imgui.Button('Закрыть') then
                        imgui.CloseCurrentPopup() 
                    end
                    imgui.SameLine()
                    if imgui.Button('Сохранить') then     
                        setSettings()
                        saveData()
                        data_for_longpoll.server = settings.global.server
                        data_for_get = {
                            server = settings.global.server, 
                            count = settings.global.count,
                        }
                        sampAddChatMessage(prefix..u8:decode('Настройки успешно сохранены.'), -1)
                    end
                    imgui.EndPopup()
                end
            imgui.EndChild()
            imgui.SameLine()
            imgui.BeginChild('right_up', imgui.ImVec2(0, 35), true)
                if imgui.Button('GET') then
                    getFullBanlist()
                end
                imgui.SameLine()
                imgui.BeginChild('vseperator', imgui.ImVec2(1, 20), false)
                    imgui.VerticalSeparator()
                imgui.EndChild()
                imgui.SameLine()
                imgui.PushItemWidth(120)
                imgui.Combo(' << Пресет                   ', settings_imgui.find.preset_int, settings_imgui.find.presets, #settings_imgui.find.presets)
                imgui.SameLine()
                imgui.PushItemWidth(120)
                imgui.Combo(' << Время                    ', settings_imgui.find.preset_time_int, settings_imgui.find.presets_time, #settings_imgui.find.presets_time)
                imgui.SameLine()
                imgui.PushItemWidth(120)
                imgui.InputText('<< Поиск', settings_imgui['find']['find_text']) 
            imgui.EndChild()
            imgui.BeginChild('down', imgui.ImVec2(0, 0), true)
                imgui.Columns(2)
                imgui.Separator()
                imgui.SetColumnWidth(-1, 40); imgui.CenterColumnText(' '); imgui.NextColumn()
                imgui.SetColumnWidth(-1, 5000)imgui.CenterColumnText('Запись || '..tostring(finded)); imgui.NextColumn()
                if banlist[1] ~= nil then
                    finded = 0
                    for key, val in ipairs(banlist) do
                        
                        local val_b, val_a = pcall(filter, val)
                        if val_b then
                            if val_a then
                                imgui.Separator()
                                finded = finded + 1
                                if key == 1 then
                                    val = val:match('\n(.+)')
                                end
                                if imgui.Selectable('SEND##'..tostring(key), false) then 
                                    imgui.OpenPopup('Выбор чата для отправки##'..tostring(key))
                                end
                                if imgui.BeginPopupModal('Выбор чата для отправки##'..tostring(key), nil, imgui.WindowFlags.AlwaysAutoResize) then
                                    val = val:match('%[%d+:%d+:%d+] (.+)')
                                    if #val > 140 then
                                        imgui.Text('    !!! ДЛИННАЯ СТРОКА !!!')
                                        imgui.Separator()
                                    end                        
                                    if imgui.Button('Фракция') then
                                        chat_buff.v = '/r'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Локальный') then
                                        print(:decode(val))
                                        chat_buff.v = ''
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Хелперский') then
                                        chat_buff.v = '/hc'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Клан') then
                                        chat_buff.v = '/o'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end
                                    end
                                    if imgui.Button('Неофка') then
                                        chat_buff.v = '/n'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('ОПГ') then
                                        chat_buff.v = '/f'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Ответ СМС') then
                                        chat_buff.v = '/rep'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Департамент') then
                                        chat_buff.v = '/d'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    if imgui.Button('Админский') then
                                        chat_buff.v = '/a'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Рация') then
                                        chat_buff.v = '/rc'
                                        if #val > 140 then
                                            imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                        else
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            imgui.CloseCurrentPopup() 
                                        end 
                                    end
                                    imgui.SameLine()
                                    if imgui.Button('Другое') then
                                        other = not other
                                    end
                                    if other then
                                        imgui.Separator()
                                        imgui.InputText(' <<= Введите чат (cо "/")', chat_buff)
                                        if imgui.Button('SEND') then
                                            chat_buff.v = '/rep'
                                            if #val > 110 then
                                                imgui.OpenPopup('Вы уверены в своих действиях?##'..tostring(key))
                                            else
                                                sampSendChat(chat_buff.v..' '..u8:decode(val))
                                                imgui.CloseCurrentPopup() 
                                            end  
                                        end
                                    end
                                    imgui.Separator()
                                    if imgui.Button("ОТМЕНА") then 
                                        imgui.CloseCurrentPopup() 
                                    end 
                                    if send then
                                        send = false
                                        imgui.CloseCurrentPopup()
                                    end
                                    if imgui.BeginPopupModal('Вы уверены в своих действиях?##'..tostring(key), nil, imgui.WindowFlags.AlwaysAutoResize) then
                                        imgui.Text('Вы уверены что хотите отправить этот текст?\nЕго длина сильно превышает допустимую и может отображаться некорректно')
                                        imgui.Text('Длина: ' ..tostring(#val).. ' симв.')
                                        imgui.Separator()
                                        if imgui.Button('ДА') then
                                            sampSendChat(chat_buff.v..' '..u8:decode(val))
                                            send = true
                                            imgui.CloseCurrentPopup()
                                        end
                                        imgui.SameLine()
                                        if imgui.Button('НЕТ') then
                                            imgui.CloseCurrentPopup()
                                        end
                                        imgui.EndPopup()
                                    end
                                    imgui.EndPopup()
                                end
                                
                                imgui.NextColumn()
                                if val ~= nil then
                                    imgui.TextWrapped('['..tostring(key)..'] >> '..val)
                                    imgui.NextColumn()
                                else
                                    if imgui.Selectable('Почему-то тут пусто##'..key, false) then 
                                        sampAddChatMessage('oops', -1)
                                    end
                                    imgui.NextColumn()
                                end
                            end
                        else 
                            if key == 1 then
                                imgui.Separator()
                                imgui.NextColumn();
                                imgui.Text('Закончите регулярное выражение'); imgui.NextColumn()
                            end
                        end
                    end
                else
                    imgui.Separator()
                    imgui.NextColumn();
                    imgui.Text('Банлист пустой. Попробуйте нажать кнопку "GET" и подождать некоторое время.'); imgui.NextColumn()
                end
                imgui.Columns(1); imgui.Separator()
            imgui.EndChild()
        imgui.End()
    end
end

--------[MAIN]----------------
function main()
    while not isSampAvailable() do wait(100) end
    if not doesDirectoryExist(getWorkingDirectory()..'\\config\\BanlistTool2') then createDirectory(getWorkingDirectory()..'\\config\\BanlistTool2') end
    loadData()
    sampRegisterChatCommand('bans', bans)
    data_for_longpoll = {
        server = settings.global.server, 
        ban = 'data'
    }
    data_for_get = {
        server = settings.global.server, 
        count = settings.global.count,
    }
    local longpollingthr = lua_thread.create_suspended(longpollingFunc)
    longpollingthr:run()
    sampAddChatMessage(u8:decode('{FFabac}[BT]: {FFFFFF}Скрипт успешно загружен. Автор: {FFabac}INVILSO{FFFFFF}. Команды - {FFabac}/bans menu{FFFFFF}, {FFabac}/bans active{FFFFFF}, {FFabac}/bans chat [chat]'), -1)
    while true do
        wait(0)
        imgui.Process = settings_imgui['global']['window'].v
    end
end

function bans(text)
    if text == 'active' then
        settings['global']['active'] = not settings['global']['active']
        saveData()
        if settings['global']['active'].v then
            sampAddChatMessage(prefix..u8:decode("Уведомление о новой строке в банлисте включено."), -1)
        else
            sampAddChatMessage(prefix..u8:decode("Уведомление о новой строке в банлисте отключено."), -1)
        end
    elseif text:find('chat .+') then
        local chat = text:match('chat (.+)')
        if chat == 'lc' then
            sampSendChat(:decode(data_for_longpoll['ban']))
        elseif chat ~= nil or chat ~= '' then
            sampSendChat('/'..chat..' '..:decode(data_for_longpoll['ban']))
        end
    elseif text:find('menu') then
        settings_imgui['global']['window'].v = not settings_imgui['global']['window'].v
    else
        sampAddChatMessage(prefix..u8:decode("Вы забыли ввести аргумент."), -1)
    end
end

function filter(val)
    if settings_imgui.find.preset_int.v == 0 then
        result = val:find(settings_imgui['find']['find_text'].v)
    else
        if settings_imgui.find.preset_time_int.v == 0 then --Все время
            if settings_imgui.find.preset_int.v == 1 then -- За аим
                result = val:find('%[%d+:%d+:%d+] B: %S+ .+, .+: %[HC .+] aim')
            elseif settings_imgui.find.preset_int.v == 2 then -- За модиф
                result = val:find(u8:decode('%[%d+:%d+:%d+] B: %S+ .+, .+: %[HC .+] Модификация стрельбы'))
            elseif settings_imgui.find.preset_int.v == 3 then -- HC
                result = val:find('%[%d+:%d+:%d+] B: %S+ .+, .+: %[HC .+]')
            elseif settings_imgui.find.preset_int.v == 4 then --HR
                result = val:find('%[%d+:%d+:%d+] B: %S+ .+, .+: %[HR .+]')
            elseif settings_imgui.find.preset_int.v == 5 then --C
                result = val:find('%[%d+:%d+:%d+] B: %S+ .+, .+: %[C .+]')
            elseif settings_imgui.find.preset_int.v == 6 then --R
                result = val:find('%[%d+:%d+:%d+] B: %S+ .+, .+: %[R .+]')
            elseif settings_imgui.find.preset_int.v == 7 then --Warns
                result = val:find('%[%d+:%d+:%d+] W:')
            elseif settings_imgui.find.preset_int.v == 8 then --Unbans
                result = val:find(u8:decode('%[%d+:%d+:%d+] U: Администратор %S+ разбанил по ошибке забаненный ранее аккаунт'))
            elseif settings_imgui.find.preset_int.v == 9 then --Jails
                result = val:find(u8:decode('%[%d+:%d+:%d+] J: %S+ отправлен администратором'))
            elseif settings_imgui.find.preset_int.v == 10 then --All
                result = val:find('%[%d+:%d+:%d+]')
            end
        elseif settings_imgui.find.preset_time_int.v == 1 then --Сегодня
            local day = os.date("%d")
            if settings_imgui.find.preset_int.v == 1 then -- За аим
                result = val:find(u8:decode('%['..day..':%d+:%d+] B: %S+ .+, .+: %[HC .+] aim'))
            elseif settings_imgui.find.preset_int.v == 2 then -- За модиф
                result = val:find(u8:decode('%['..day..':%d+:%d+] B: %S+ .+, .+: %[HC .+] Модификация стрельбы'))
            elseif settings_imgui.find.preset_int.v == 3 then -- HC
                result = val:find('%['..day..':%d+:%d+] B: %S+ .+, .+: %[HC .+]')
            elseif settings_imgui.find.preset_int.v == 4 then --HR
                result = val:find('%['..day..':%d+:%d+] B: %S+ .+, .+: %[HR .+]')
            elseif settings_imgui.find.preset_int.v == 5 then --C
                result = val:find('%['..day..':%d+:%d+] B: %S+ .+, .+: %[C .+]')
            elseif settings_imgui.find.preset_int.v == 6 then --R
                result = val:find('%['..day..':%d+:%d+] B: %S+ .+, .+: %[R .+]')
            elseif settings_imgui.find.preset_int.v == 7 then --Warns
                result = val:find('%['..day..':%d+:%d+] W: %S+ .+, .+: .+')
            elseif settings_imgui.find.preset_int.v == 8 then --Unbans
                result = val:find('%['..day..u8:decode(':%d+:%d+] U: Администратор %S+ разбанил по ошибке забаненный ранее аккаунт'))
            elseif settings_imgui.find.preset_int.v == 9 then --Jails
                result = val:find('%['..day..u8:decode(':%d+:%d+] J: %S+ отправлен администратором'))
            elseif settings_imgui.find.preset_int.v == 10 then --All
                result = val:find('%['..tostring(day)..':%d+:%d+]')
            end
        elseif settings_imgui.find.preset_time_int.v == 2 then --Вчера
            local day = os.date("%d")
            day = tonumber(day)
            if day < 10 then
                day = day - 1
                day = tostring(day)
                day = '0'..day
            else
                day = day - 1
            end
            
            if settings_imgui.find.preset_int.v == 1 then -- За аим
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[HC .+] aim')
            elseif settings_imgui.find.preset_int.v == 2 then -- За модиф
                result = val:find('%['..tostring(day)..u8:decode(':%d+:%d+] B: %S+ .+, .+: %[HC .+] Модификация стрельбы'))
            elseif settings_imgui.find.preset_int.v == 3 then -- HC
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[HC .+]')
            elseif settings_imgui.find.preset_int.v == 4 then --HR
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[HR .+]')
            elseif settings_imgui.find.preset_int.v == 5 then --C
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[C .+]')
            elseif settings_imgui.find.preset_int.v == 6 then --R
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[R .+]')
            elseif settings_imgui.find.preset_int.v == 7 then --Warns
                result = val:find('%['..tostring(day)..':%d+:%d+] W: %S+ .+, .+: .+')
            elseif settings_imgui.find.preset_int.v == 8 then --Unbans
                result = val:find('%['..tostring(day)..u8:decode(':%d+:%d+] U: Администратор %S+ разбанил по ошибке забаненный ранее аккаунт'))
            elseif settings_imgui.find.preset_int.v == 9 then --Jails
                result = val:find('%['..tostring(day)..u8:decode(':%d+:%d+] J: %S+ отправлен администратором'))
            elseif settings_imgui.find.preset_int.v == 10 then --All
                result = val:find('%['..tostring(day)..':%d+:%d+]')
            end
        elseif settings_imgui.find.preset_time_int.v == 3 then --Позавчера
            local day = os.date("%d")
            day = tonumber(day)
            if day < 10 then
                day = day - 2
                day = tostring(day)
                day = '0'..day
            else
                day = day - 2
            end
            if settings_imgui.find.preset_int.v == 1 then -- За аим
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[HC .+] aim')
            elseif settings_imgui.find.preset_int.v == 2 then -- За модиф
                result = val:find('%['..tostring(day)..u8:decode(':%d+:%d+] B: %S+ .+, .+: %[HC .+] Модификация стрельбы'))
            elseif settings_imgui.find.preset_int.v == 3 then -- HC
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[HC .+]')
            elseif settings_imgui.find.preset_int.v == 4 then --HR
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[HR .+]')
            elseif settings_imgui.find.preset_int.v == 5 then --C
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[C .+]')
            elseif settings_imgui.find.preset_int.v == 6 then --R
                result = val:find('%['..tostring(day)..':%d+:%d+] B: %S+ .+, .+: %[R .+]')
            elseif settings_imgui.find.preset_int.v == 7 then --Warns
                result = val:find('%['..tostring(day)..':%d+:%d+] W: %S+ .+, .+: .+')
            elseif settings_imgui.find.preset_int.v == 8 then --Unbans
                result = val:find('%['..tostring(day)..u8:decode(':%d+:%d+] U: Администратор %S+ разбанил по ошибке забаненный ранее аккаунт'))
            elseif settings_imgui.find.preset_int.v == 9 then --Jails
                result = val:find('%['..tostring(day)..u8:decode(':%d+:%d+] J: %S+ отправлен администратором'))
            elseif settings_imgui.find.preset_int.v == 10 then --All
                result = val:find('%['..tostring(day)..':%d+:%d+]')
            end
        elseif settings_imgui.find.preset_time_int.v == 4 then --В этом месяце
            local day = os.date("%m")
            if settings_imgui.find.preset_int.v == 1 then -- За аим
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[HC .+] aim')
            elseif settings_imgui.find.preset_int.v == 2 then -- За модиф
                result = val:find('%[%d+:'..tostring(day)..u8:decode(':%d+] B: %S+ .+, .+: %[HC .+] Модификация стрельбы'))
            elseif settings_imgui.find.preset_int.v == 3 then -- HC
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[HC .+]')
            elseif settings_imgui.find.preset_int.v == 4 then --HR
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[HR .+]')
            elseif settings_imgui.find.preset_int.v == 5 then --C
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[C .+]')
            elseif settings_imgui.find.preset_int.v == 6 then --R
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[R .+]')
            elseif settings_imgui.find.preset_int.v == 7 then --Warns
                result = val:find('%[%d+:'..tostring(day)..':%d+] W: %S+ .+, .+: .+')
            elseif settings_imgui.find.preset_int.v == 8 then --Unbans
                result = val:find('%[%d+:'..tostring(day)..u8:decode(':%d+] U: Администратор %S+ разбанил по ошибке забаненный ранее аккаунт'))
            elseif settings_imgui.find.preset_int.v == 9 then --Jails
                result = val:find('%[%d+:'..tostring(day)..u8:decode(':%d+] J: %S+ отправлен администратором'))
            elseif settings_imgui.find.preset_int.v == 10 then --All
                result = val:find('%[%d+:'..tostring(day)..':%d+]')
            end
        elseif settings_imgui.find.preset_time_int.v == 5 then --В прошлом месяце
            local day = os.date("%m")
            day = tonumber(day)
            if day < 10 then
                day = day - 1
                day = tostring(day)
                day = '0'..day
            else
                day = day - 1
            end
            if settings_imgui.find.preset_int.v == 1 then -- За аим
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[HC .+] aim')
            elseif settings_imgui.find.preset_int.v == 2 then -- За модиф
                result = val:find('%[%d+:'..tostring(day)..u8:decode(':%d+] B: %S+ .+, .+: %[HC .+] Модификация стрельбы'))
            elseif settings_imgui.find.preset_int.v == 3 then -- HC
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[HC .+]')
            elseif settings_imgui.find.preset_int.v == 4 then --HR
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[HR .+]')
            elseif settings_imgui.find.preset_int.v == 5 then --C
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[C .+]')
            elseif settings_imgui.find.preset_int.v == 6 then --R
                result = val:find('%[%d+:'..tostring(day)..':%d+] B: %S+ .+, .+: %[R .+]')
            elseif settings_imgui.find.preset_int.v == 7 then --Warns
                result = val:find('%[%d+:'..tostring(day)..':%d+] W: %S+ .+, .+: .+')
            elseif settings_imgui.find.preset_int.v == 8 then --Unbans
                result = val:find('%[%d+:'..tostring(day)..u8:decode(':%d+] U: Администратор %S+ разбанил по ошибке забаненный ранее аккаунт'))
            elseif settings_imgui.find.preset_int.v == 9 then --Jails
                result = val:find('%[%d+:'..tostring(day)..u8:decode(':%d+] J: %S+ отправлен администратором'))
            elseif settings_imgui.find.preset_int.v == 10 then --All
                result = val:find('%[%d+:'..tostring(day)..':%d+]')
            end
        end
    end
    return result
end

---------------[WebFuncs]-----------------------
function longpollingFunc()
    while true do
        wait(0)
        if settings.global.active then
            local response, code, headers, status = httpRequest(serverip..":"..serverport.."/banlist/longpoll", encodeJson(data_for_longpoll))
            if code == 200 then
                if decodeJson(response)[1] ~= false then
                    data_for_longpoll['ban'] = decodeJson(response)[1]
                    sampAddChatMessage('{FF0000}'..:decode(data_for_longpoll['ban']:sub(14, data_for_longpoll['ban']:len())), 0xFFFFFF)
                else
                    print(response)
                end
            else 
                print('{FFFFFF}REQUEST ERROR: '..code)
            end
        end
    end
end
function getFullBanlist()
    httpRequest(
        serverip..":"..serverport.."/banlist/get", 
        encodeJson(data_for_get), 
        function (response, code, headers, status)
            if code == 200 then
                if decodeJson(response)[1] ~= false then
                    banlist = decodeJson(response)
                    sampAddChatMessage(prefix..u8:decode('Строки банлиста успешно получены.'), -1)
                end
            else 
                sampAddChatMessage(prefix..u8:decode('При получении возникла ошибка, посмотрите в консоль.'), -1)
                print('{FFFFFF}REQUEST ERROR: '..code)
            end
        end
    )
end

--------------[SETTINGS Funcs]--------------
function getSettings()
    ---------[global]----------
    settings_imgui.global.active.v = settings.global.active
    settings_imgui.global.server.v = settings.global.server
    settings_imgui.global.count.v = settings.global.count
end
function setSettings()
    ---------[global]----------
    settings.global.active = settings_imgui.global.active.v
    settings.global.server = settings_imgui.global.server.v
    settings.global.count = settings_imgui.global.count.v
end

function saveData()
	local configFile = io.open(getWorkingDirectory()..'\\config\\BanlistTool2\\bt.json', 'w+')
	configFile:write(encodeJson(settings))
	configFile:close()
end
function loadData()
	if not doesFileExist(getWorkingDirectory()..'\\config\\BanlistTool2\\bt.json') then
	  local configFile = io.open(getWorkingDirectory()..'\\config\\BanlistTool2\\bt.json', 'w+')
	  configFile:write(encodeJson(settings))
	  configFile:close()
	  return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\BanlistTool2\\bt.json', 'r')
	settings = decodeJson(configFile:read('*a'))
    configFile:close()
end

------------------[GUIFUNCS]---------------
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end
function customStyle()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
    colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
    colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
    colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
    colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
    colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
    colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
    colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
    colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
end
customStyle()
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
	local draw_list = imgui.GetWindowDrawList()

	local height = imgui.GetTextLineHeightWithSpacing()
	local width = height * 1.55
	local radius = height * 0.50
	local ANIM_SPEED = 0.17

	if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
		bool.v = not bool.v
		rBool = true
		LastActiveTime[tostring(str_id)] = os.clock()
		LastActive[tostring(str_id)] = true
	end

	local t = bool.v and 1.0 or 0.0

	if LastActive[tostring(str_id)] then
		local time = os.clock() - LastActiveTime[tostring(str_id)]
		if time <= ANIM_SPEED then
			local t_anim = ImSaturate(time / ANIM_SPEED)
			t = bool.v and t_anim or 1.0 - t_anim
		else
			LastActive[tostring(str_id)] = false
		end
	end

	local col_bg
	if bool.v then
		col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBgHovered])
	else
		col_bg = imgui.ImColor(100, 100, 100, 180):GetU32()
	end

	draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y + (height / 6)), imgui.ImVec2(p.x + width - 1.0, p.y + (height - (height / 6))), col_bg, 5.0)
	draw_list:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 0.75, imgui.GetColorU32(bool.v and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.ImColor(150, 150, 150, 255):GetVec4()))

	return rBool
end
function imgui.VerticalSeparator()
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x, p.y + imgui.GetContentRegionMax().y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.Separator]))
end

------------------[HTTP]-------------------
function httpRequest(request, body, handler) -- copas.http
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end