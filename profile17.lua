box.cfg{listen = 3301}
box.once('init', function()
	profile_space = box.schema.space.create('profile', {id = 1})
	profile_space:create_index('primary', {
		type = 'hash',
		parts = {1, 'unsigned'}
		})
	box.schema.user.grant('guest', 'read,write,execute', 'universe')
	end)

log = require('log')

local function store_profile(profile)
	return box.space.profile:replace({profile.uid, profile.data})
end

local function load_profile(user_id)
	local tup = box.space.profile:select(user_id)
	if #tup == 0 then
		return nil
	end
	local profile = {}
	profile.uid = user_id
	profile.data = tup[1][2]
	return profile
end

local function create_new_profile(user_id)
	local profile = {}
	profile.uid = user_id
	profile.data = {}
	return profile
end

local function set_profile_key(profile, key, value)
	if value == '' then
		value = nil
	end
	profile.data[key] = value
end

local function cast_profile_to_return_format(profile)
	return {profile.uid, profile.data}
end

function profile_delete(user_id)
	box.space.profile:delete(user_id)
end

function profile_get_all(user_id)
	local profile = load_profile(user_id)
	return cast_profile_to_return_format(profile)
end

function profile_multiset(user_id, ...)
	local pref_list = {...}
	if #pref_list == 0 then
		error('No keys passed')
	end

	if #pref_list % 2 ~= 0 then
		error('Not even number of arguments')
	end

	local profile = load_profile(user_id)
	if not profile then
		profile = create_new_profile(user_id) 
	end

	local i, pref_key = next(pref_list)
    	local i, pref_value = next(pref_list, i)
    	while pref_key ~= nil and pref_value ~= nil do
		set_profile_key(profile, pref_key, pref_value)
		i, pref_key = next(pref_list, i)
		i, pref_value = next(pref_list, i)
    	end

	store_profile(profile)
	return cast_profile_to_return_format(profile)
end

function profile_set(user_id, key, value)
	return profile_multiset(user_id, key, value)
end
