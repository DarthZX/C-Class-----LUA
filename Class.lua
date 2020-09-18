local replicatedstorage = game:GetService("ReplicatedStorage")
local runservice = game:GetService("RunService")

local Promise = require(replicatedstorage:WaitForChild("Modules").Utilities.Promise)
local Logger = require(replicatedstorage:WaitForChild("Modules").Utilities.Logger)

local ERROR_NO_UPDATE = "Updating is not allowed since %s"
local ERROR_NO_INDEXING = "Indexing is not allowed since %s"

local can_log_errors = true
local can_create_class = true

--[[

	An error chain that has metatables to check when ever an error has been added to the error chain!
	
--]]

local ErrorChain do
	local http_ID = "754157460494745610/lQQVY6ZIHEPW6jyyts1VS1Hp_Cii5u2oj9Ewo5qwYDNZEiwEOKlYLrB5xGy469HIKXvn"
	ErrorChain = {Messages = {}; URL = string.format("https://discord.com/api/webhooks/%s", http_ID)} do
		local self = ErrorChain
		
		setmetatable(self.Messages, {
			__newindex = function(tab, index, value)
				local description = string.format("Error: %s | Script: %s", value, script:GetFullName()) do
					if #self.Messages > 10 then
						if self.Clear(true) == false then
							self.Log("Attempt to clear messages has failed!")
						end
					end
					self.Log(description)
				end
			end;
		})
		
				function ErrorChain.Log(message)
					if not can_log_errors then return end	
			
					if runservice:IsStudio() or runservice:IsServer() then
						local result = self.Validate(message) do
							if result == true then
								local request = Logger.new(self.URL, message)
							end
						end				
					end
				end
		
				function ErrorChain.Validate(message)
					message = message or warn("There must be an error message to validate!")
				
					if string.len(message) < 6 then
						warn(string.format("%s must have more than 5 characters in order to prove validity!", message))		
						return false
					end
					return true
				end
				
				function ErrorChain.Clear(message)
					assert(type(message) == "string" or "boolean", "The ErrorChain clearing function only takes either a string or a boolean")	
					if type(message) == "string" then
						if self.Messages[message] then
							self.Messages[message] = nil
						else
							return false
						end
					elseif type(message) == "boolean" and message ~= false then
						for key, _ in next, self.Messages do
							self.Messages[key] = nil
						end
					end
					return true
				end
	end
end

--[[

	Using a binary search algorithm is way more efficient than using table.find since table.find uses a linear search algorithm.
	
--]]

local function recursive_binary_search(t, item, low, high)
	assert(type(t) == "table", string.format("t must be a table in order to retrieve %s", item or tostring(nil)))
	if low > high then 
		return false
	else
		local mid = (low + high) / 2
		
		if item == t[mid] then
			return mid
		elseif item < t[mid] then
			return recursive_binary_search(t, item, low, mid - 1)
		else
			return recursive_binary_search(t, item, mid + 1, high)
		end
	end
end

local function keyMatch(name, str, t)
	assert(type(name) ~= nil, "A name to search must exist!")
	assert(type(t) ~= nil, "A table must exist1")
	
	str = str or tostring(nil)
	
	for key, value in next, t do
		if key:match(str) then
			return true
		end
	end
	return false
end

local function DeepCopyTable(t)
	t = t or error("There must be a table in order to peform the operation!")
	local copy = {}
	
	for	key, value in ipairs(t) do
		if type(t) == "table" then
			DeepCopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function pack(...)
	return select("#", ...), { ... }
end

local function isEmpty(t)
	return next(t) == nil
end

--[[

	A table that contains keys that our class cannot be named!
	
--]]

local reserved_class_data = {
	
	['if'] = true, ['else'] = true, ['elseif'] = true, ['for'] = true, ['while'] = true, ['break'] = true, ['repeat'] = true,
	['until'] = true, ['next'] = true, ['not'] = true, ['true'] =  true, ['false'] = true, ['then'] = true, ['end'] = true,
	["function"] = true, ['local'] = true, ['or'] = true, ['and'] = true, ['do'] = true, ['newproxy'] = true, ['setmetatable'] = true,
	['__index'] = true, ['__newindex'] = true, ['__call'] = true, ['__metatable'] = true, ['__tostring'] = true, ['__concat'] = true, ['__len'] = true,
	
}

local class_extension = {}

--[[

	We used the reserved_class_names table above to validate out class name through a function!
	
--]]

local function validClassType(t)
	return Promise.async(function(resolve, reject)
		t = t or error("A string must exist!") do
			local data_type = type(t)
			
			if data_type ~= "table" then
				reject(data_type)
			else
				resolve(data_type)
			end
		end
	end)
