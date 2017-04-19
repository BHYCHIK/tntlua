local signature_space = 0
local alias_space = 2

function get_dkim_for_domain(domain_name)
    local original_domain_name = domain_name

    local alias = box.select(alias_space, 0, domain_name)
    if alias then
        domain_name = alias[1]
    end

    local signature_data = box.select(signature_space, 0, domain_name)
    if signature_data then
        return box.tuple.new({original_domain_name, signature_data[1], signature_data[2]})
    end

    return box.tuple.new({"", "", ""})
end
