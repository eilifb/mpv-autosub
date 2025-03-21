local mp = require('mp')
local utils = require('mp.utils')
local mpopt = require('mp.options')

local config = {
    subliminal = "",
    languages  = { { "English", "en", "eng" } },
    logins     = {},
    auto       = false,
    debug      = false,
    force      = false,
    utf8       = true,
    excludes   = {},
    includes   = {}
}


-- Log function: log to both terminal and MPV OSD (On-Screen Display)
local function log(string, secs)
    secs = secs or 2.5           -- secs defaults to 2.5 when secs parameter is absent
    mp.msg.warn(string)          -- This logs to the terminal
    mp.osd_message(string, secs) -- This logs to MPV screen
end

-- Logs function: logs to terminal if the Bools.debug variable is true
-- includes which file and line the log function was called at
local function log_debug(input, secs)
    if not Bools.debug then
        return
    end
    local traceback = debug.traceback()
    local iterator = traceback:gmatch("[^\n]+")
    local current = iterator()
    local next_match = ""
    while current do
        next_match = iterator()
        if current:match("log_debug") then
            break
        end
        current = next_match
    end
    input = tostring(input)
    next_match = next_match:gsub(".*/", "")
    mp.msg.warn(input .. " | file:line  - " .. next_match)
end


--[[ Converts a string in the form of a table to an actual lua table.
    mpopt.read_options() has no functionality for reading or making tables.
    I am by no means a lua programmer, thus the 'hack-y' implementation.
    Could do with a lot more error checking and handling of multi-line.
--]]
local function string_to_table(input)
    input        = "return" .. input
    input        = load(input)
    local output = input() --TODO: add nil check
    return output
end


-- Check if subtitles should be auto-downloaded:
local function autosub_allowed()
    local duration = tonumber(mp.get_property('duration'))
    local active_format = mp.get_property('file-format')

    if not Bools.auto then
        mp.msg.warn('Automatic downloading disabled!')
        return false
    elseif duration < 900 then
        mp.msg.warn('Video is less than 15 minutes\n' ..
            '=> NOT auto-downloading subtitles')
        return false
    elseif directory:find('^http') then
        mp.msg.warn('Automatic subtitle downloading is disabled for web streaming')
        return false
    elseif active_format:find('^cue') then
        mp.msg.warn('Automatic subtitle downloading is disabled for cue files')
        return false
    else
        local not_allowed = { 'aiff', 'ape', 'flac', 'mp3', 'ogg', 'wav', 'wv', 'tta' }

        for _, file_format in pairs(not_allowed) do
            if file_format == active_format then
                mp.msg.warn('Automatic subtitle downloading is disabled for audio files')
                return false
            end
        end

        for _, exclude in pairs(Excludes) do
            local escaped_exclude = exclude:gsub('%W', '%%%0')
            local excluded = directory:find(escaped_exclude)

            if excluded then
                mp.msg.warn('This path is excluded from auto-downloading subs')
                return false
            end
        end

        for i, include in ipairs(Includes) do
            local escaped_include = include:gsub('%W', '%%%0')
            local included = directory:find(escaped_include)

            if included then
                break
            elseif i == #Includes then
                mp.msg.warn('This path is not included for auto-downloading subs')
                return false
            end
        end
    end

    return true
end

-- Check if subtitles should be downloaded in this language:
local function should_download_subs_in(language)
    for i, track in ipairs(sub_tracks) do
        local subtitles = track['external'] and
            'subtitle file' or 'embedded subtitles'

        if not track['lang'] and (track['external'] or not track['title'])
            and i == #sub_tracks then
            local status = track['selected'] and ' active' or ' present'
            log('Unknown ' .. subtitles .. status)
            mp.msg.warn('=> NOT downloading new subtitles')
            return false -- Don't download if 'lang' key is absent
        elseif track['lang'] == language[3] or track['lang'] == language[2] or
            (track['title'] and track['title']:lower():find(language[3])) then
            if not track['selected'] then
                mp.set_property('sid', track['id'])
                log('Enabled ' .. language[1] .. ' ' .. subtitles .. '!')
            else
                log(language[1] .. ' ' .. subtitles .. ' active')
            end
            mp.msg.warn('=> NOT downloading new subtitles')
            return false -- The right subtitles are already present
        end
    end
    mp.msg.warn('No ' .. language[1] .. ' subtitles were detected\n' ..
        '=> Proceeding to download:')
    return true
