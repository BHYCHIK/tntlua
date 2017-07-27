-- Tuple of profile has always 2 fields.
-- Field 1 -- user-id
-- Field 2 -- key/value dict. Key is always a number.

box.cfg{listen = 3301}
box.once('init', function()
	profile_space = box.schema.space.create('profile', {id = 1})
	profile_space:create_index('primary', {
		type = 'tree',
		parts = {1, 'unsigned'},
		unique = true
		})
	box.schema.user.grant('guest', 'read,write,execute', 'universe')
	end)

msgpack = require('msgpack')

-- Cast internal profile format to the format, requested by client-side.
local function cast_profile_to_return_format(profile)
	setmetatable(profile.data, msgpack.map_mt) -- If we doesnt call this, we will receive an array with many nulls, not map.
	return {profile.uid, profile.data}
end

local function store_profile(profile)
	-- We dont want to store empty profiles. Save space.
	if #profile.data == 0 then
		return box.space.profile:delete(profile.uid)
	end

	setmetatable(profile.data, msgpack.map_mt) -- If we doesnt call this, we will store an array with many nulls, not map.
	return box.space.profile:replace({profile.uid, profile.data})
end

local function create_new_profile(user_id)
	local profile = {}
	profile.uid = user_id
	profile.data = {}
	return profile
end

local function load_profile(user_id)
	local tup = box.space.profile:select(user_id)
	-- In case no profile found, operate it as profile without keys/values
	if #tup == 0 then
		return create_new_profile(user_id)
	end
	local profile = {}
	profile.uid = user_id
	profile.data = tup[1][2] -- Index 1 is because we have only 1 tuple with such userid (index is unique). Second field of tuple is key/value dict.
	return profile
end

local function set_profile_key(profile, key, value)
	-- Do not store empty keys. We want to save space.
	if value == '' then
		value = nil
	end
	profile.data[key] = value
end

-- function profile_delete delete profile. Returns nothing
function profile_delete(user_id)
	box.space.profile:delete(user_id)
end

-- function profile_get_all returns full profile
function profile_get_all(user_id)
	local profile = load_profile(user_id)
	return cast_profile_to_return_format(profile)
end

-- function profile_multiget returns only requested keys from profile. Accepts user_id and then several keys
function profile_multiget(user_id, ...)
	-- First of all, make hash of needed keys
	local pref_list = {...}
	local pref_hash = {}
	for k, v in ipairs(pref_list) do
		pref_hash[v] = true
	end

	local profile = load_profile(user_id)
	-- Create a copy of profile. We select few keys, so it is faster to copy only needed keys, then clear not needed keys
	local profile_copy = create_new_profile(profile.uid)
	for k, v in pairs(profile.data) do
		if pref_hash[k] then
			profile_copy.data[k] = v
		end
	end

	return cast_profile_to_return_format(profile_copy)
end

-- function profile_multiset accepts user_id and then key, value, key, value, key, value, ... Returns full updated profile.
function profile_multiset(user_id, ...)
	local pref_list = {...}

	if #pref_list % 2 ~= 0 then
		error('Not even number of arguments')
	end
	
	local profile = load_profile(user_id)
	
	-- In case of no keys were passed, just return full profile
	if #pref_list == 0 then
		return cast_profile_to_return_format(profile)
	end

	local i, pref_key = next(pref_list)
    	local i, pref_value = next(pref_list, i)
	-- iterate all passed key/value pairs from arguments
    	while pref_key ~= nil and pref_value ~= nil do
		set_profile_key(profile, pref_key, pref_value)
		i, pref_key = next(pref_list, i)
		i, pref_value = next(pref_list, i)
    	end

	store_profile(profile)
	return cast_profile_to_return_format(profile)
end

-- function profile_set set only one key. Returns full updated profile
function profile_set(user_id, key, value)
	return profile_multiset(user_id, key, value)
end
