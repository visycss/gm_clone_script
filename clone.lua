local function ClonePlayerModel(ply, count)
    if not IsValid(ply) then
        print("[CLONE CRITICAL] Игрок не валиден!")
        return
    end

    -- Диагностика окружения
    print("[CLONE DEBUG] Проверка базовых функций:")
    print("ents таблица существует?", tostring(ents ~= nil))
    print("ents.Create существует?", tostring(type(ents.Create) == "function"))
    print("player.GetAll существует?", tostring(type(player.GetAll) == "function"))

    local model = ply:GetModel()
    print("[CLONE DEBUG] Модель игрока:", model)

    if not util.IsValidModel(model) then
        ply:ChatPrint("Ошибка: Недопустимая модель игрока!")
        print("[CLONE ERROR] Модель невалидна:", model)
        return
    end

    count = math.Clamp(tonumber(count) or 1, 1, 20)
    print("[CLONE DEBUG] Количество клонов:", count)

    -- Альтернативный способ создания ентити
    local function TryCreateEntity()
        -- Попробуем разные методы создания
        local ent = nil
        
        -- Метод 1: Стандартный способ
        if type(ents.Create) == "function" then
            print("[CLONE DEBUG] Пробуем стандартный ents.Create")
            pcall(function() ent = ents.Create("prop_dynamic") end)
        end

        -- Метод 2: Через дублирование существующего объекта
        if not IsValid(ent) then
            print("[CLONE DEBUG] Пробуем дублирование объекта")
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) then
                pcall(function() ent = tr.Entity:Clone() end)
            end
        end

        -- Метод 3: Через console command
        if not IsValid(ent) then
            print("[CLONE DEBUG] Пробуем создание через консольную команду")
            ply:ConCommand("gm_spawn "..model)
            timer.Simple(0.1, function()
                local ents = ents.FindByClass("prop_physics")
                if #ents > 0 then
                    ent = ents[1]
                    ent:SetModel(model)
                end
            end)
            return
        end

        return ent
    end

    -- Создаем клоны
    for i = 1, count do
        timer.Simple(i * 0.5, function()
            if not IsValid(ply) then return end

            print("[CLONE DEBUG] Создание клона", i)
            local ent = TryCreateEntity()

            if not IsValid(ent) then
                ply:ChatPrint("Ошибка: Не удалось создать клон!")
                print("[CLONE ERROR] Не удалось создать ентити")
                return
            end

            -- Настройка клона
            ent:SetModel(model)
            local pos = ply:GetPos() + ply:GetForward() * 100 + Vector(0,0,10)
            ent:SetPos(pos)
            ent:SetAngles(ply:GetAngles())
            
            if ply.GetPlayerColor then
                ent:SetColor(ply:GetPlayerColor():ToColor())
            end

            print("[CLONE SUCCESS] Клон создан успешно")
            ply:ChatPrint("Клон создан!")

            -- Автоудаление
            timer.Simple(30, function()
                if IsValid(ent) then ent:Remove() end
            end)
        end)
    end
end

concommand.Add("clone", function(ply, cmd, args)
    print("[CLONE INIT] Вызвана команда clone")
    ClonePlayerModel(ply, args[1] or 1)
end)

-- Дополнительная диагностика
timer.Simple(5, function()
    print("\n[CLONE DIAGNOSTIC] Информация о системе:")
    print("Версия Garry's Mod:", VERSION)
    print("Серверная сторона:", SERVER and "Да" or "Нет")
    print("Клиентская сторона:", CLIENT and "Да" or "Нет")
    print("Доступные entity классы:")
    for _, class in ipairs({"prop_physics", "prop_dynamic", "prop_ragdoll"}) do
        print("- "..class..":", tostring(scripted_ents.GetStored(class) ~= nil))
    end
end)