local space_no = 0

function find_filters_by_regex(regex)
    if box.cfg.replication_source == nil then error("replica api only") end

    local cnt = 0
    local t = {}
    for tpl in box.space[space_no].index[0]:iterator(box.index.ALL) do

        if string.find(tpl[1], regex) then
            table.insert(t, tpl)
        end

        cnt = cnt + 1
        if cnt == 1000 then
            box.fiber.testcancel()
            box.fiber.sleep(0)
            cnt = 0
        end

    end

    return unpack(t)
end
