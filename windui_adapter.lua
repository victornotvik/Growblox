-- ============================================================
-- WindUI → Rayfield Adapter
-- Menggantikan baris 50-52 di k.lua (WindUI loadstring)
-- Kompatibel dengan Delta executor. Tanpa dependency eksternal
-- selain Rayfield.
-- ============================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ============================================================
-- HELPERS
-- ============================================================

-- Buat Toggle element dengan dukungan :Set(bool)
local function wrapToggle(rfElement, cb)
    -- rfElement adalah nilai balik CreateToggle (bisa nil di beberapa versi Rayfield)
    local el = {}
    el._cb   = cb
    el._val  = false
    function el:Set(v)
        self._val = v == true
        if self._cb then
            pcall(self._cb, self._val)
        end
        -- Coba update visual Rayfield kalau ada method
        if rfElement and type(rfElement.Set) == "function" then
            pcall(rfElement.Set, rfElement, self._val)
        end
    end
    return el
end

-- Buat Paragraph element dengan dukungan :SetDesc(str)
local function wrapParagraph(rfElement, title)
    local el = {}
    el._title = title or ""
    el._rf    = rfElement
    function el:SetDesc(txt)
        if self._rf and type(self._rf.Set) == "function" then
            pcall(self._rf.Set, self._rf, { Title = self._title, Content = tostring(txt or "") })
        end
    end
    return el
end

-- Buat Input element dengan dukungan :Set(str)
local function wrapInput(rfElement)
    local el = {}
    el._rf = rfElement
    function el:Set(txt)
        -- Rayfield Input tidak punya .Set; kita simpan nilai saja (tidak ada cara update visual)
        el._val = tostring(txt or "")
    end
    return el
end

-- Buat Dropdown element dengan dukungan :Refresh(values), :Select(opt)
local function wrapDropdown(rfElement)
    local el = {}
    el._rf = rfElement
    function el:Refresh(values)
        -- Rayfield tidak mendukung update daftar opsi secara langsung.
        -- Kita simpan saja; script k.lua tidak crash asalkan fungsi ada.
        el._values = values
    end
    function el:Select(opt)
        -- Simpan pilihan; tidak bisa memperbarui visual Rayfield secara runtime.
        el._selected = opt
    end
    return el
end

-- ============================================================
-- SECTION / BOX BUILDER (pembungkus untuk Tab)
-- ============================================================
-- WindUI Section dalam Tab = Box yang bisa collapsed.
-- Rayfield: gunakan CreateSection sebagai visual separator saja,
-- lalu semua elemen tetap dibuat di Tab parent.

