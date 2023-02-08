local imgui = require('mimgui');
local dlstatus = require('moonloader').download_status;
local MODULE = {
    __VERSION = '0.1',
    __FILE = getWorkingDirectory()..'\\lib\\mimthemes_list.json',
    __RAW = 'https://raw.githubusercontent.com/GovnocodedByChapo/mimthemes/main/list.json',
    __TEMPFILENAME = getWorkingDirectory()..'\\resource\\_TEMP_mimthemes_last_list_ver.json',
    list = {},
    listArray = {},
    updateChecked = false
};

function MODULE.__check() 
    if (MODULE.updateChecked) then return end
    downloadUrlToFile(MODULE.__RAW, MODULE.__TEMPFILENAME, function (id, status, p1, p2)
        if (status == dlstatus.STATUSEX_ENDDOWNLOAD) then
            local F = io.open(MODULE.__TEMPFILENAME, 'r');
            local JSON = decodeJson(F:read('*a') or '[]');
            F:close();

            local status, output = pcall(function()
                if (doesFileExist(MODULE.__FILE)) then
                    local F = io.open(MODULE.__FILE);
                    local CurrentJSON = decodeJson(F:read('*a') or '[]');
                    F:close();
                    print(JSON.version)
                    if (JSON.version > CurrentJSON.version) then
                        os.rename(MODULE.__TEMPFILENAME, MODULE.__FILE);
                    end
                else
                    os.rename(MODULE.__TEMPFILENAME, MODULE.__FILE);
                end
            end)
            if (not status) then
                print('error in __check:', output);
            end
            MODULE.updateChecked = true;
        end
    end)
end

function MODULE.getThemes(getArray)
    if (not doesFileExist(MODULE.__FILE)) then
        print('File "'..MODULE.__FILE..'" not found, downloading...');
        --MODULE.__check();
        return {}, 'list_file_not_found';
    end
    local F = io.open(MODULE.__FILE, 'r')
    local JSON = F:read('*a');
    F:close();
    local data = decodeJson(JSON or '[]');
    if (data) then
        MODULE.list = data.list;
        if (getArray) then
            local list = {}
            for name, _ in pairs(data.list) do
                table.insert(list, name)
            end
            MODULE.listArray = list;
            return list;
        else
            return data.list;
        end
    end
    return {};
end

local ffi = require('ffi')

function MODULE.applyTheme(name)
    if (not MODULE.updateChecked) then
        MODULE.__check();
    end
    if (not MODULE.getThemes()[name]) then
        return false;
    end
    local theme = MODULE.getThemes()[name];
    imgui.SwitchContext()
    if (theme.col) then
        for param, value in pairs(theme.col) do
            local status, _ = pcall(function() return imgui.Col[param] ~= nil end);
            assert(status, 'Unknown color style var "'..param..'"');
            assert(type(value) == 'table', 'Color must be "table"');
            assert(#value == 4, 'Color must have 4 parameters (r, g, b, a)');
            imgui.GetStyle().Colors[imgui.Col[param]] = imgui.ImVec4(table.unpack(value));
        end
    end

    if (theme.style) then
        for param, value in pairs(theme.style) do
            assert(imgui.StyleVar[param], 'Unknown style var "'..param..'"');
            assert(type(value) == 'table' or type(value) == 'number', 'Style must be "table" or "number"');
            assert(type(value) == 'number' or (#value == 4 or #value == 2), 'Incorrect value length (ImVec2 = 2 (x, y), ImVec4 = 4 (x, y, z, w))');
            imgui.GetStyle()[param] = type(value) == 'number' and value or (#value == 2 and imgui.ImVec2(table.unpack(value)) or imgui.ImVec4(table.unpack(value)));
        end
    end
    return true;
end

return MODULE;