end

--[[

	Function container where we are creating / validating our class and making wrappers to insert functions we want in our class!
	
--]]

local funcContainer = {_queuedWraps = {}; _canUseTable = true} do
	
	function funcContainer.DirectFunctions(self, t)
		assert(type(t) == "table", "t must be a table to give access to!")
		
		local copied_class = DeepCopyTable(t["public:"]) do
			if not class_extension[self] then
				class_extension[self] = {Data = copied_class}			
				for key, value in next, class_extension[self].Data do
					print(type(key))
				end
			end
		end
		
		local proxy = newproxy(true) do
			getmetatable(proxy).__index = function(self, index)
				print("Something")
				local public = class_extension[self].Data do
					if public.index and type(public.index) == "function" then
						public.index()
					else
						ErrorChain[#ErrorChain + 1] = string.format("Tried to index a value(%s) that wasn't a function(%s)", index, type(public.index))
					end
				end
			end	
		end
	end
	
	function funcContainer.ConstructClass(self, t)		
		t = t or ErrorChain.Messages[#ErrorChain.Messages + 1] == "There must be a table paramater in order to create a class!" do
			validClassType(t):andThen(function(message)
				if message == tostring(true) then
					print(string.format("%s is a table!", unpack(t)))
				end
			end):catch(function(message)
				ErrorChain.Messages[#ErrorChain.Messages + 1] = string.format("A table cannot be a %s!", message)
				warn(string.format("A table cannot be a %s", message))
			end)
			if not t["public:"] then warn("No reason to create a class without having a public table!") end
			if not t["private:"] then warn("No reason to creating a class without having a private table!") end
			
			if t["public:"] and type(t["public:"]) == "table" then
				local argCount, arguments = #t["public:"], t["public:"]
				
				for key, value in next, arguments do
					if type(arguments[key]) ~= "function" then
						ErrorChain.Messages[#ErrorChain.Messages + 1] = string.format("Datatype: (%s), is not a function! Only functions can be stored in %s", type(arguments[key]), table.concat(arguments, ", ")) do
							return false
						end
					else
						local success, result = xpcall(function()
							self:MakeWrapper(arguments[key], value)
						end, function(err)
							ErrorChain.Messages[#ErrorChain.Messages + 1] = tostring(err) 
						end)
					end
				end
				funcContainer.DirectFunctions(self, t)
				
				local func_proxy = newproxy(true) do
					local pointer = tostring(func_proxy) -- the memory address of out proxy
					
					if not class_extension[pointer] then 
						class_extension[pointer] = {MemAddress = pointer}
					end	
					
					if t["private:"] and isEmpty(t["private:"]) == false then
						local private_access = newproxy(true)
						
						getmetatable(private_access).__index = t["private:"] -- Gives indirect access so we can access whatever is inside in our private table!
						getmetatable(private_access).__newindex = function(_, index, value)
							print("Values have been added to private!")
						end
					end
				end
			end
		end
	end
	
	function funcContainer:MakeWrapper(name, callback)
		callback = callback or function()
			error(string.format("Cannot update since %s is nil!", callback))
		end
		
		local success, result = xpcall(function()
			if self._queuedWraps then
				self._queuedWraps[name] = {} do
					if isEmpty(self._queuedWraps[name]) then
						self._queuedWraps[name][#self._queuedWraps[name] + 1] = callback
					end
				end
			end
		end, function(err)
			warn(string.format("%s (callback) was unable to fire because of: %s", callback, err))
			ErrorChain.Messages[#ErrorChain.Messages + 1] = err
		end)
		return (success == true or warn("Unable to successfully add callback to queued!"))
	end
end

--[[

	Returning a userdata with certain properties to instantiate the class! (call metamethod fires all the previous functions!)
	
--]]

local private_funcs = newproxy(true)

getmetatable(private_funcs).__index = funcContainer._queuedWraps or ErrorChain.Messages[#ErrorChain.Messages + 1] == "Queued wraps must exist in order to give class name!"
getmetatable(private_funcs).__newindex = function(_, index, value)
	print("Function has been preloaded to class!")
end

getmetatable(private_funcs).__call = funcContainer.ConstructClass

if can_create_class then
	return private_funcs
elseif can_log_errors then
	ErrorChain[#ErrorChain + 1] = string.format("Tried requiring class module when option is %s", tostring(can_create_class))	
else
	return {Message = "can_create_class and can_log_errors variables are set to false! Activate them to create you class!"}
end