end


-- Control function: only download if necessary
local function control_downloads()
    -- Make MPV accept external subtitle files with language specifier:
    mp.set_property('sub-auto', 'fuzzy')
    -- Set subtitle language preference:
    mp.set_property('slang', Languages[1][2])
    mp.msg.warn('Reactivate external subtitle files:')
    mp.commandv('rescan_external_files')
    directory, filename = utils.split_path(mp.get_property('path'))

    if not autosub_allowed() then
        return
    end

    sub_tracks = {}
    for _, track in ipairs(mp.get_property_native('track-list')) do
        if track['type'] == 'sub' then
            sub_tracks[#sub_tracks + 1] = track
        end
    end
    if Bools.debug then -- Log subtitle properties to terminal:
        for _, track in ipairs(sub_tracks) do
            mp.msg.warn('Subtitle track', track['id'], ':\n{')
            for k, v in pairs(track) do
                if type(v) == 'string' then v = '"' .. v .. '"' end
                mp.msg.warn('  "' .. k .. '":', v)
            end
            mp.msg.warn('}\n')
        end
    end

    for _, language in ipairs(Languages) do
        if should_download_subs_in(language) then
            if download_subs(language) then return end -- Download successful!
        else
            return
        end -- No need to download!
    end
    log('No subtitles were found')
end


-- Download function: download the best subtitles in most preferred language
function download_subs(language)
    language = language or Languages[1]
    log_debug("type language: " .. type(language))
    log_debug(language)
    log_debug(language[2][1])

    if #language == 0 then
        log('No Language found\n')
        return false
    end

    log('Searching ' .. language[1] .. ' subtitles ...', 30)

    -- Build the `subliminal` command, starting with the executable:
    local subliminal_table = { args = { Subliminal } }
    local tbl = subliminal_table.args
    log_debug("tbl:")
    log_debug(tbl[1])
    for _, login in ipairs(Logins) do
        tbl[#tbl + 1] = login[1]
        tbl[#tbl + 1] = login[2]
        tbl[#tbl + 1] = login[3]
    end
    if Bools.debug then
        -- To see `--debug` output start MPV from the terminal!
        tbl[#tbl + 1] = '--debug'
    end

    tbl[#tbl + 1] = 'download'
    if Bools.force then
        tbl[#tbl + 1] = '-f'
    end
    if Bools.utf8 then
        tbl[#tbl + 1] = '-e'
        tbl[#tbl + 1] = 'utf-8'
    end

    tbl[#tbl + 1] = '-l'
    tbl[#tbl + 1] = language[2]
    tbl[#tbl + 1] = '-d'
    tbl[#tbl + 1] = directory
    tbl[#tbl + 1] = filename --> Subliminal command ends with the movie filename.

    log_debug("tbl: \n" .. table.concat(tbl, ', ') .. "\n")
    log_debug("subliminal_table.args: \n" .. table.concat(subliminal_table.args, ', ') .. "\n")

    local result = utils.subprocess(subliminal_table)

    if string.find(result.stdout, 'Downloaded 1 subtitle') then
        -- When multiple external files are present,
        -- always activate the most recently downloaded:
        mp.set_property('slang', language[2])
        -- Subtitles are downloaded successfully, so rescan to activate them:
        mp.commandv('rescan_external_files')
        log(language[1] .. ' subtitles ready!')
        return true
    else
        log('No ' .. language[1] .. ' subtitles found\n')
        return false
    end
end

-- Manually download second language subs by pressing 'n':
function download_subs2()
    download_subs(Languages[2])
end

local function init()
    mpopt.read_options(config, 'autosub') --
    Subliminal = config.subliminal
    Languages = string_to_table(config.languages)
    Logins = string_to_table(config.logins)
    Bools = { auto = config.auto, debug = config.debug, force = config.force, utf8 = config.utf8 }
    Excludes = string_to_table(config.excludes)
    Includes = string_to_table(config.includes)
end

init()
mp.add_key_binding('b', 'download_subs', download_subs)
mp.add_key_binding('n', 'download_subs2', download_subs2)
mp.register_event('file-loaded', control_downloads)
