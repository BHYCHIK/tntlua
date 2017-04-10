-- Race conditions in this files are possible. It is ok by biz logic.
--

local tuple_length_limit = 1001 --max numbers of element + 1. VALUE MUST BE ODD.
local space_no = 0

local function truncate_tuple(selected)
    selected = selected:transform(1, #selected - tuple_length_limit):transform(1, (tuple_length_limit - 1) / 2)
    box.replace(space_no, selected)
    return selected
end

function ussender_add(user_id, sender_id)
    local user_id = box.unpack("i", user_id)
    local sender_id = box.unpack("l", sender_id)

    local selected = { box.select_limit(space_no, 0, 0, 1, user_id) }

    if #selected == 0 then
        box.insert(space_no, user_id, sender_id)
    else

        if #selected[1] >= tuple_length_limit then
            selected[1] = truncate_tuple(selected[1])
        end

        local fun, param, state = selected[1]:pairs()
        state, _ = fun(param, state) -- skip the first element of tuple
        for state, v in fun, param, state do
            local cur_id = box.unpack("l", v)
            if cur_id == sender_id then
                return
            end
        end
        box.update(space_no, user_id, "!p", -1, sender_id)
    end

end

function ussender_select(user_id)
    local user_id = box.unpack("i", user_id)
    local ret = {box.select_limit(space_no, 0, 0, 1, user_id)}
    if #ret == 0 then
        return {user_id}
    end
    if #ret[1] >= tuple_length_limit then
        ret[1] = truncate_tuple(ret[1])
    end
    return ret
end

function ussender_delete(user_id)
    local user_id = box.unpack("i", user_id)
    box.delete(space_no, user_id)
end