local function makeBox(rfTab, sectionName)
    -- Buat separator visual
    if sectionName then
        pcall(function() rfTab:CreateSection(tostring(sectionName)) end)
    end

    -- Kembalikan proxy yang memforward semua method ke rfTab
    local box = {}

    function box:Toggle(opts)
        opts = opts or {}
        local title = tostring(opts.Title or "")
        local def   = opts.Value == true
        local cb    = type(opts.Callback) == "function" and opts.Callback or nil
        local rf    = pcall(function()
            rfTab:CreateToggle({
                Name         = title,
                CurrentValue = def,
                Flag         = nil,
                Callback     = function(v)
                    if cb then pcall(cb, v) end
                end,
            })
        end)
        -- Dapatkan elemen Rayfield (Rayfield biasanya tidak return objek dari CreateToggle)
        return wrapToggle(nil, cb)
    end

    function box:Button(opts)
        opts = opts or {}
        local title = tostring(opts.Title or "")
        local cb    = type(opts.Callback) == "function" and opts.Callback or nil
        pcall(function()
            rfTab:CreateButton({
                Name     = title,
                Callback = function()
                    if cb then pcall(cb) end
                end,
            })
        end)
    end

    function box:Slider(opts)
        opts = opts or {}
        local title   = tostring(opts.Title or "")
        local valTbl  = type(opts.Value) == "table" and opts.Value or {}
        local minV    = tonumber(valTbl.Min)   or 0
        local maxV    = tonumber(valTbl.Max)   or 100
        local defV    = tonumber(valTbl.Default) or minV
        local step    = tonumber(opts.Step)    or 1
        local cb      = type(opts.Callback) == "function" and opts.Callback or nil
        pcall(function()
            rfTab:CreateSlider({
                Name         = title,
                Range        = { minV, maxV },
                Increment    = step,
                CurrentValue = defV,
                Flag         = nil,
                Callback     = function(v)
                    if cb then pcall(cb, v) end
                end,
            })
        end)
    end

    function box:Dropdown(opts)
        opts = opts or {}
        local title  = tostring(opts.Title or "")
        local values = type(opts.Values) == "table" and opts.Values or {}
        local defVal = opts.Value
        local cb     = type(opts.Callback) == "function" and opts.Callback or nil
        local isMulti = opts.Multi == true

        -- tentukan CurrentOption
        local curOpt
        if isMulti then
            if type(defVal) == "table" then
                curOpt = defVal
            else
                curOpt = {}
            end
        else
            if type(defVal) == "string" then
                curOpt = { defVal }
            elseif type(defVal) == "table" then
                curOpt = defVal
            else
                curOpt = (#values > 0) and { values[1] } or {}
            end
        end

        local rfEl
        pcall(function()
            rfEl = rfTab:CreateDropdown({
                Name            = title,
                Options         = values,
                CurrentOption   = curOpt,
                MultipleOptions = isMulti,
                Flag            = nil,
                Callback        = function(opt)
                    if cb then
                        if isMulti then
                            pcall(cb, type(opt) == "table" and opt or { opt })
                        else
                            local v = type(opt) == "table" and opt[1] or opt
                            pcall(cb, v)
                        end
                    end
                end,
            })
        end)
        return wrapDropdown(rfEl)
    end

    function box:Input(opts)
        opts = opts or {}
        local title  = tostring(opts.Title or "")
        local ph     = tostring(opts.Placeholder or opts.Desc or "")
        local cb     = type(opts.Callback) == "function" and opts.Callback or nil
        local rfEl
        pcall(function()
            rfEl = rfTab:CreateInput({
                Name                    = title,
                PlaceholderText         = ph,
                RemoveTextAfterFocusLost = false,
                Flag                    = nil,
                Callback                = function(text)
                    if cb then pcall(cb, text) end
                end,
            })
        end)
        return wrapInput(rfEl)
    end

    function box:Paragraph(opts)
        opts = opts or {}
        local title = tostring(opts.Title or "")
        local desc  = tostring(opts.Desc or "")
        local rfEl
        pcall(function()
            rfEl = rfTab:CreateParagraph({ Title = title, Content = desc })
        end)
        return wrapParagraph(rfEl, title)
    end

    -- Section dalam Box tidak di-nested (Rayfield tidak support), cukup buat separator
    function box:Section(opts)
        opts = opts or {}
        local subName = tostring(opts.Title or "")
        return makeBox(rfTab, subName)
    end

    return box
end

-- ============================================================
-- TAB WRAPPER
-- ============================================================

local function makeTab(rfWindow, tabName)
    local rfTab
    pcall(function()
        rfTab = rfWindow:CreateTab(tostring(tabName or ""), nil)
    end)
    if not rfTab then
        -- Fallback: buat proxy kosong agar tidak crash
        local dummy = {}
        setmetatable(dummy, { __index = function() return function() return {} end end })
        return dummy
    end

    -- Buat proxy yang memiliki semua method WindUI Tab,
    -- dan mendelegasikan ke rfTab atau makeBox
    local tab = makeBox(rfTab, nil)  -- inherit semua method box

    -- Override Section (box collapsible dalam tab) → pakai makeBox dengan separator
    function tab:Section(opts)
        opts = opts or {}
        local title = tostring(opts.Title or "")
        return makeBox(rfTab, title)
    end

    return tab
end

-- ============================================================
-- SECTION (SIDEBAR GRUP) WRAPPER
-- ============================================================
-- WindUI Section di sidebar = grup yang berisi Tab.
-- Rayfield tidak ada sidebar grup; kita buat Tab biasa.

local function makeSection(rfWindow, _secTitle)
    local sec = {}
    function sec:Tab(opts)
        opts = opts or {}
        local title = tostring(opts.Title or opts[1] or "")
        return makeTab(rfWindow, title)
    end
    return sec
end

-- ============================================================
-- WINDOW WRAPPER
-- ============================================================

local function makeWindow(rfWindow)
    local win = {}

    -- Window:Section(...) → sidebar grup (abaikan grouping, return Section proxy)
    function win:Section(opts)
        opts = opts or {}
        local title = tostring(opts.Title or "")
        return makeSection(rfWindow, title)
    end

    -- Window:Tab(...) → buat Tab langsung (tanpa grup)
    function win:Tab(opts)
        opts = opts or {}
        local title = tostring(opts.Title or opts[1] or "")
        return makeTab(rfWindow, title)
    end

    -- Window:EditOpenButton(...) → Rayfield tidak ada; abaikan dengan aman
    function win:EditOpenButton(_opts)
        -- noop
    end

    -- Window:Destroy() → Rayfield tidak expose Destroy; pcall untuk aman
    function win:Destroy()
        pcall(function()
            if rfWindow and type(rfWindow.Destroy) == "function" then
                rfWindow:Destroy()
            end
        end)
    end

    return win
end

-- ============================================================
-- WINDUI ADAPTER UTAMA
-- ============================================================

local WindUI = {}

-- WindUI:CreateWindow(opts) → return Window
function WindUI:CreateWindow(opts)
    opts = opts or {}
    local title  = tostring(opts.Title  or "Script")
    local author = tostring(opts.Author or "")

    local rfWin
    pcall(function()
        rfWin = Rayfield:CreateWindow({
            Name              = title,
            LoadingTitle      = title,
            LoadingSubtitle   = author,
            ConfigurationSaving = { Enabled = false },
            KeySystem         = false,
        })
    end)

    if not rfWin then
        -- Fallback dummy window agar k.lua tidak crash
        local dummy = {}
        setmetatable(dummy, {
            __index = function(_, _k)
                return function() return setmetatable({}, {
                    __index = function() return function() return {} end end
                }) end
            end
        })
        return dummy
    end

    return makeWindow(rfWin)
end

-- WindUI:Notify(opts)
function WindUI:Notify(opts)
    opts = opts or {}
    pcall(function()
        Rayfield:Notify({
            Title    = tostring(opts.Title   or ""),
            Content  = tostring(opts.Content or ""),
            Duration = tonumber(opts.Duration) or 5,
            Image    = nil,
        })
    end)
end

-- WindUI:Popup(opts)
-- Rayfield tidak punya modal popup. Strategi:
--   1. Tampilkan notifikasi dengan isi Content.
--   2. Panggil callback tombol pertama (Indonesia) secara otomatis
--      SETELAH delay kecil, sehingga caller bisa lanjut.
--   Jika tidak ada tombol, cukup notify saja.
function WindUI:Popup(opts)
    opts = opts or {}
    local title   = tostring(opts.Title   or "")
    local content = tostring(opts.Content or "")
    local buttons = type(opts.Buttons) == "table" and opts.Buttons or {}

    -- Tampilkan sebagai notifikasi
    local notifContent = content
    if #buttons > 0 then
        local names = {}
        for _, b in ipairs(buttons) do
            names[#names + 1] = tostring(b.Title or "")
        end
        notifContent = content .. "\n[" .. table.concat(names, " / ") .. "]"
    end

    pcall(function()
        Rayfield:Notify({
            Title   = title,
            Content = notifContent,
            Duration = 4,
            Image   = nil,
        })
    end)

    -- Panggil callback tombol pertama otomatis (seperti menekan tombol default)
    if #buttons > 0 and type(buttons[1].Callback) == "function" then
        task.spawn(function()
            task.wait(0.1)
            pcall(buttons[1].Callback)
        end)
    end
end

-- ============================================================
-- Expose WindUI sebagai hasil loadstring (menggantikan baris 50-52)
-- ============================================================
return WindUI
